//
//  NJF_DB.m
//  NJF_FMDB
//
//  Created by jinfeng niu on 2018/10/10.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import "NJF_DB.h"
#import "FMDB.h"

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

- (void)closeDB{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (_dbQueue) {
        [_dbQueue close];
        _dbQueue = nil;
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)saveArray:(NSArray *_Nonnull)array
             name:(NSString *_Nonnull)name
         complete:(njf_complete_B)complete{
    
}
@end
