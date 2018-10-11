//
//  NJF_DBTool.m
//  NJF_FMDB
//
//  Created by niujf on 2018/10/11.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//
#import "NJF_DBTool.h"
#import "NJF_DBConfig.h"
#import "NJF_DB.h"
@implementation NJF_DBTool

/**
 自定义数据库名称.
 */
void njf_setSqliteName(NSString*_Nonnull sqliteName){
    if (![sqliteName isEqualToString:[NJF_DB shareManager].sqliteName]) {
        [NJF_DB shareManager].sqliteName = sqliteName;
    }
}

@end
