//
//  NJF_DB.m
//  NJF_FMDB
//
//  Created by jinfeng niu on 2018/10/10.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import "NJF_DB.h"
#import "FMDB.h"
#import "NJF_DBTool.h"

/**
 默认数据库名称
 */
#define SQLITE_NAME @"NJF_FMDB.db"
#define CachePath(name) [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:name]

@interface NJF_DB()
/**
 数据库队列,多线程操作
 */
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) FMDatabase *db;
@property (nonatomic, assign) BOOL inTransation;//事物操作

/**
 记录注册监听数据变化的block.
 */
@property (nonatomic,strong) NSMutableDictionary* changeBlocks;

@end

static NJF_DB *njfDB = nil;
@implementation NJF_DB

- (instancetype)init{
    if (self = [super init]) {
        self.semaphore = dispatch_semaphore_create(1);
    }
    return self;
}
/**
 获取单例函数.
 */
+ (nonnull instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        njfDB = [[NJF_DB alloc] init];
    });
    return njfDB;
}

-(NSMutableDictionary *)changeBlocks{
    if (_changeBlocks == nil) {
        @synchronized(self){
            if(_changeBlocks == nil){
                _changeBlocks = [NSMutableDictionary dictionary];
            }
        }
    }
    return _changeBlocks;
}

/**
 创建数据库队列
 */
- (FMDatabaseQueue *)dbQueue{
    if (_dbQueue) return _dbQueue;
    NSString *name;
    if (_sqliteName) {
        name = [NSString stringWithFormat:@"%@.db",_sqliteName];
    }else{
        name = SQLITE_NAME;
    }
    NSString *filename = CachePath(name);
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:filename];
    return _dbQueue;
}

/**
 关闭数据库
 */
- (void)closeDB{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (_dbQueue) {
        [_dbQueue close];
        _dbQueue = nil;
    }
    dispatch_semaphore_signal(self.semaphore);
}

/**
 数据库中是否存在表.
 */
- (void)isExistWithTableName:(NSString *_Nonnull)name complete:(njf_complete_B)complete{
    NSAssert(name, @"表名不能为空");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        result = [db tableExists:name];
    }];
    if (complete) complete(result);
}

/**
 为了对象层的事物操作而封装的函数.
 */
- (void)executeDB:(void(^_Nonnull)(FMDatabase *_Nonnull db))block{
    NSAssert(block, @"block is nil");
    if (_db) {
        block(_db);
        return;
    }
    __weak typeof (self) weakSelf = self;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.db = db;
        block(db);
        strongSelf.db = nil;
    }];
}

/**
 创建表
 */
- (void)creatTableWithTableName:(NSString *)name keys:(NSArray <NSString *> *_Nonnull)keys complete:(njf_complete_B)complete{
    NSAssert(name, @"表名不能为空");
    NSAssert(keys, @"字段数组不能为空");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString *header = [NSString stringWithFormat:@"create table if not exists %@(",name];
        NSMutableString *sql = [NSMutableString string];
        [sql appendString:header];
        for (int i = 0; i < keys.count; i ++) {
            NSString *key = [keys[i] componentsSeparatedByString:@"*"][0];
            if ([key isEqualToString:njf_primaryKey]) {
                [sql appendFormat:@"%@ primary key autoincrement",[NJF_DBTool keyType:keys[i]]];
            }else{
                [sql appendString:[NJF_DBTool keyType:keys[i]]];
            }
            if (i == (keys.count - 1)) {
                [sql appendString:@");"];
            }else{
                [sql appendString:@","];
            }
        }
        //创建表
        result = [db executeUpdate:sql];
    }];
    if (complete) complete(result);
}

/**
查询表中有多少数据
 */
- (NSUInteger)countQueueForTable:(NSString *_Nonnull)name{
    NSAssert(name, @"表名不能为空");
    __block NSInteger count = 0;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"select count(*) from %@",name];
        [db executeStatements:sql withResultBlock:^int(NSDictionary * _Nonnull resultsDictionary) {
            count = [[resultsDictionary.allValues lastObject] integerValue];
            return 0;
        }];
    }];
    return count;
}

/**
执行事务操作
 */
- (void)executeTransation:(BOOL(^_Nonnull)(void))block{
    __weak typeof(self) weakSelf = self;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.inTransation = db.isInTransaction;
        if (!strongSelf.inTransation) {
            strongSelf.inTransation = [db beginTransaction];
        }
        BOOL isCommit = NO;
        isCommit = block();
        if (strongSelf.inTransation) {
            if (isCommit) {
                [db commit];
            }else{
                [db rollback];
            }
            strongSelf.inTransation = NO;
        }
    }];
}

//查询表中有多少数据
-(NSInteger)getKeyMaxForTable:(NSString*)name key:(NSString*)key db:(FMDatabase*)db{
    __block NSInteger num = 0;
    [db executeStatements:[NSString stringWithFormat:@"select max(%@) from %@",key,name] withResultBlock:^int(NSDictionary *resultsDictionary){
        id dbResult = [resultsDictionary.allValues lastObject];
        if(dbResult && ![dbResult isKindOfClass:[NSNull class]]) {
            num = [dbResult integerValue];
        }
        return 0;
    }];
    return num;
}

-(void)doChangeWithName:(NSString* const _Nonnull)name flag:(BOOL)flag state:(njf_changeState)state{
    if(flag && self.changeBlocks.count>0){
        //开一个子线程去执行block,防止死锁.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
            [self.changeBlocks enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop){
                NSString* tablename = [key componentsSeparatedByString:@"*"].firstObject;
                if([name isEqualToString:tablename]){
                    void(^block)(njf_changeState) = obj;
                    //返回主线程回调.
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        block(state);
                    });
                }
            }];
        });
    }
}

/**
 插入数据
 */
- (void)insertIntoWithTableName:(NSString *_Nonnull)name dict:(NSDictionary *_Nonnull)dict complete:(njf_complete_B)complete{
    NSAssert(name, @"表名不能为空");
    NSAssert(dict, @"插入的字典不能为空");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSArray *keys = dict.allKeys;
        //主健自增
        if ([keys containsObject:njf_sqlKey(njf_primaryKey)]) {
            NSInteger num = [self getKeyMaxForTable:name key:njf_sqlKey(njf_primaryKey) db:db];
            [dict setValue:@(num+1) forKey:njf_sqlKey(njf_primaryKey)];
        }
        NSArray* values = dict.allValues;
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"insert into %@(",name];
        for(int i=0;i<keys.count;i++){
            [SQL appendFormat:@"%@",keys[i]];
            if(i == (keys.count-1)){
                [SQL appendString:@") "];
            }else{
                [SQL appendString:@","];
            }
        }
        [SQL appendString:@"values("];
        for(int i=0;i<values.count;i++){
            [SQL appendString:@"?"];
            if(i == (keys.count-1)){
                [SQL appendString:@");"];
            }else{
                [SQL appendString:@","];
            }
        }
        result = [db executeUpdate:SQL withArgumentsInArray:values];
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:njf_insert];
    if (complete) complete(result);
}

/**
 根据唯一标识保存数组
 */
- (void)saveArray:(NSArray *_Nonnull)array
             name:(NSString *_Nonnull)name
         complete:(njf_complete_B)complete{
    NSAssert(array && array.count,@"数组不能为空");
    NSAssert(name,@"唯一标识名不能为空");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        __weak typeof(self) weakSelf = self;
        [self isExistWithTableName:name complete:^(BOOL isSuccess) {
            if (!isSuccess) {//创建表
                [weakSelf creatTableWithTableName:name keys:@[[NSString stringWithFormat:@"%@*i",njf_primaryKey],@"param*@\"NSString\"",@"index*i"] complete:nil];
            }
        }];
        //获取表中有多少数据
        __block NSInteger sqlCount = [self countQueueForTable:name];
        __block NSInteger num = 0;
        [self executeTransation:^BOOL{
            for (id value in array) {
                NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
                id sqlValue = [NJF_DBTool getSqlValue:value type:type encode:YES];
                NSDictionary* dict = @{@"njf_param":sqlValue,@"njf_index":@(sqlCount++)};
                //插入数据
                [self insertIntoWithTableName:name dict:dict complete:^(BOOL isSuccess) {
                    if (isSuccess) {
                        num ++;
                    }
                }];
            }
            return YES;
        }];
        if (complete) complete(array.count == num);
    }
    dispatch_semaphore_signal(self.semaphore);
}
@end
