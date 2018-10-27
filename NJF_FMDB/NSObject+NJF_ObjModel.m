//
//  NSObject+NJF_ObjModel.m
//  NJF_FMDB
//
//  Created by niujf on 2018/10/20.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import "NSObject+NJF_ObjModel.h"
#import <objc/runtime.h>
#import "NJF_DB.h"
#import "NJF_DBTool.h"

@implementation NSObject (NJF_ObjModel)

- (void)setNjf_id:(NSNumber *)njf_id{
    objc_setAssociatedObject(self, @selector(njf_id), njf_id, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)njf_id{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setNjf_createTime:(NSString *)njf_createTime{
    objc_setAssociatedObject(self, @selector(njf_createTime), njf_createTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)njf_createTime{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setNjf_updateTime:(NSString *)njf_updateTime{
    objc_setAssociatedObject(self, @selector(njf_updateTime), njf_updateTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)njf_updateTime{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setNjf_tableName:(NSString *)njf_tableName{
    objc_setAssociatedObject(self, @selector(njf_tableName), njf_tableName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)njf_tableName{
    return objc_getAssociatedObject(self, _cmd);
}

- (BOOL)njf_saveObjWithName:(NSString *const _Nonnull)name
                    obj:(id _Nonnull)obj{
    __block BOOL result;
    [[NJF_DB shareManager] njf_saveObjWithName:name obj:obj complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}

- (NSArray *_Nullable)njf_findWithName:(NSString *_Nullable)name
                                 where:(NSString *_Nullable)where{
    if (name == nil) {
        name = NSStringFromClass([self class]);
    }
    __block NSArray *result;
    [[NJF_DB shareManager] njf_querryWithName:name conditions:where complete:^(NSArray * _Nullable array) {
        result = array;
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return  result;
}

- (NSArray *_Nullable)njf_findWithName:(NSString *_Nullable)name
                              dateType:(njf_dataTimeType)dateType
                              dateTime:(NSString *_Nonnull)dateTime{
    if (name == nil) {
        name = NSStringFromClass([self class]);
    }
    NSMutableString* like = [NSMutableString string];
    [like appendFormat:@"'%@",dateTime];
    [like appendString:@"%'"];
    NSString* where;
    if (dateType == njf_createTime) {
        where = [NSString stringWithFormat:@"where %@ like %@",njf_sqlKey(njf_createTimeKey),like];
    }else{
        where = [NSString stringWithFormat:@"where %@ like %@",njf_sqlKey(njf_createTimeKey),like];
    }
    __block NSArray *result;
    [[NJF_DB shareManager] njf_querryWithName:name conditions:where complete:^(NSArray * _Nullable array) {
        result = [NJF_DBTool tansformDataFromSqlDataWithTableName:name class:[self class] array:array];
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return  result;
}

- (BOOL)njf_deleteWithName:(NSString *_Nullable)name where:(NSString *_Nonnull)where{
    if (name == nil) {
        name = NSStringFromClass([self class]);
    }
    __block BOOL result;
    [[NJF_DB shareManager] njf_deleteWithName:name conditions:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return  result;
}

- (BOOL)njf_updateWithName:(NSString *_Nullable)name
                     where:(NSString *_Nonnull)where{
    if (name == nil) {
        name = NSStringFromClass([self class]);
    }
    __block BOOL result;
    id obj = [[self class] new];
    [[NJF_DB shareManager] njf_updateWithName:name obj:obj valueDict:nil conditions:where complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}

- (BOOL)njf_saveOrUpdateWithName:(NSString *const _Nonnull)name
                           array:(NSArray *_Nonnull)array{
    __block BOOL result;
    //获取ignorearr
    NSArray *ignoreKeys = [NJF_DBTool executeSelector:njf_ignoreKeysSelector forClass:[self class]];
    [[NJF_DB shareManager] njf_saveOrUpdateWithName:name arr:array ignoreKeys:ignoreKeys complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return  result;
}

- (id _Nullable)njf_firstObjWithName:(NSString *_Nullable)name{
    NSArray* array = [self njf_find:name limit:1 orderBy:nil desc:NO];
    return (array&&array.count)?array.firstObject:nil;
}

- (id _Nullable)njf_lastObjWithName:(NSString *_Nullable)name{
    NSArray* array = [self njf_find:name limit:1 orderBy:nil desc:YES];
    return (array&&array.count)?array.firstObject:nil;
}

- (id _Nullable)njf_objWithName:(NSString *_Nullable)name
                            row:(NSInteger)row{
    NSArray* array = [self njf_find:name range:NSMakeRange(row,1) orderBy:nil desc:NO];
    return (array&&array.count)?array.firstObject:nil;
}

id _Nullable njf_executeSql(NSString* _Nonnull sql,NSString* _Nullable tablename,__unsafe_unretained _Nullable Class cla){
    if (tablename == nil) {
        tablename = NSStringFromClass(cla);
    }
    id result = [[NJF_DB shareManager] njf_executeSql:sql tablename:tablename class:cla];
    //关闭数据库
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}

/**
 同步查询所有结果.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @orderBy 要排序的key.
 @limit 每次查询限制的条数,0则无限制.
 @desc YES:降序，NO:升序.
 */
- (NSArray *_Nullable)njf_find:(NSString *_Nullable)tablename limit:(NSInteger)limit orderBy:(NSString * _Nullable)orderBy desc:(BOOL)desc{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSMutableString* where = [NSMutableString string];
    orderBy?[where appendFormat:@"order by %@%@ ",NJF,orderBy]:[where appendFormat:@"order by %@ ",njf_rowid];
    desc?[where appendFormat:@"desc"]:[where appendFormat:@"asc"];
    !limit?:[where appendFormat:@" limit %@",@(limit)];
    __block NSArray* results;
    [[NJF_DB shareManager] queryObjectWithTableName:tablename class:[self class] where:where complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[NJF_DB shareManager] njf_closeDB];
    return results;
}

/**
 同步查询所有结果.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @orderBy 要排序的key.
 @range 查询的范围(从location开始的后面length条，localtion要大于0).
 @desc YES:降序，NO:升序.
 */
- (NSArray *_Nullable)njf_find:(NSString* _Nullable)tablename range:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc{
    if(tablename == nil) {
        tablename = NSStringFromClass([self class]);
    }
    NSMutableString* where = [NSMutableString string];
    orderBy?[where appendFormat:@"order by %@%@ ",NJF,orderBy]:[where appendFormat:@"order by %@ ",njf_rowid];
    desc?[where appendFormat:@"desc"]:[where appendFormat:@"asc"];
    NSAssert((range.location>0)&&(range.length>0),@"range参数错误,location应该大于零,length应该大于零");
    [where appendFormat:@" limit %@,%@",@(range.location-1),@(range.length)];
    __block NSArray* results;
    [[NJF_DB shareManager] queryObjectWithTableName:tablename class:[self class] where:where complete:^(NSArray * _Nullable array) {
        results = array;
    }];
    //关闭数据库
    [[NJF_DB shareManager] njf_closeDB];
    return results;
}
@end
