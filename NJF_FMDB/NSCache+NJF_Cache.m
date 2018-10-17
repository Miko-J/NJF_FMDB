//
//  NSCache+NJF_Cache.m
//  NJF_FMDB
//
//  Created by niujf on 2018/10/17.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import "NSCache+NJF_Cache.h"

static NSCache * keyCaches;
@implementation NSCache (NJF_Cache)

+ (instancetype)njf_cache{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyCaches = [NSCache new];
    });
    return keyCaches;
}
@end
