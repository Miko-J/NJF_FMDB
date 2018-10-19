//
//  NJF_DBConfig.h
//  NJF_FMDB
//
//  Created by niujf on 2018/10/11.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#ifndef NJF_DBConfig_h
#define NJF_DBConfig_h

#define njf_primaryKey @"njf_id"
#define njf_complete_B void(^_Nullable)(BOOL isSuccess)
#define njf_complete_A void(^_Nullable)(NSArray *_Nullable array)
extern void njf_setSqliteName(NSString*_Nonnull sqliteName);

/**
 封装处理传入数据库的key和value.
 */
extern NSString *_Nonnull njf_sqlKey(NSString *_Nonnull key);

typedef NS_ENUM(NSInteger,njf_changeState){//数据改变状态
    njf_insert,//插入
    njf_update,//更新
    njf_delete,//删除
    njf_drop//删表
};

#endif /* NJF_DBConfig_h */
