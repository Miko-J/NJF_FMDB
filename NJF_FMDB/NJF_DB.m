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

static NSString *const njf_primaryKey = @"njf_id";
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
                [self creatTableWithTableName:name keys:@[[NSString stringWithFormat:@"%@*i",njf_primaryKey],@"param*@\"NSString\"",@"index*i"] complete:nil];
            }
        }];
    }
    dispatch_semaphore_signal(self.semaphore);
}
@end
