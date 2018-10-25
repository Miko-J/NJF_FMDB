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

/**
 支持keyPath.
 @name 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @where 条件参数，可以为nil,nil时查询所有数据.
 where使用规则请看demo或如下事例:
 1.查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
 where = [NSString stringWithFormat:@"where %@=%@ and %@=%@ or %@=%@",bg_sqlKey(@"age"),bg_sqlValue(@(45)),bg_sqlKey(@"name"),bg_sqlValue(@"爸爸"),bg_sqlKey(@"name"),bg_sqlValue(@"马哥")];
 2.查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
 where = [NSString stringWithFormat:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳",@"user1.name",bg_contains,@"fuck"])];
 3.查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
 where = [NSString stringWithFormat:@"where %@ and %@=%@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳",@"user1.name",bg_contains,@"fuck"]),bg_sqlKey(@"name"),bg_sqlValue(@"爸爸")];
 */
- (NSArray *_Nullable)njf_findWithName:(NSString *_Nullable)name
                                 where:(NSString *_Nullable)where;

/**
 查询某一时间段的数据.(存入时间或更新时间)
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @dateTime 参数格式：
 2018 即查询2018年的数据
 2018-07 即查询2018年7月的数据
 2018-07-19 即查询2018年7月19日的数据
 2018-07-19 16 即查询2018年7月19日16时的数据
 2018-07-19 16:17 即查询2018年7月19日16时17分的数据
 2018-07-19 16:17:53 即查询2018年7月19日16时17分53秒的数据
 2018-07-19 16:17:53.350 即查询2018年7月19日16时17分53秒350毫秒的数据
 */
- (NSArray *_Nullable)njf_findWithName:(NSString *_Nullable)name
                              dateType:(njf_dataTimeType)dateType
                              dateTime:(NSString *_Nonnull)dateTime;

/**
 @name 当此参数为nil时,查询以此类名为表名的数据，非nil时，删除以此参数为表名的数据.
 @where 条件参数,可以为nil，nil时删除所有以tablename为表名的数据.
 支持keyPath.
 where使用规则请看demo或如下事例:
 1.删除People类中name等于"美国队长"的数据.
 where = [NSString stringWithFormat:@"where %@=%@",njf_sqlKey(@"name"),njf_sqlValue(@"美国队长")];
 2.删除People类中user.student.human.body等于"小芳"的数据.
 where = [NSString stringWithFormat:@"where %@",bg_keyPathValues(@[@"user.student.human.body",njf_equal,@"小芳"])];
 3.删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据.
 where = [NSString stringWithFormat:@"where %@=%@ and %@",njf_sqlKey(@"name"),njf_sqlValue(@"美国队长"),njf_keyPathValues(@[@"user.student.human.body",njf_equal,@"小芳"])];
  */
- (BOOL)njf_deleteWithName:(NSString *_Nullable)name where:(NSString *_Nonnull)where;
@end

NS_ASSUME_NONNULL_END
