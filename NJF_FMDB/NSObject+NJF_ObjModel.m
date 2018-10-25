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
    return  result;
}
@end
