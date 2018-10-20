//
//  NSObject+NJF_ObjModel.h
//  NJF_FMDB
//
//  Created by niujf on 2018/10/20.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (NJF_ObjModel)
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

@end

NS_ASSUME_NONNULL_END
