//
//  NJF_DBConfig.h
//  NJF_FMDB
//
//  Created by niujf on 2018/10/11.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#ifndef NJF_DBConfig_h
#define NJF_DBConfig_h

static NSString *njf_primaryKey = @"njf_id";
static NSString *NJF = @"NJF_";
static NSString *njf_rowid = @"rowid";
static NSString *njf_createTimeKey = @"njf_createTime";
static NSString *njf_updateTimeKey = @"njf_updateTime";
static NSString *njf_tableNameKey = @"njf_tableName";
static NSInteger MaxQueryPageNum = 50;

#define njf_complete_B void(^_Nullable)(BOOL isSuccess)
#define njf_complete_A void(^_Nullable)(NSArray *_Nullable array)
#define njf_complete_I void(^_Nullable)(njf_dealState result)

#define njf_ignoreKeysSelector NSSelectorFromString(@"njf_ignoreKeys")
#define njf_uniqueKeysSelector NSSelectorFromString(@"njf_uniqueKeys")
#define njf_unionPrimaryKeysSelector NSSelectorFromString(@"njf_unionPrimaryKeys")
/**
 自定义数据库名称.
 */
extern void njf_setSqliteName(NSString *_Nonnull sqliteName);

/**
 删除数据库文件
 */
extern BOOL njf_deleteSqlite(NSString *_Nonnull sqliteName);

/**
 封装处理传入数据库的key和value.
 */
extern NSString *_Nonnull njf_sqlKey(NSString *_Nonnull key);

/**
 转换OC对象成数据库数据.
 */
extern id _Nonnull njf_sqlValue(id _Nonnull value);

typedef NS_ENUM(NSInteger,njf_changeState){//数据改变状态
    njf_insert,//插入
    njf_update,//更新
    njf_delete,//删除
    njf_drop//删表
};

typedef NS_ENUM(NSInteger,njf_getModelInfoType){//过滤数据类型
    njf_ModelInfoInsert,//插入过滤
    njf_ModelInfoSingleUpdate,//单条更新过滤
    njf_ModelInfoArrayUpdate,//批量更新过滤
    njf_ModelInfoNone//无过滤
};

typedef NS_ENUM(NSInteger,njf_dealState){//处理状态
    njf_error = -1,//处理失败
    njf_incomplete = 0,//处理不完整
    njf_complete = 1//处理完整
};

typedef NS_ENUM(NSInteger,njf_dataTimeType){
    njf_createTime,//存储时间
    njf_updateTime,//更新时间
};
#endif /* NJF_DBConfig_h */
