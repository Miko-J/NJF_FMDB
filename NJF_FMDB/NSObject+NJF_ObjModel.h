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
 同步 存储或更新 数组元素.
 @array 存放对象的数组.(数组中存放的是同一种类型的数据)
 当"唯一约束"或"主键"存在时，此接口会更新旧数据,没有则存储新数据.
 提示：“唯一约束”优先级高于"主键".
 */
- (BOOL)njf_saveOrUpdateWithName:(NSString *const _Nonnull)name
                           array:(NSArray *_Nonnull)array;

/**
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，更新以此参数为表名的数据.
 @where 条件参数,不能为nil.
 不支持keyPath.
 where使用规则请看demo或如下事例:
 1.将People类中name等于"马云爸爸"的数据的name更新为"马化腾":
 where = [NSString stringWithFormat:@"set %@=%@ where %@=%@",njf_sqlKey(@"name"),njf_sqlValue(@"马化腾"),njf_sqlKey(@"name"),njf_sqlValue(@"马云爸爸")];
 */
- (BOOL)njf_updateWithName:(NSString *_Nullable)name
                     where:(NSString *_Nonnull)where;

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
- (BOOL)njf_deleteWithName:(NSString *_Nullable)name
                     where:(NSString *_Nonnull)where;


/**
 查询表中的第一个元素
 @param name 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @return 返回第一个元素
 */
- (id _Nullable)njf_firstObjWithName:(NSString *_Nullable)name;

/**
 查询表中最后一个元素
 @param name 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @return 返回最后一个元素
 */
- (id _Nullable)njf_lastObjWithName:(NSString *_Nullable)name;

/**
 查询某一行数据
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @row 从第1行开始算起.
 */
- (id _Nullable)njf_objWithName:(NSString *_Nullable)name
                            row:(NSInteger)row;

/**
 同步查询所有结果.
 @tablename 当此参数为nil时,查询以此类名为表名的数据，非nil时，查询以此参数为表名的数据.
 @orderBy 要排序的key.
 @range 查询的范围(从location开始的后面length条，localtion要大于0).
 @desc YES:降序，NO:升序.
 */
- (NSArray *_Nullable)njf_find:(NSString* _Nullable)tablename
                       range:(NSRange)range orderBy:(NSString* _Nullable)orderBy
                         desc:(BOOL)desc;

/**
 查询该表中有多少条数据.
 @tablename 当此参数为nil时,查询以此类名为表名的数据条数，非nil时，查询以此参数为表名的数据条数.
 @where 条件参数,nil时查询所有以tablename为表名的数据条数.
 支持keyPath.
 使用规则请看demo或如下事例:
 1.查询People类中name等于"美国队长"的数据条数.
 where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长")];
 2.查询People类中user.student.human.body等于"小芳"的数据条数.
 where = [NSString stringWithFormat:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 3.查询People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据条数.
 where = [NSString stringWithFormat:@"where %@=%@ and %@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长"),bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
 */
- (NSInteger)njf_countTableWithName:(NSString *_Nullable)name
                          where:(NSString *_Nullable)where;

/**
 直接执行sql语句;
 @tablename nil时以cla类名为表名.
 @cla 要操作的类,nil时返回的结果是字典.
 提示：字段名要增加BG_前缀
 */
extern id _Nullable njf_executeSql(NSString* _Nonnull sql,NSString* _Nullable tablename,__unsafe_unretained _Nullable Class cla);

/**
 获取当前表的版本号
 @return 版本号
 */
- (NSInteger)njf_getTableVersionWithName:(NSString *_Nullable)name;

/**
 刷新,当类'唯一约束','联合主键','属性类型'发生改变时,调用此接口刷新一下.
 同步刷新.
 @name 当此参数为nil时,操作以此类名为表名的数据表，非nil时，操作以此参数为表名的数据表.
 @version 版本号,从1开始,依次往后递增.
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
 */
- (njf_dealState)njf_updateTableVersionWithName:(NSString *_Nullable)name
                                        version:(NSInteger)version;
@end

NS_ASSUME_NONNULL_END
