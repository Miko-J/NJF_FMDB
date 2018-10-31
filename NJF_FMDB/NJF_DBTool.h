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
 判断是不是主键.
 */
+(BOOL)isUniqueKey:(NSString* _Nonnull)uniqueKey
              with:(NSString* _Nonnull)param;

/**
 获取当前表的版本号
 @param key key
 @return NSInteger
 */
+ (NSInteger)getTableVersionWithkey:(NSString *_Nonnull)key;

/**
 设置当前表的版本号
 @param key key
 @param value value
 */
+ (void)setTableVersionWithKey:(NSString *_Nonnull)key
                         value:(NSInteger)value;

/**
 判断并获取字段类型.
 */
+ (NSString *)keyType:(NSString *)param;

/**
 NSDate转字符串,格式: yyyy-MM-dd HH:mm:ss
 */
+(NSString* _Nonnull)stringWithDate:(NSDate* _Nonnull)date;

/**
  根据类属性值和属性类型返回数据库存储的值.

 @param value 数值
 @param type 数组value的类型
 @param encode YES:编码 , NO:解码.
 @return 返回id类型的数据
 */
+(id _Nonnull)getSqlValue:(id _Nonnull)value
                     type:(NSString* _Nonnull)type
                   encode:(BOOL)encode;

/**
 抽取封装条件数组处理函数.
 */
+(NSArray *_Nonnull)where:(NSArray *_Nonnull)where;

/**
 判断并执行类方法.
 */
+ (id _Nonnull)executeSelector:(SEL)selector
                      forClass:(__unsafe_unretained Class)cla;

/**
 根据类获取变量名列表
 @onlyKey YES:紧紧返回key,NO:在key后面添加type.
 */
+ (NSArray *)getClassIvarList:(__unsafe_unretained Class)cla Object:(_Nullable id)object onlyKey:(BOOL)onlyKey;

/**
 转换从数据库中读取出来的数据.
 @tableName 表名(即类名).
 @array 传入要转换的数组数据.
 */
+ (NSArray *_Nonnull)tansformDataFromSqlDataWithTableName:(NSString *_Nonnull)name class:(__unsafe_unretained _Nonnull Class)cla array:(NSArray* _Nonnull)array;

/**
 过滤建表的key.
 */
+ (NSArray *)filtCreateKeys:(NSArray *)createkeys
                ignoredkeys:(NSArray *)ignoredkeys;

@end

NS_ASSUME_NONNULL_END
