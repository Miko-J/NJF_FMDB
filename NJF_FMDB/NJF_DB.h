//
//  NJF_DB.h
//  NJF_FMDB
//
//  Created by jinfeng niu on 2018/10/10.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "NJF_DBConfig.h"

@interface NJF_DB : NSObject

//信号量
@property (nonatomic, strong) dispatch_semaphore_t _Nullable semaphore;
/**
 自定义数据库名称
 */
@property (nonatomic, copy, nonnull) NSString *sqliteName;
/**
 获取单利函数
 */
+ (nonnull instancetype)shareManager;

/**
 关闭数据库
 */
- (void)closeDB;
/**************************数组操作*********************/
/**
  直接存储数组
 */
- (void)saveArray:(NSArray *_Nonnull)array
             name:(NSString *_Nonnull)name
         complete:(njf_complete_B)complete;

/**
 读取数组
 */
- (void)querryArrayWithName:(NSString *_Nonnull)name
                   complete:(njf_complete_A)complete;

/**
 更新数组元素
 */
- (void)updateobjWithName:(NSString *_Nonnull)name
                      obj:(id _Nonnull)obj
                    index:(NSInteger)index
                 complete:(njf_complete_B)complete;

/**
 删除数组某个位置上的元素
 */
- (void)deleteObjWithName:(NSString *_Nonnull)name
                    index:(NSInteger)index
                 complete:(njf_complete_B)complete;

/**
 查询数组某个位置上的元素
 */
- (void)querryWithName:(NSString *_Nonnull)name
                 index:(NSInteger)index
                 value:(void(^)(id value))value;

/**
  删除表中的所有数据
 */
- (void)dropSafeTable:(NSString *_Nonnull)name
             complete:(njf_complete_B)complete;

/**************************字典操作*********************/
/**
 直接存储字典
 */
- (void)saveDict:(NSDictionary *_Nonnull)dict
            name:(NSString *_Nonnull)name
        complete:(njf_complete_B)complete;

/**
遍历字典
 */
- (void)njf_enumerateKeysAndObjectsName:(NSString *_Nonnull)name
                                  block:(void(^ _Nonnull)(NSString *_Nonnull key, NSString *_Nonnull value, BOOL *stop))block
                               complete:(njf_complete_B)complete;

/**
 添加字典元素
 */
- (void)njf_setValueWithName:(NSString *_Nonnull)name value:(id _Nonnull)value
                         key:(NSString *_Nonnull)key
                    complete:(njf_complete_B)complete;

/**
 根据key更新字典元素
 */
- (void)njf_updateValueWithName:(NSString *_Nonnull)name value:(id _Nonnull)value
                            key:(NSString *_Nonnull)key
                       complete:(njf_complete_B)complete;

/**
 根据key获取value
 */
- (void)njf_valueForKeyWithName:(NSString *const _Nonnull)name
                           key:(NSString *_Nonnull)key
                  valueBlock:(void (^ _Nonnull)(id _Nonnull value))block;

/**
 根据key删除字典元素
 */
- (void)njf_deleteValueForKeyWithName:(NSString *const _Nonnull)name
                                  key:(NSString *_Nonnull)key
                             complete:(njf_complete_B)complete;
/**
 清除字典数据
 */
- (void)njf_clearDictWithName:(NSString *const _Nonnull)name
                     complete:(njf_complete_B)complete;
@end
