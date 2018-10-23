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
        [[NJF_DB shareManager] saveDict:self name:name complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        [[NJF_DB shareManager] closeDB];
        return result;
    }else{
        return NO;
    }
}

+ (BOOL)njf_enumerateKeysAndObjectsName:(NSString *const _Nonnull)name block:(void(^ _Nonnull)(NSString *_Nonnull key, NSString *_Nonnull value, BOOL *stop))block{
    __block BOOL result;
    [[NJF_DB shareManager] njf_enumerateKeysAndObjectsName:name block:block complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    [[NJF_DB shareManager] closeDB];
    return result;
}
@end
