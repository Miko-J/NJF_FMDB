//
//  NSObject+NJF_ObjModel.h
//  NJF_FMDB
//
//  Created by niujf on 2018/10/20.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NJF_DBConfig.h"

NS_ASSUME_NONNULL_BEGIN
@protocol NJF_DBProtocol <NSObject>

@optional

/**
 联合主键，可能有多个字段拼接而成，保证主键的唯一性,如果需要自定义，需要自己实现其函数
 @return 返回值是 “联合主键” 的字段名(即相对应的变量名).
  注：当“联合主键”和“唯一约束”同时定义时，“联合主键”优先级大于“唯一约束”.
 */
+ (NSArray *_Nonnull)njf_unionPrimaryKeys;

/**
 @return 返回不需要存储的属性
 */
+ (NSArray *_Nonnull)njf_ignoreKeys;
/**
 自定义 “唯一约束” 函数,如果需要 “唯一约束”字段,则在类中自己实现该函数.
 一般在保存字典的时候，key和value是一一对应的，保证key的唯一性，
 @return 返回值是 “唯一约束” 的字段数组(即相对应的变量名).
 */
+ (NSArray *_Nonnull)njf_uniqueKeys;

@end

@interface NSObject (NJF_ObjModel) <NJF_DBProtocol>
/**
 本库自带的自动增长主键.
 */
@property (nonatomic,strong) NSNumber *_Nonnull njf_id;
/**
 为了方便开发者，特此加入以下两个字段属性供开发者做参考.(自动记录数据的存入时间和更新时间)
 */
@property (nonatomic,copy) NSString *_Nonnull njf_createTime;//数据创建时间(即存入数据库的时间)
@property (nonatomic,copy) NSString *_Nonnull njf_updateTime;//数据最后那次更新的时间.
/**
 自定义表名
 */
@property (nonatomic,copy) NSString *_Nonnull njf_tableName;


/**
 保存一个对象
 @param name name
 @param obj obj
 @return BOOL
 */
- (BOOL)njf_saveObjWithName:(NSString *const _Nonnull)name
                    obj:(id _Nonnull)obj;
@end

NS_ASSUME_NONNULL_END
