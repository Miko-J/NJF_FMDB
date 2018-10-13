//
//  NJF_DBTool.h
//  NJF_FMDB
//
//  Created by niujf on 2018/10/11.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NJF_DBTool : NSObject

/**
 判断并获取字段类型.
 */
+ (NSString *)keyType:(NSString *)param;

@end

NS_ASSUME_NONNULL_END
