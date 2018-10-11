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
        [[NJF_DB shareManager] saveArray:self name:name complete:^(BOOL isSuccess) {
            result = isSuccess;
        }];
        //关闭数据库
        [[NJF_DB shareManager] closeDB];
        return result;
    }else{
        return NO;
    }
}

@end