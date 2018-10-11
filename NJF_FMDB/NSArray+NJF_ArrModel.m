//
//  NSArray+NJF_ArrModel.m
//  NJF_FMDB
//
//  Created by niujf on 2018/10/11.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import "NSArray+NJF_ArrModel.h"

@implementation NSArray (NJF_ArrModel)

- (BOOL)njf_saveArrWithName:(NSString * const _Nonnull)name{
    if ([self isKindOfClass:[NSArray class]]) {
        return YES;
    }else{
        return NO;
    }
}

@end
