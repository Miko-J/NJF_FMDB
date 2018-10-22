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
@end
