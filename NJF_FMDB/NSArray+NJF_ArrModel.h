//
//  NSArray+NJF_ArrModel.h
//  NJF_FMDB
//
//  Created by niujf on 2018/10/11.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (NJF_ArrModel)

/**
 存储数组.
 @name 唯一标识名称.
 **/
- (BOOL)njf_saveArrWithName:(NSString * const _Nonnull)name;

/**
 根据表名获取数组存储的元素
 @param name 表名
 @return 返回一个数组
 */
+ (NSArray *_Nonnull)njf_arrayWithName:(NSString * const _Nonnull)name;

/**
 根据表名在数组中添加元素
 @param name 表名
 @param obj 要添加的元素
 @return BOOL
 */
+ (BOOL)njf_addObjWithName:(NSString *const _Nonnull)name
                       obj:(id const _Nonnull)obj;


/**
 根据索引和表名在数组中更新元素
 @param name 表名
 @param obj 要更新的元素
 @param index 索引
 @return BOOL
 */
+ (BOOL)njf_updateObjWithName:(NSString *const _Nonnull)name
                          obj:(id _Nonnull)obj
                        index:(NSInteger)index;
@end

NS_ASSUME_NONNULL_END
