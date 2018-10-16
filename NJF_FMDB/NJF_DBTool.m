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

static NSString *njfValue = @"BGValue";
static NSString *njfData = @"BGData";
static NSString *njfArray = @"BGArray";
static NSString *njfSet = @"BGSet";
static NSString *njfDictionary = @"BGDictionary";
static NSString *njfModel = @"BGModel";
static NSString *njfMapTable = @"BGMapTable";
static NSString *njfHashTable = @"BGHashTable";
static NSString *njf_typeHead_NS = @"@\"NS";
static NSString *njf_typeHead__NS = @"@\"__NS";
static NSString *njf_typeHead_UI = @"@\"UI";
static NSString *njf_typeHead__UI = @"@\"__UI";
//100M大小限制.
#define MaxData @(838860800)

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

/**
 字典转json字符
 */
+ (NSString *)dataToJson:(id)data{
    NSAssert(data, @"数据不能为空");
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

//根据value类型返回用于数组插入数据库的NSDictionary
+ (NSDictionary *)dictionaryForArrInsert:(id)value{
    if ([value isKindOfClass:[NSArray class]]){
        return @{njfArray:[self jsonStringWithArr:value]};
    }else if ([value isKindOfClass:[NSSet class]]){
        return @{njfSet:[self jsonStringWithArr:value]};
    }else if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]){
        return @{njfValue:value};
    }else if([value isKindOfClass:[NSData class]]){
        NSData* data = value;
        NSNumber* maxLength = MaxData;
        NSAssert(data.length<maxLength.integerValue,@"最大存储限制为100M");
        return @{njfData:[value base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]};
    }else if ([value isKindOfClass:[NSDictionary class]]){
        return @{njfDictionary:[self jsonStringWithDict:value]};
    }else if ([value isKindOfClass:[NSMapTable class]]){
        return @{njfMapTable:[self jsonStringWithMapTable:value]};
    }else if([value isKindOfClass:[NSHashTable class]]){
        return @{njfHashTable:[self jsonStringWithNSHashTable:value]};
    }else{
        NSString* modelKey = [NSString stringWithFormat:@"%@*%@",njfModel,NSStringFromClass([value class])];
        return @{modelKey:[self jsonStringWithObject:value]};
    }
}

//NSArray,NSSet转json字符
+ (NSString *)jsonStringWithArr:(id)arr{
    if ([NSJSONSerialization isValidJSONObject:arr]) {
        return [self dataToJson:arr];
    }else{
        NSMutableArray *arrM = [NSMutableArray array];
        for (id value in arr) {
            [arrM addObject:[self dictionaryForArrInsert:value]];
        }
        return [self dataToJson:arrM];
    }
}

//字典转json字符串
+ (NSString *)jsonStringWithDict:(NSDictionary *)dict{
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        return [self dataToJson:dict];
    }else{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (NSString *key in dict.allKeys) {
            dict[key] = [self dictionaryForArrInsert:dict[key]];
        }
        return [self dataToJson:dict];
    }
}

//NSMapTable转json字符串.
+(NSString*)jsonStringWithMapTable:(NSMapTable*)mapTable{
    NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
    NSArray* objects = mapTable.objectEnumerator.allObjects;
    NSArray* keys = mapTable.keyEnumerator.allObjects;
    for(int i=0;i<objects.count;i++){
        NSString* key = keys[i];
        id object = objects[i];
        dictM[key] = [self dictionaryForArrInsert:object];
    }
    return [self dataToJson:dictM];
}

//NSHashTable转json字符串.
+(NSString*)jsonStringWithNSHashTable:(NSHashTable*)hashTable{
    NSMutableArray* arrM = [NSMutableArray array];
    NSArray* values = hashTable.objectEnumerator.allObjects;
    for(id value in values){
        [arrM addObject:[self dictionaryForArrInsert:value]];
    }
    return  [self dataToJson:arrM];
}

//对象转json字符
+(NSString *)jsonStringWithObject:(id)object{
    NSMutableDictionary* keyValueDict = [NSMutableDictionary dictionary];
    NSArray* keyAndTypes = [BGTool getClassIvarList:[object class] Object:object onlyKey:NO];
    //忽略属性
    NSArray* ignoreKeys = [BGTool executeSelector:bg_ignoreKeysSelector forClass:[object class]];
    for(NSString* keyAndType in keyAndTypes){
        NSArray* arr = [keyAndType componentsSeparatedByString:@"*"];
        NSString* propertyName = arr[0];
        NSString* propertyType = arr[1];
        
        if([ignoreKeys containsObject:propertyName])continue;
        
        if(![propertyName isEqualToString:njf_primaryKey]){
            id propertyValue = [object valueForKey:propertyName];
            if (propertyValue){
                id Value = [self getSqlValue:propertyValue type:propertyType encode:YES];
                keyValueDict[propertyName] = Value;
            }
        }
    }
    return [self dataToJson:keyValueDict];
}

//跟value和数据类型type 和编解码标志 返回编码插入数据库的值,或解码数据库的值.
+(id _Nonnull)getSqlValue:(id _Nonnull)value type:(NSString* _Nonnull)type encode:(BOOL)encode{
    if (!value || [value isKindOfClass:[NSNull class]]) return nil;
    if(([type hasPrefix:njf_typeHead_NS]||[type hasPrefix:njf_typeHead__NS])&&[type containsString:@"String"]){
        if([type containsString:@"AttributedString"]){//处理富文本.
            if(encode) {
                return [[NSKeyedArchiver archivedDataWithRootObject:value] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            }else{
                NSData* data = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
                return [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
        }else{
            return value;
        }
    }else if(([type hasPrefix:njf_typeHead_NS]||[type hasPrefix:njf_typeHead__NS])&&[type containsString:@"Number"]){
        if(encode) {
            return [NSString stringWithFormat:@"%@",value];
        }else{
            return [[NSNumberFormatter new] numberFromString:value];
        }
    }else if(([type hasPrefix:njf_typeHead_NS]||[type hasPrefix:njf_typeHead__NS])&&[type containsString:@"Array"]){
        if(encode){
            return [self jsonStringWithArr:value];
        }else{
            return [self arrayFromJsonString:value];
        }
    }else if(([type hasPrefix:njf_typeHead_NS]||[type hasPrefix:njf_typeHead__NS])&&[type containsString:@"Dictionary"]){
        if(encode){
            return [self jsonStringWithDict:value];
        }else{
            return [self dictionaryFromJsonString:value];
        }
    }else if(([type hasPrefix:njf_typeHead_NS]||[type hasPrefix:njf_typeHead__NS])&&[type containsString:@"Set"]){
        if(encode){
            return [self jsonStringWithArr:value];
        }else{
            return [self arrayFromJsonString:value];
        }
    }else if(([type hasPrefix:njf_typeHead_NS]||[type hasPrefix:njf_typeHead__NS])&&[type containsString:@"Data"]){
        if(encode){
            NSData* data = value;
            NSNumber* maxLength = MaxData;
            NSAssert(data.length<maxLength.integerValue,@"最大存储限制为100M");
            return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }else{
            return [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
        }
    }else if(([type hasPrefix:njf_typeHead_NS]||[type hasPrefix:njf_typeHead__NS])&&[type containsString:@"MapTable"]){
        if(encode){
            return [self jsonStringWithMapTable:value];
        }else{
            return [self mapTableFromJsonString:value];
        }
    }else if(([type hasPrefix:njf_typeHead_NS]||[type hasPrefix:njf_typeHead__NS])&&[type containsString:@"HashTable"]){
        if(encode){
            return [self jsonStringWithNSHashTable:value];
        }else{
            return [self hashTableFromJsonString:value];
        }
    }else if(([type hasPrefix:njf_typeHead_NS]||[type hasPrefix:njf_typeHead__NS])&&[type containsString:@"Date"]){
        if(encode){
            return [self stringWithDate:value];
        }else{
            return [self dateFromString:value];
        }
    }else if(([type hasPrefix:njf_typeHead_NS]||[type hasPrefix:njf_typeHead__NS])&&[type containsString:@"URL"]){
        if(encode){
            return [value absoluteString];
        }else{
            return [NSURL URLWithString:value];
        }
    }else if(([type hasPrefix:njf_typeHead_UI]||[type hasPrefix:njf_typeHead__UI])&&[type containsString:@"Image"]){
        if(encode){
            NSData* data = UIImageJPEGRepresentation(value, 1);
            NSNumber* maxLength = MaxData;
            NSAssert(data.length<maxLength.integerValue,@"最大存储限制为100M");
            return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }else{
            return [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters]];
        }
    }else if(([type hasPrefix:bg_typeHead_UI]||[type hasPrefix:bg_typeHead__UI])&&[type containsString:@"Color"]){
        if(encode){
            CGFloat r, g, b, a;
            [value getRed:&r green:&g blue:&b alpha:&a];
            return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
        }else{
            NSArray<NSString*>* arr = [value componentsSeparatedByString:@","];
            return [UIColor colorWithRed:arr[0].floatValue green:arr[1].floatValue blue:arr[2].floatValue alpha:arr[3].floatValue];
        }
    }else if ([type containsString:@"NSRange"]){
        if(encode){
            return NSStringFromRange([value rangeValue]);
        }else{
            return [NSValue valueWithRange:NSRangeFromString(value)];
        }
    }else if ([type containsString:@"CGRect"]&&[type containsString:@"CGPoint"]&&[type containsString:@"CGSize"]){
        if(encode){
            return NSStringFromCGRect([value CGRectValue]);
        }else{
            return [NSValue valueWithCGRect:CGRectFromString(value)];
        }
    }else if (![type containsString:@"CGRect"]&&[type containsString:@"CGPoint"]&&![type containsString:@"CGSize"]){
        if(encode){
            return NSStringFromCGPoint([value CGPointValue]);
        }else{
            return [NSValue valueWithCGPoint:CGPointFromString(value)];
        }
    }else if (![type containsString:@"CGRect"]&&![type containsString:@"CGPoint"]&&[type containsString:@"CGSize"]){
        if(encode){
            return NSStringFromCGSize([value CGSizeValue]);
        }else{
            return [NSValue valueWithCGSize:CGSizeFromString(value)];
        }
    }else if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
             [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
             [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
             [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
             [type isEqualToString:@"c"]||[type isEqualToString:@"C"]||
             [type isEqualToString:@"l"]||[type isEqualToString:@"L"]){
        return value;
    }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
             [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
        return value;
    }else{
        
        if(encode){
            NSBundle *bundle = [NSBundle bundleForClass:[value class]];
            if(bundle == [NSBundle mainBundle]){//自定义的类
                return [self jsonStringWithArray:@[value]];
            }else{//特殊类型
                return [[NSKeyedArchiver archivedDataWithRootObject:value] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            }
        }else{
            if([value containsString:BGModel]){//自定义的类
                return [self arrayFromJsonString:value].firstObject;
            }else{//特殊类型
                NSData* data = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
                return [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
        }
        
    }
}
@end
