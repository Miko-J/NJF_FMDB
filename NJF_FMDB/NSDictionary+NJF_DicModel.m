//
//  NSDictionary+NJF_DicModel.m
//  NJF_FMDB
//
//  Created by niujf on 2018/10/11.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import "NSDictionary+NJF_DicModel.h"
#import "NJF_DB.h"

@implementation NSDictionary (NJF_DicModel)

- (BOOL)njf_saveDictWithName:(NSString *const _Nonnull)name{
    if ([self isKindOfClass:[NSDictionary class]]) {
        __block BOOL result;
        [[NJF_DB shareManager] njf_saveDict:self name:name complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        [[NJF_DB shareManager] njf_closeDB];
        return result;
    }else{
        return NO;
    }
}

+ (BOOL)njf_enumerateKeysAndObjectsName:(NSString *const _Nonnull)name block:(void(^ _Nonnull)(NSString *_Nonnull key, id _Nonnull value, BOOL *stop))block{
    __block BOOL result;
    [[NJF_DB shareManager] njf_enumerateKeysAndObjectsName:name block:block complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}

+ (BOOL)njf_setValueWithName:(NSString *const _Nonnull)name
                       value:(id _Nonnull)value
                         key:(NSString *_Nonnull)key{
    __block BOOL result;
    [[NJF_DB shareManager] njf_setValueWithName:name value:value key:key complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}

+ (BOOL)njf_updateValueWithName:(NSString *const _Nonnull)name
                          value:(id _Nonnull)value
                            key:(NSString *_Nonnull)key{
    __block BOOL result;
    [[NJF_DB shareManager] njf_updateValueWithName:name value:value key:key complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}

+ (id _Nonnull)njf_valueForKeyWithName:(NSString *const _Nonnull)name
                                   key:(NSString *_Nonnull)key;{
    __block id result;
    [[NJF_DB shareManager] njf_valueForKeyWithName:name key:key valueBlock:^(id  _Nonnull value) {
        result = value;
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}

+ (BOOL)njf_deleteValueForKeyWithName:(NSString *const _Nonnull)name
                                  key:(NSString *_Nonnull)key{
    __block BOOL result;
    [[NJF_DB shareManager] njf_deleteValueForKeyWithName:name key:key complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}

+ (BOOL)njf_clearDictWithName:(NSString *const _Nonnull)name{
    __block BOOL result;
    [[NJF_DB shareManager] njf_clearDictWithName:name complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    [[NJF_DB shareManager] njf_closeDB];
    return result;
}
@end
