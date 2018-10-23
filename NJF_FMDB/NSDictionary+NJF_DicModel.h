//
//  NSDictionary+NJF_DicModel.h
//  NJF_FMDB
//
//  Created by niujf on 2018/10/11.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (NJF_DicModel)


/**
 存储字典
 @param name 唯一标识
 */
- (BOOL)njf_saveDictWithName:(NSString *const _Nonnull)name;

/**
 遍历字典
 @param block 回调
 */
+ (BOOL)njf_enumerateKeysAndObjectsName:(NSString *const _Nonnull)name
                                  block:(void(^ _Nonnull)(NSString *_Nonnull key, id _Nonnull value, BOOL *stop))block;

/**
  添加字典元素
 @param name 表名
 @param value value
 @param key key
 @return BOOL
 */
+ (BOOL)njf_setValueWithName:(NSString *const _Nonnull)name
                       value:(id _Nonnull)value
                         key:(NSString *_Nonnull)key;

/**
 更新字典元素
 @param name 表名
 @param value value
 @param key key
 @return BOOL
 */
+ (BOOL)njf_updateValueWithName:(NSString *const _Nonnull)name
                          value:(id _Nonnull)value
                            key:(NSString *_Nonnull)key;


/**
 根据key，查找value
 @param name name
 @param key key
 @return 返回一个value
 */
+ (id _Nonnull)njf_valueForKeyWithName:(NSString *const _Nonnull)name
                       key:(NSString *_Nonnull)key;


/**
 删除一个字典数据
 @param name name
 @param key key
 @return BOOL
 */
+ (BOOL)njf_deleteValueForKeyWithName:(NSString *const _Nonnull)name
                                  key:(NSString *_Nonnull)key;
/**
 清除字典数据
 @param name name
 @return BOOL
 */
+ (BOOL)njf_clearDictWithName:(NSString *const _Nonnull)name;

@end

NS_ASSUME_NONNULL_END
