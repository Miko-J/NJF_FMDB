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

static NSString *sqlText = @"text";         //数据库的字符类型
static NSString *sqlReal = @"real";         //数据库的浮点类型
static NSString *sqlInteger = @"integer";   //数据库的整数类型
static NSString *njf = @"njf_";
@implementation NJF_DBTool

/**
 自定义数据库名称.
 */
void njf_setSqliteName(NSString*_Nonnull sqliteName){
    if (![sqliteName isEqualToString:[NJF_DB shareManager].sqliteName]) {
        [NJF_DB shareManager].sqliteName = sqliteName;
    }
}

+ (NSString *)keyType:(NSString *)param{
    NSArray* array = [param componentsSeparatedByString:@"*"];
    NSString* key = array[0];
    NSString* type = array[1];
    NSString* sqlType;
    type = [self getSqlType:type];
    if ([sqlText isEqualToString:type]) {
        sqlType = sqlText;
    }else if ([sqlReal isEqualToString:type]){
        sqlType = sqlReal;
    }else if ([sqlInteger isEqualToString:type]){
        sqlType = sqlInteger;
    }else{
        NSAssert(NO,@"没有找到匹配的类型!");
    }
    //设置列名(njf_ + 属性名),加njf_是为了防止和数据库关键字发生冲突.
    return [NSString stringWithFormat:@"%@ %@",[NSString stringWithFormat:@"%@%@",njf,key],sqlType];
}

+(NSString*)getSqlType:(NSString*)type{
    if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
       [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
       [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
       [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
       [type isEqualToString:@"c"]||[type isEqualToString:@"C"]|
       [type isEqualToString:@"l"]||[type isEqualToString:@"L"]) {
        return sqlInteger;
    }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
             [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
        return sqlReal;
    }else{
        return sqlText;
    }
}
@end
