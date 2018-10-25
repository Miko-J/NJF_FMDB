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
#import "NSObject+NJF_ObjModel.h"
#import "NJF_DBConfig.h"
#import "NSCache+NJF_Cache.h"
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
    NSLog(@"数据库路径 = %@",filename);
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:filename];
    return _dbQueue;
}

/**
 关闭数据库
 */
- (void)njf_closeDB{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (_dbQueue) {
        [_dbQueue close];
        _dbQueue = nil;
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)njf_deleteSqlite:(NSString *_Nonnull)sqliteName
                complete:(njf_complete_B)complete{
    NSString* filePath = CachePath(([NSString stringWithFormat:@"%@.db",sqliteName]));
    NSFileManager * file_manager = [NSFileManager defaultManager];
    NSError* error;
    if ([file_manager fileExistsAtPath:filePath]) {
        [file_manager removeItemAtPath:filePath error:&error];
    }
    if (complete) complete(error==nil);
}

/**
 数据库中是否存在表.
 */
- (void)isExistWithTableName:(NSString *_Nonnull)name
                    complete:(njf_complete_B)complete{
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
- (void)creatTableWithTableName:(NSString *)name
                           keys:(NSArray <NSString *> *_Nonnull)keys
               unionPrimaryKeys:(NSArray *_Nullable)unionPrimaryKeys
                     uniqueKeys:(NSArray *_Nullable)uniqueKeys
                       complete:(njf_complete_B)complete{
    NSAssert(name, @"表名不能为空");
    NSAssert(keys, @"字段数组不能为空");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString *header = [NSString stringWithFormat:@"create table if not exists %@(",name];
        NSMutableString *sql = [[NSMutableString alloc] init];
        [sql appendString:header];
        NSInteger uniqueKeyFlag = uniqueKeys.count;
        NSMutableArray* tempUniqueKeys = [NSMutableArray arrayWithArray:uniqueKeys];
        for (int i = 0; i < keys.count; i ++) {
            NSString *key = [keys[i] componentsSeparatedByString:@"*"][0];
            if(tempUniqueKeys.count && [tempUniqueKeys containsObject:key]){
                for(NSString* uniqueKey in tempUniqueKeys){
                    if([NJF_DBTool isUniqueKey:uniqueKey with:keys[i]]){
                        [sql appendFormat:@"%@ unique",[NJF_DBTool keyType:keys[i]]];
                        [tempUniqueKeys removeObject:uniqueKey];
                        uniqueKeyFlag--;
                        break;
                    }
                }
            }else{
                if ([key isEqualToString:njf_primaryKey]) {
                    [sql appendFormat:@"%@ primary key autoincrement",[NJF_DBTool keyType:keys[i]]];
                }else{
                    [sql appendString:[NJF_DBTool keyType:keys[i]]];
                }
            }
            if (i == (keys.count - 1)) {
                if(unionPrimaryKeys.count){
                    [sql appendString:@",primary key ("];
                    [unionPrimaryKeys enumerateObjectsUsingBlock:^(id  _Nonnull unionKey, NSUInteger idx, BOOL * _Nonnull stop) {
                        if(idx == 0){
                            [sql appendString:njf_sqlKey(unionKey)];
                        }else{
                            [sql appendFormat:@",%@",njf_sqlKey(unionKey)];
                        }
                    }];
                    [sql appendString:@")"];
                }
                [sql appendString:@")"];
            }else{
                [sql appendString:@","];
            }
        }
        if(uniqueKeys.count){
            NSAssert(!uniqueKeyFlag,@"没有找到设置的'唯一约束',请检查模型类.m文件的bg_uniqueKeys函数返回值是否正确!");
        }
        NSLog(@"创建的表语句为%@",sql);
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
-(NSInteger)getKeyMaxForTable:(NSString*)name
                          key:(NSString*)key
                           db:(FMDatabase*)db{
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
- (void)insertIntoWithTableName:(NSString *_Nonnull)name
                           dict:(NSDictionary *_Nonnull)dict
                       complete:(njf_complete_B)complete{
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
- (void)njf_saveArray:(NSArray *_Nonnull)array
             name:(NSString *_Nonnull)name
         complete:(njf_complete_B)complete{
    NSAssert(array && array.count,@"数组不能为空");
    NSAssert(name,@"唯一标识名不能为空");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        __weak typeof(self) weakSelf = self;
        [self isExistWithTableName:name complete:^(BOOL isSuccess) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!isSuccess) {//创建表
                [strongSelf creatTableWithTableName:name keys:@[[NSString stringWithFormat:@"%@*i",njf_primaryKey],@"param*@\"NSString\"",@"index*i"] unionPrimaryKeys:nil uniqueKeys:nil complete:nil];
            }
        }];
        //获取表中有多少数据
        __block NSInteger sqlCount = [self countQueueForTable:name];
        __block NSInteger num = 0;
        [self executeTransation:^BOOL{
            for (id value in array) {
                NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
                id sqlValue = [NJF_DBTool getSqlValue:value type:type encode:YES];
                sqlValue = [NSString stringWithFormat:@"%@$$$%@",sqlValue,type];
                NSDictionary* dict = @{@"NJF_param":sqlValue,@"NJF_index":@(sqlCount++)};
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

/**
 读取数组某个元素.
 */
- (void)njf_querryArrayWithName:(NSString *_Nonnull)name
                   complete:(njf_complete_A)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        NSString* condition = [NSString stringWithFormat:@"order by %@ asc",njf_sqlKey(njf_primaryKey)];
        [self queryQueueWithTableName:name conditions:condition complete:^(NSArray * _Nullable array) {
            NSMutableArray* resultM = nil;
            if(array&&array.count){
                resultM = [NSMutableArray array];
                for(NSDictionary* dict in array){
                    NSArray* keyAndTypes = [dict[@"NJF_param"] componentsSeparatedByString:@"$$$"];
                    id value = [keyAndTypes firstObject];
                    NSString* type = [keyAndTypes lastObject];
                    value = [NJF_DBTool getSqlValue:value type:type encode:NO];
                    if (value) {
                        [resultM addObject:value];
                    }
                }
            }
            if (complete) complete(resultM);
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
}

-(void)queryQueueWithTableName:(NSString* _Nonnull)name
                    conditions:(NSString* _Nullable)conditions
                      complete:(njf_complete_A)complete{
    NSAssert(name,@"表名不能为空!");
    __block NSMutableArray* arrM = nil;
    [self executeDB:^(FMDatabase * _Nonnull db){
        NSString* SQL = conditions?[NSString stringWithFormat:@"select * from %@ %@",name,conditions]:[NSString stringWithFormat:@"select * from %@",name];
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL];
        if (rs == nil) {
           NSLog(@"查询错误,可能是'类变量名'发生了改变或'字段','表格'不存在!,请存储后再读取!");
        }else{
            arrM = [[NSMutableArray alloc] init];
        }
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
        //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
        [rs close];
    }];
    if (complete) complete(arrM);
}

/**
 更新数组某个元素.
 */
- (void)njf_updateobjWithName:(NSString *_Nonnull)name
                      obj:(id _Nonnull)obj
                    index:(NSInteger)index
                 complete:(njf_complete_B)complete{
    NSAssert(name, @"表名不能为空");
    NSAssert(obj, @"更新的元素不能为空");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block BOOL result;
    @autoreleasepool {
        NSString *type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([obj class])];
        id sqlValue = [NJF_DBTool getSqlValue:obj type:type encode:YES ];
        sqlValue = [NSString stringWithFormat:@"%@$$$%@",sqlValue,type];
        NSDictionary *dict = @{@"NJF_param":sqlValue};
        [self updateWithTableName:name valueDict:dict where:@[@"index",@"=",@(index)] complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        if (complete) complete(result);
    }
    dispatch_semaphore_signal(self.semaphore);
}

/**
 更新数据
 */
- (void)updateWithTableName:(NSString *_Nonnull)name
                  valueDict:(NSDictionary *_Nonnull)valueDict
                      where:(NSArray *_Nullable)where
                   complete:(njf_complete_B)complete{
    __block BOOL result;
    NSMutableArray* arguments = [NSMutableArray array];
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"update %@ set ",name];
        for(int i=0;i<valueDict.allKeys.count;i++){
            [SQL appendFormat:@"%@=?",valueDict.allKeys[i]];
            [arguments addObject:valueDict[valueDict.allKeys[i]]];
            if (i != (valueDict.allKeys.count-1)) {
                [SQL appendString:@","];
            }
        }
        if(where && (where.count>0)){
            NSArray* results = [NJF_DBTool where:where];
            [SQL appendString:results[0]];
            [arguments addObjectsFromArray:results[1]];
        }
        result = [db executeUpdate:SQL withArgumentsInArray:arguments];
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:njf_update];
    if (complete) complete (result);
}

/**
 删除数组某个位置上的元素,改变索引
 */
- (void)njf_deleteObjWithName:(NSString *_Nonnull)name
                    index:(NSInteger)index
                 complete:(njf_complete_B)complete{
    NSAssert(name, @"表名不能为空");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block NSInteger flag = 0;
    @autoreleasepool {
        [self executeTransation:^BOOL{
            [self deleteQueueWithTableName:name conditions:[NSString stringWithFormat:@"where NJF_index=%ld",(long)index] complete:^(BOOL isSuccess) {
                if (isSuccess) {
                    flag ++;
                }
            }];
            if (flag) {//数组元素删除成功，改变存储的索引
                [self updateQueueWithTableName:name valueDict:nil conditions:[NSString stringWithFormat:@"set NJF_index=NJF_index-1 where NJF_index>%@",@(index)] complete:^(BOOL isSuccess) {
                    flag ++;
                }];
            }
            return flag == 2;
        }];
        if (complete) complete(flag == 2);
    }
    dispatch_semaphore_signal(self.semaphore);
}

/**
 删除数组某个位置上的元素
 */
- (void)deleteQueueWithTableName:(NSString *_Nonnull)name
                      conditions:(NSString *_Nonnull)conditions
                        complete:(njf_complete_B)complete{
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = conditions?[NSString stringWithFormat:@"delete from %@ %@",name,conditions]:[NSString stringWithFormat:@"delete from %@",name];
        result = [db executeUpdate:SQL];
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:njf_delete];
    if (complete) complete(result);
}

/**
更新数组的索引
 */
- (void)updateQueueWithTableName:(NSString *_Nonnull)name
                       valueDict:(NSDictionary *_Nullable)valueDict
                      conditions:(NSString *_Nonnull)conditions
                        complete:(njf_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db){
        NSString* SQL;
        if (!valueDict || !valueDict.count) {
            SQL = [NSString stringWithFormat:@"update %@ %@",name,conditions];
        }else{
            NSMutableString* param = [NSMutableString stringWithFormat:@"update %@ set ",name];
            for(int i=0;i<valueDict.allKeys.count;i++){
                NSString* key = valueDict.allKeys[i];
                [param appendFormat:@"%@=?",key];
                if(i != (valueDict.allKeys.count-1)) {
                    [param appendString:@","];
                }
            }
            [param appendFormat:@" %@",conditions];
            SQL = param;
        }
        result = [db executeUpdate:SQL withArgumentsInArray:valueDict.allValues];
    }];
    
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:njf_update];
    if (complete) complete(result);
}

- (void)njf_querryWithName:(NSString *_Nonnull)name
                 index:(NSInteger)index
                 value:(void(^)(id value))value{
    NSAssert(name, @"表名不能为空");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block id resultValue = nil;
    @autoreleasepool {
        [self queryQueueWithTableName:name conditions:[NSString stringWithFormat:@"where NJF_index=%@",@(index)] complete:^(NSArray * _Nullable array) {
            if(array&&array.count){
                NSDictionary* dict = [array firstObject];
                NSArray* keyAndTypes = [dict[@"NJF_param"] componentsSeparatedByString:@"$$$"];
                id value = [keyAndTypes firstObject];
                NSString* type = [keyAndTypes lastObject];
                resultValue = [NJF_DBTool getSqlValue:value type:type encode:NO];
            }
        }];
        
    }
    if (value) value(resultValue);
    dispatch_semaphore_signal(self.semaphore);
}

/**
 删除表(线程安全).
 */
- (void)njf_dropSafeTable:(NSString *_Nonnull)name
             complete:(njf_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self dropTable:name complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

/**
 删除表.
 */
-(void)dropTable:(NSString* _Nonnull)name complete:(njf_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"drop table %@",name];
        result = [db executeUpdate:SQL];
    }];
    //数据监听执行函数
    [self doChangeWithName:name flag:result state:njf_drop];
    if (complete) complete(result);
}

/*********************字典*******************/
- (void)njf_saveDict:(NSDictionary *_Nonnull)dict
            name:(NSString *_Nonnull)name
        complete:(njf_complete_B)complete{
    NSAssert(dict || dict.allKeys.count, @"字典不能为空");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        __weak typeof(self) weakSelf = self;
        [self isExistWithTableName:name complete:^(BOOL isSuccess) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!isSuccess) {
                [strongSelf creatTableWithTableName:name keys:@[[NSString stringWithFormat:@"%@*i",njf_primaryKey],@"key*@\"NSString\"",@"value*@\"NSString\""] unionPrimaryKeys:nil uniqueKeys:@[@"key"] complete:nil];
            }
        }];
        __block NSInteger num = 0;
        [self executeTransation:^BOOL{
            [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
                NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
                id sqlValue = [NJF_DBTool getSqlValue:value type:type encode:YES];
                sqlValue = [NSString stringWithFormat:@"%@$$$%@",sqlValue,type];
                NSDictionary* dict = @{@"NJF_key":key,@"NJF_value":sqlValue};
                [self insertIntoWithTableName:name dict:dict complete:^(BOOL isSuccess) {
                    if (isSuccess) {
                        num ++;
                    }
                }];
            }];
            return YES;
        }];
        if (complete) complete(num == dict.allKeys.count);
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)njf_enumerateKeysAndObjectsName:(NSString *_Nonnull)name block:(void(^ _Nonnull)(NSString *_Nonnull key, NSString *_Nonnull value, BOOL *stop))block complete:(njf_complete_B)complete{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        NSString* condition = [NSString stringWithFormat:@"order by %@ asc",njf_sqlKey(njf_primaryKey)];
        [self queryQueueWithTableName:name conditions:condition complete:^(NSArray * _Nullable array) {
            BOOL stopFlag = NO;
            for(NSDictionary* dict in array){
                NSArray* keyAndTypes = [dict[@"NJF_value"] componentsSeparatedByString:@"$$$"];
                NSString* key = dict[@"NJF_key"];
                id value = [keyAndTypes firstObject];
                NSString* type = [keyAndTypes lastObject];
                value = [NJF_DBTool getSqlValue:value type:type encode:NO];
                !block?:block(key,value,&stopFlag);
                if(stopFlag){
                    break;
                }
            }
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)njf_setValueWithName:(NSString *_Nonnull)name value:(id _Nonnull)value
                         key:(NSString *_Nonnull)key
                    complete:(njf_complete_B)complete{
    NSAssert(key, @"key不能为空");
    NSAssert(value, @"value不能为空");
    NSDictionary *dict = @{key:value};
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self njf_saveDict:dict name:name complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)njf_updateValueWithName:(NSString *_Nonnull)name value:(id _Nonnull)value
                            key:(NSString *_Nonnull)key
                       complete:(njf_complete_B)complete{
    NSAssert(key,@"key不能为空!");
    NSAssert(value,@"value不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block BOOL result;
    @autoreleasepool{
        NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
        id sqlvalue = [NJF_DBTool getSqlValue:value type:type encode:YES];
        sqlvalue = [NSString stringWithFormat:@"%@$$$%@",sqlvalue,type];
        NSDictionary* dict = @{@"NJF_value":sqlvalue};
        [self updateWithTableName:name valueDict:dict where:@[@"key",@"=",key] complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        if (complete) complete(result);
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)njf_valueForKeyWithName:(NSString *const _Nonnull)name
                       key:(NSString *_Nonnull)key
                valueBlock:(void (^ _Nonnull)(id _Nonnull value))block{
    NSAssert(key,@"key不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block id resultValue = nil;
    @autoreleasepool {
        [self queryQueueWithTableName:name conditions:[NSString stringWithFormat:@"where NJF_key='%@'",key] complete:^(NSArray * _Nullable array){
            if(array&&array.count){
                NSDictionary* dict = [array firstObject];
                NSArray* keyAndTypes = [dict[@"NJF_value"] componentsSeparatedByString:@"$$$"];
                id value = [keyAndTypes firstObject];
                NSString* type = [keyAndTypes lastObject];
                resultValue = [NJF_DBTool getSqlValue:value type:type encode:NO];
            }
        }];
        if (block) block(resultValue);
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)njf_deleteValueForKeyWithName:(NSString *const _Nonnull)name
                                  key:(NSString *_Nonnull)key
                             complete:(njf_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(key,@"key不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block BOOL result;
    @autoreleasepool {
        [self deleteQueueWithTableName:name conditions:[NSString stringWithFormat:@"where NJF_key='%@'",key] complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        if (complete) complete(result);
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)njf_clearDictWithName:(NSString *const _Nonnull)name
                     complete:(njf_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block BOOL result;
    @autoreleasepool {
        [self dropTable:name complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        if (complete) complete(result);
    }
    dispatch_semaphore_signal(self.semaphore);
}


- (void)njf_saveObjWithName:(NSString *const _Nonnull)name
                        obj:(id _Nonnull)obj
                   complete:(njf_complete_B)complete{
    NSAssert(name, @"表名不能为空");
    NSAssert(obj, @"存储的对象不能为空");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        //创建表
        [self ifNotExistCreateTableWithName:name obj:obj];
        [self insertWithName:name Obj:obj ignoreKeys:[NJF_DBTool executeSelector:njf_ignoreKeysSelector forClass:[obj class]] complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

//插入数据
- (void)insertWithName:(NSString *const _Nonnull)name
                   Obj:(id)obj
            ignoreKeys:(NSArray *_Nonnull)ignoreKeys
              complete:(njf_complete_B)complete{
    //获取要写入的字典数组数据
    NSDictionary *dict = [self getDictWithObject:obj ignoredKeys:ignoreKeys filtModelInfoType:njf_ModelInfoInsert];
    //自动判断是否有字段改变,自动刷新数据库.
    [self ifIvarChangeWithName:name object:obj ignoredKeys:ignoreKeys];
    [self insertIntoWithTableName:name dict:dict complete:complete];
}

/**
 判断类属性是否有改变,智能刷新.
 */
-(void)ifIvarChangeWithName:(NSString *_Nonnull)name
                     object:(id)object
                ignoredKeys:(NSArray*)ignoredkeys{
    //获取缓存的属性信息
    NSCache* cache = [NSCache njf_cache];
    NSString *tableName = [object valueForKey:njf_tableNameKey];
    tableName = tableName.length ? tableName : NSStringFromClass([object class]);
    NSString* cacheKey = [NSString stringWithFormat:@"%@_IvarChangeState",tableName];
    id IvarChangeState = [cache objectForKey:cacheKey];
    if(IvarChangeState){
        return;
    }else{
        [cache setObject:@(YES) forKey:cacheKey];
    }
    
    @autoreleasepool {
        NSMutableArray* newKeys = [NSMutableArray array];
        NSMutableArray* sqlKeys = [NSMutableArray array];
        [self executeDB:^(FMDatabase * _Nonnull db) {
            NSString* SQL = [NSString stringWithFormat:@"select sql from sqlite_master where tbl_name='%@' and type='table';",name];
            NSMutableArray* tempArrayM = [NSMutableArray array];
            //获取表格所有列名.
            [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
                NSString* allName = [resultsDictionary.allValues lastObject];
                allName = [allName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                NSRange range1 = [allName rangeOfString:@"("];
                allName = [allName substringFromIndex:range1.location+1];
                NSRange range2 = [allName rangeOfString:@")"];
                allName = [allName substringToIndex:range2.location];
                NSArray* sqlNames = [allName componentsSeparatedByString:@","];
                
                for(NSString* sqlName in sqlNames){
                    NSString* columnName = [[sqlName componentsSeparatedByString:@" "] firstObject];
                    [tempArrayM addObject:columnName];
                }
                return 0;
            }];
            NSArray* columNames = tempArrayM.count?tempArrayM:nil;
            NSArray* keyAndtypes = [NJF_DBTool getClassIvarList:[object class] Object:object onlyKey:NO];
            for(NSString* keyAndtype in keyAndtypes){
                NSString* key = [[keyAndtype componentsSeparatedByString:@"*"] firstObject];
                if(ignoredkeys && [ignoredkeys containsObject:key])continue;
                key = [NSString stringWithFormat:@"%@%@",NJF,key];
                if (![columNames containsObject:key]) {
                    [newKeys addObject:keyAndtype];
                }
            }
            NSMutableArray* keys = [NSMutableArray arrayWithArray:[NJF_DBTool getClassIvarList:[object class] Object:nil onlyKey:YES]];
            if (ignoredkeys) {
                [keys removeObjectsInArray:ignoredkeys];
            }
            [columNames enumerateObjectsUsingBlock:^(NSString* _Nonnull columName, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString* propertyName = [columName stringByReplacingOccurrencesOfString:NJF withString:@""];
                if(![keys containsObject:propertyName]){
                    [sqlKeys addObject:columName];
                }
            }];
            
        }];
        if((sqlKeys.count==0) && (newKeys.count>0)){
            //此处只是增加了新的列.
            for(NSString* key in newKeys){
                //添加新字段
                [self addTable:tableName key:key complete:^(BOOL isSuccess){}];
            }
        }else if(sqlKeys.count>0){
            //字段发生改变,减少或名称变化,实行刷新数据库.
            NSMutableArray* newTableKeys = [[NSMutableArray alloc] initWithArray:[NJF_DBTool getClassIvarList:[object class] Object:nil onlyKey:NO]];
            NSMutableArray* tempIgnoreKeys = [[NSMutableArray alloc] initWithArray:ignoredkeys];
            for(int i=0;i<newTableKeys.count;i++){
                NSString* key = [[newTableKeys[i] componentsSeparatedByString:@"*"] firstObject];
                if([tempIgnoreKeys containsObject:key]) {
                    [newTableKeys removeObject:newTableKeys[i]];
                    [tempIgnoreKeys removeObject:key];
                    i--;
                }
                if(tempIgnoreKeys.count == 0){
                    break;
                }
            }
            [self refreshQueueTable:tableName class:[object class] keys:newTableKeys complete:nil];
        }else;
    }
}

-(void)refreshQueueTable:(NSString* _Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* const _Nonnull)keys complete:(njf_complete_I)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(keys,@"字段数组不能为空!");
    [self isExistWithTableName:name complete:^(BOOL isSuccess){
        if (!isSuccess){
            NSLog(@"没有数据存在,数据库更新失败!");
            if (complete) complete(njf_error);
            return;
        }
    }];
    NSString* BGTempTable = @"BGTempTable";
    //事务操作.
    __block int recordFailCount = 0;
    [self executeTransation:^BOOL{
        [self copyA:name toB:BGTempTable class:cla keys:keys complete:^(njf_dealState result) {
            if(result == njf_complete){
                recordFailCount++;
            }
        }];
        [self dropTable:name complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        [self copyA:BGTempTable toB:name class:cla keys:keys complete:^(njf_dealState result) {
            if(result == njf_complete){
                recordFailCount++;
            }
        }];
        [self dropTable:BGTempTable complete:^(BOOL isSuccess) {
            if(isSuccess)recordFailCount++;
        }];
        if(recordFailCount != 4){
            NSLog(@"发生错误，更新数据库失败!");
        }
        return recordFailCount==4;
    }];
    //回调结果.
    if (recordFailCount==0) {
        if (complete) complete(njf_error);
    }else if (recordFailCount>0&&recordFailCount<4){
        if (complete) complete(njf_incomplete);
    }else{
        if (complete) complete(njf_complete);
    }
}

-(void)copyA:(NSString* _Nonnull)A toB:(NSString* _Nonnull)B class:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* const _Nonnull)keys complete:(njf_complete_I)complete{
    //获取"唯一约束"字段名
    NSArray* uniqueKeys = [NJF_DBTool executeSelector:njf_uniqueKeysSelector forClass:cla];
    //获取“联合主键”字段名
    NSArray* unionPrimaryKeys = [NJF_DBTool executeSelector:njf_unionPrimaryKeysSelector forClass:cla];
    //建立一张临时表
    __block BOOL createFlag;
    [self creatTableWithTableName:B keys:keys unionPrimaryKeys:unionPrimaryKeys uniqueKeys:uniqueKeys complete:^(BOOL isSuccess) {
        createFlag = isSuccess;
    }];
    if (!createFlag){
        NSLog(@"数据库更新失败!");
        if (complete) complete(njf_error);
        return;
    }
    __block njf_dealState refreshstate = njf_error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    __weak typeof(self) weakSelf = self;
    NSInteger count = [self countQueueForTable:A];
    for(NSInteger i=0;i<count;i += MaxQueryPageNum){
        @autoreleasepool{//由于查询出来的数据量可能巨大,所以加入自动释放池.
            NSString* param = [NSString stringWithFormat:@"limit %@,%@",@(i),@(MaxQueryPageNum)];
            [self queryQueueWithTableName:A conditions:param complete:^(NSArray * _Nullable array) {
                for(NSDictionary* oldDict in array){
                    NSMutableDictionary* newDict = [NSMutableDictionary dictionary];
                    for(NSString* keyAndType in keys){
                        NSString* key = [keyAndType componentsSeparatedByString:@"*"][0];
                        //字段名前加上 @"BG_"
                        key = [NSString stringWithFormat:@"%@%@",NJF,key];
                        if (oldDict[key]){
                            newDict[key] = oldDict[key];
                        }
                    }
                    //将旧表的数据插入到新表
                    [weakSelf insertIntoWithTableName:B dict:newDict complete:^(BOOL isSuccess) {
                        if (isSuccess){
                            if (!recordSuccess) {
                                recordSuccess = YES;
                            }
                        }else{
                            if (!recordError) {
                                recordError = YES;
                            }
                        }
                    }];
                }
            }];
        }
    }
    if (complete){
        if (recordError && recordSuccess) {
            refreshstate = njf_incomplete;
        }else if(recordError && !recordSuccess){
            refreshstate = njf_error;
        }else if (recordSuccess && !recordError){
            refreshstate = njf_complete;
        }else;
        complete(refreshstate);
    }
}

/**
 动态添加表字段.
 */
-(void)addTable:(NSString* _Nonnull)name key:(NSString* _Nonnull)key complete:(njf_complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self executeDB:^(FMDatabase * _Nonnull db) {
        NSString* SQL = [NSString stringWithFormat:@"alter table %@ add %@;",name,[NJF_DBTool keyType:key]];
        result = [db executeUpdate:SQL];
    }];
    if(complete) complete(result);
}

/**
 根据对象获取要更新或插入的字典.
 */
- (NSDictionary *_Nonnull)getDictWithObject:(id _Nonnull)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys filtModelInfoType:(njf_getModelInfoType)filtModelInfoType{
    //获取存到数据库的数据.
    NSMutableDictionary* valueDict = [self getDictWithObject:object ignoredKeys:ignoredKeys];
    if (filtModelInfoType == njf_ModelInfoSingleUpdate){//单条更新操作时,移除 创建时间和主键 字段不做更新
        [valueDict removeObjectForKey:njf_sqlKey(njf_createTimeKey)];
        //判断是否定义了“联合主键”.
        NSArray* unionPrimaryKeys = [NJF_DBTool executeSelector:njf_unionPrimaryKeysSelector forClass:[object class]];
        NSString* njf_id = njf_sqlKey(njf_primaryKey);
        if(unionPrimaryKeys.count == 0){
            if([valueDict.allKeys containsObject:njf_id]) {
                [valueDict removeObjectForKey:njf_id];
            }
        }else{
            if(![valueDict.allKeys containsObject:njf_id]) {
                valueDict[njf_id] = @(1);//没有就预备放入
            }
        }
    }else if(filtModelInfoType == njf_ModelInfoInsert){//插入时要移除主键,不然会出错.
        //判断是否定义了“联合主键”.
        NSArray* unionPrimaryKeys = [NJF_DBTool executeSelector:njf_unionPrimaryKeysSelector forClass:[object class]];
        NSString* njf_id = njf_sqlKey(njf_primaryKey);
        if(unionPrimaryKeys.count == 0){
            if([valueDict.allKeys containsObject:njf_id]) {
                [valueDict removeObjectForKey:njf_id];
            }
        }else{
            if(![valueDict.allKeys containsObject:njf_id]) {
                valueDict[njf_id] = @(1);//没有就预备放入
            }
        }
    }else if(filtModelInfoType == njf_ModelInfoArrayUpdate){//批量更新操作时,移除 创建时间 字段不做更新
        [valueDict removeObjectForKey:njf_sqlKey(njf_createTimeKey)];
    }else;
    //#warning 压缩深层嵌套模型数据量使用
    //    NSString* depth_model_conditions = @"\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\";
    //    [valueDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
    //        if([obj isKindOfClass:[NSString class]] && [obj containsString:depth_model_conditions]){
    //            if ([obj containsString:BGModel]) {
    //                obj = [obj stringByReplacingOccurrencesOfString:depth_model_conditions withString:@"^*"];
    //                obj = [obj stringByReplacingOccurrencesOfString:@"^*^*^*^*^*^*^*^*^*^*" withString:@"$#"];
    //                obj = [obj stringByReplacingOccurrencesOfString:@"$#$#$#$#$#" withString:@"~-"];
    //                valueDict[key] = [obj stringByReplacingOccurrencesOfString:@"~-~-~-" withString:@"+&"];
    //            }
    //        }
    //    }];
    return valueDict;
}

/**
 获取存储数据
 */
- (NSMutableDictionary *)getDictWithObject:(id)object ignoredKeys:(NSArray* const)ignoredKeys{
    NSMutableDictionary* modelInfoDictM = [NSMutableDictionary dictionary];
    NSArray* keyAndTypes = [NJF_DBTool getClassIvarList:[object class] Object:object onlyKey:NO];
    for(NSString* keyAndType in keyAndTypes){
        NSArray* keyTypes = [keyAndType componentsSeparatedByString:@"*"];
        NSString* propertyName = keyTypes[0];
        NSString* propertyType = keyTypes[1];
        if(![ignoredKeys containsObject:propertyName]){
            //数据库表列名(NJF_ + 属性名),加NJF_是为了防止和数据库关键字发生冲突.
            NSString* sqlColumnName = [NSString stringWithFormat:@"%@%@",NJF,propertyName];
            id propertyValue;
            id sqlValue;
            //crateTime和updateTime两个额外字段单独处理.
            if([propertyName isEqualToString:njf_createTimeKey] ||
               [propertyName isEqualToString:njf_updateTimeKey]){
                propertyValue = [NJF_DBTool stringWithDate:[NSDate new]];
            }else{
                propertyValue = [object valueForKey:propertyName];
            }
            if(propertyValue){
                //列值
                sqlValue = [NJF_DBTool getSqlValue:propertyValue type:propertyType encode:YES];
                modelInfoDictM[sqlColumnName] = sqlValue;
            }
        }
    }
    NSAssert(modelInfoDictM.allKeys.count,@"对象变量数据为空,不能存储!");
    return modelInfoDictM;
}

- (BOOL)ifNotExistCreateTableWithName:(NSString *const _Nonnull)name obj:(id _Nonnull)obj{
    //获取要忽略的字段
    NSArray *ignoreKeys = [NJF_DBTool executeSelector:njf_ignoreKeysSelector forClass:[obj class]];
    //获取"唯一约束"字段名
    NSArray *uniqueKeys = [NJF_DBTool executeSelector:njf_uniqueKeysSelector forClass:[obj class]];
    //获取“联合主键”字段名
    NSArray *unionPrimaryKeys = [NJF_DBTool executeSelector:njf_unionPrimaryKeysSelector forClass:[obj class]];
    __block BOOL result;
    [self isExistWithTableName:name complete:^(BOOL isSuccess) {
        if (!isSuccess){//如果不存在就新建
            NSArray* createKeys = [self njf_filtCreateKeys:[NJF_DBTool getClassIvarList:[obj class] Object:obj onlyKey:NO] ignoredkeys:ignoreKeys];
            [self creatTableWithTableName:name keys:createKeys unionPrimaryKeys:unionPrimaryKeys uniqueKeys:uniqueKeys complete:^(BOOL isSuccess) {
                result = isSuccess;
            }];
        }
    }];
    return result;
}

/**
 过滤建表的key.
 */
- (NSArray *)njf_filtCreateKeys:(NSArray *)njf_createkeys ignoredkeys:(NSArray *)njf_ignoredkeys{
    NSMutableArray* createKeys = [NSMutableArray arrayWithArray:njf_createkeys];
    NSMutableArray* ignoredKeys = [NSMutableArray arrayWithArray:njf_ignoredkeys];
    //判断是否有需要忽略的key集合.
    if (ignoredKeys.count){
        for(__block int i=0;i<createKeys.count;i++){
            if(ignoredKeys.count){
                NSString* createKey = [createKeys[i] componentsSeparatedByString:@"*"][0];
                [ignoredKeys enumerateObjectsUsingBlock:^(id  _Nonnull ignoreKey, NSUInteger idx, BOOL * _Nonnull stop) {
                    if([createKey isEqualToString:ignoreKey]){
                        [createKeys removeObjectAtIndex:i];
                        [ignoredKeys removeObjectAtIndex:idx];
                        i--;
                        *stop = YES;
                    }
                }];
            }else{
                break;
            }
        }
    }
    return createKeys;
}

- (void)njf_querryWithName:(NSString *const _Nonnull)name
                     conditions:(NSString *_Nullable)conditions
                  complete:(njf_complete_A)complete{
    NSAssert(name, @"表名为空");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self queryQueueWithTableName:name conditions:conditions complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)njf_deleteWithName:(NSString *_Nonnull)name
            conditions:(NSString *_Nullable)conditions
              complete:(njf_complete_B)complete{
    NSAssert(name, @"表名为空");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        [self deleteQueueWithTableName:name conditions:conditions complete:complete];
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (id _Nullable)njf_executeSql:(NSString* const _Nonnull)sql
                     tablename:(NSString* _Nonnull)tablename
                         class:(__unsafe_unretained _Nonnull Class)cla{
    NSAssert(sql,@"sql语句不能为空!");
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    __block id result;
    [self executeDB:^(FMDatabase * _Nonnull db){
        if([[sql lowercaseString] hasPrefix:@"select"]){
            // 1.查询数据
            FMResultSet *rs = [db executeQuery:sql];
            if (rs == nil) {
                NSLog(@"查询错误,数据不存在,请存储后再读取!");
                result = nil;
            }else{
                result = [NSMutableArray array];
            }
            result = [NSMutableArray array];
            // 2.遍历结果集
            while (rs.next) {
                NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
                for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                    dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
                }
                [result addObject:dictM];
            }
            //查询完后要关闭rs，不然会报@"Warning: there is at least one open result set around after performing
            [rs close];
            //转换结果
            result = [NJF_DBTool tansformDataFromSqlDataWithTableName:tablename class:cla array:result];
        }else{
            result = @([db executeUpdate:sql]);
        }
        NSLog(@"%@",sql);
    }];
    dispatch_semaphore_signal(self.semaphore);
    return result;
}

@end
