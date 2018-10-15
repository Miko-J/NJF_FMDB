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

/**
 根据类属性值和属性类型返回数据库存储的值.
 @value 数值.
 @type 数组value的类型.
 @encode YES:编码 , NO:解码.
 */

/**
  根据类属性值和属性类型返回数据库存储的值.

 @param value 数值
 @param type 数组value的类型
 @param encode YES:编码 , NO:解码.
 @return 返回id类型的数据
 */
+(id _Nonnull)getSqlValue:(id _Nonnull)value type:(NSString* _Nonnull)type encode:(BOOL)encode;

@end

NS_ASSUME_NONNULL_END
