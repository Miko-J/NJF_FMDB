//
//  NSArray+NJF_ArrModel.m
//  NJF_FMDB
//
//  Created by niujf on 2018/10/11.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import "NSArray+NJF_ArrModel.h"
#import "NJF_DB.h"
@implementation NSArray (NJF_ArrModel)

- (BOOL)njf_saveArrWithName:(NSString * const _Nonnull)name{
    if ([self isKindOfClass:[NSArray class]]) {
        __block BOOL result;
        [[NJF_DB shareManager] njf_saveArray:self name:name complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        //关闭数据库
        [[NJF_DB shareManager] njf_closeDB];
        return result;
    }else{
        return NO;
    }
}

+ (NSArray *_Nonnull)njf_arrayWithName:(NSString * const _Nonnull)name{
    __block NSMutableArray *arr;
    [[NJF_DB shareManager] njf_querryArrayWithName:name complete:^(NSArray * _Nullable array) {
        if (array && array.count > 0) {
            arr = [NSMutableArray arrayWithArray:array];
        }
    }];
    //关闭数据库
    [[NJF_DB shareManager] njf_closeDB];
    return arr;
}

+ (BOOL)njf_addObjWithName:(NSString * const _Nonnull)name obj:(id const _Nonnull)obj{
    __block BOOL result;
    [[NJF_DB shareManager] njf_saveArray:@[obj] name:name complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}

+ (BOOL)njf_updateObjWithName:(NSString *const _Nonnull)name
                          obj:(id _Nonnull)obj
                        index:(NSInteger)index{
    __block BOOL result;
    [[NJF_DB shareManager] njf_updateobjWithName:name obj:obj index:index complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[NJF_DB shareManager] njf_closeDB];
    return  result;
}

+ (BOOL)njf_deleteObjWithName:(NSString *const _Nonnull)name
                        index:(NSInteger)index{
    __block BOOL result;
    [[NJF_DB shareManager] njf_deleteObjWithName:name index:index complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[NJF_DB shareManager] njf_closeDB];
    return  result;
}

+ (id _Nullable)nif_ObjWithName:(NSString *const _Nonnull)name
                          index:(NSInteger)index{
    __block id resultValue;
    [[NJF_DB shareManager] njf_querryWithName:name index:index value:^(id value) {
        resultValue = value;
    }];
    //关闭数据库
    [[NJF_DB shareManager] njf_closeDB];
    return resultValue;
}

+ (BOOL)njf_clearArrayWithName:(NSString *const _Nonnull)name{
    __block BOOL result;
    [[NJF_DB shareManager] njf_dropSafeTable:name complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    //关闭数据库
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}

@end
