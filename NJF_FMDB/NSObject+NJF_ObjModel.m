//
//  NSObject+NJF_ObjModel.m
//  NJF_FMDB
//
//  Created by niujf on 2018/10/20.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import "NSObject+NJF_ObjModel.h"
#import <objc/runtime.h>

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
@end
