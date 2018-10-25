//
//  NJF_DBTool.m
//  NJF_FMDB
//
//  Created by niujf on 2018/10/11.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "NJF_DBTool.h"
#import "NJF_DBConfig.h"
#import "NJF_DB.h"
#import "NSCache+NJF_Cache.h"
#import <objc/runtime.h>
#import <CoreData/CoreData.h>

static NSString *sqlText = @"text";         //数据库的字符类型
static NSString *sqlReal = @"real";         //数据库的浮点类型
static NSString *sqlInteger = @"integer";   //数据库的整数类型

static NSString *NJFValue = @"NJFValue";
static NSString *NJFData = @"NJFData";
static NSString *NJFArray = @"NJFArray";
static NSString *NJFSet = @"NJFSet";
static NSString *NJFDictionary = @"NJFDictionary";
static NSString *NJFModel = @"NJFModel";
static NSString *NJFMapTable = @"NJFMapTable";
static NSString *NJFHashTable = @"NJFHashTable";
static NSString *njf_typeHead_NS = @"@\"NS";
static NSString *njf_typeHead__NS = @"@\"__NS";
static NSString *njf_typeHead_UI = @"@\"UI";
static NSString *njf_typeHead__UI = @"@\"__UI";
//100M大小限制.
#define MaxData @(838860800)

/**
 *  遍历所有类的block（父类）
 */
typedef void (^NJFClassesEnumeration)(Class c, BOOL *stop);
static NSSet *foundationClasses_;

@implementation NJF_DBTool

/**
 自定义数据库名称.
 */
void njf_setSqliteName(NSString*_Nonnull sqliteName){
    if (![sqliteName isEqualToString:[NJF_DB shareManager].sqliteName]) {
        [NJF_DB shareManager].sqliteName = sqliteName;
    }
}

BOOL njf_deleteSqlite(NSString *_Nonnull sqliteName){
    __block BOOL result;
    [[NJF_DB shareManager] njf_deleteSqlite:sqliteName complete:^(BOOL isSuccess) {
        result = isSuccess;
    }];
    return result;
}
/**
 封装处理传入数据库的key和value.
 */
NSString *njf_sqlKey(NSString* key){
    return [NSString stringWithFormat:@"%@%@",NJF,key];
}

/**
 转换OC对象成数据库数据.
 */
id njf_sqlValue(id value){
    if([value isKindOfClass:[NSNumber class]]) {
        return value;
    }else if([value isKindOfClass:[NSString class]]){
        return [NSString stringWithFormat:@"'%@'",value];
    }else{
        NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
        value = [NJF_DBTool getSqlValue:value type:type encode:YES];
        if ([value isKindOfClass:[NSString class]]) {
            return [NSString stringWithFormat:@"'%@'",value];
        }else{
            return value;
        }
    }
}

/**
 判断是不是 "唯一约束" 字段.
 */
+ (BOOL)isUniqueKey:(NSString* _Nonnull)uniqueKey
              with:(NSString* _Nonnull)param{
    NSArray* array = [param componentsSeparatedByString:@"*"];
    NSString* key = array[0];
    return [uniqueKey isEqualToString:key];
}

/**
 抽取封装条件数组处理函数
 */
+ (NSArray *)where:(NSArray*)where{
    NSMutableArray* results = [NSMutableArray array];
    NSMutableString* SQL = [NSMutableString string];
    if(!(where.count%3)){
        [SQL appendString:@" where "];
        for(int i=0;i<where.count;i+=3){
            [SQL appendFormat:@"%@%@%@?",NJF,where[i],where[i+1]];
            if (i != (where.count-3)) {
                [SQL appendString:@" and "];
            }
        }
    }else{
        //NSLog(@"条件数组错误!");
        NSAssert(NO,@"条件数组错误!");
    }
    NSMutableArray* wheres = [NSMutableArray array];
    for(int i=0;i<where.count;i+=3){
        [wheres addObject:where[i+2]];
    }
    [results addObject:SQL];
    [results addObject:wheres];
    return results;
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
    return [NSString stringWithFormat:@"%@ %@",[NSString stringWithFormat:@"%@%@",NJF,key],sqlType];
}

+ (NSString *)getSqlType:(NSString*)type{
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
        return @{NJFArray:[self jsonStringWithArr:value]};
    }else if ([value isKindOfClass:[NSSet class]]){
        return @{NJFSet:[self jsonStringWithArr:value]};
    }else if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]){
        return @{NJFValue:value};
    }else if([value isKindOfClass:[NSData class]]){
        NSData* data = value;
        NSNumber* maxLength = MaxData;
        NSAssert(data.length<maxLength.integerValue,@"最大存储限制为100M");
        return @{NJFData:[value base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]};
    }else if ([value isKindOfClass:[NSDictionary class]]){
        return @{NJFDictionary:[self jsonStringWithDict:value]};
    }else if ([value isKindOfClass:[NSMapTable class]]){
        return @{NJFMapTable:[self jsonStringWithMapTable:value]};
    }else if([value isKindOfClass:[NSHashTable class]]){
        return @{NJFHashTable:[self jsonStringWithNSHashTable:value]};
    }else{
        NSString* modelKey = [NSString stringWithFormat:@"%@*%@",NJFModel,NSStringFromClass([value class])];
        return @{modelKey:[self jsonStringWithObject:value]};
    }
}

/**
 根据类获取变量名列表
 @onlyKey YES:紧紧返回key,NO:在key后面添加type.
 */
+ (NSArray *)getClassIvarList:(__unsafe_unretained Class)cla Object:(_Nullable id)object onlyKey:(BOOL)onlyKey{
    //获取缓存的属性信息
    NSCache* cache = [NSCache njf_cache];
    NSString* cacheKey;
    cacheKey = onlyKey?[NSString stringWithFormat:@"%@_IvarList_yes",NSStringFromClass(cla)]:[NSString stringWithFormat:@"%@_IvarList_no",NSStringFromClass(cla)];
    NSArray* cachekeys = [cache objectForKey:cacheKey];
    if(cachekeys){
        return cachekeys;
    }
    NSMutableArray* keys = [NSMutableArray array];
    if(onlyKey){
        [keys addObject:njf_primaryKey];
        [keys addObject:njf_createTimeKey];
        [keys addObject:njf_updateTimeKey];
    }else{
        //手动添加库自带的自动增长主键ID和类型q
        [keys addObject:[NSString stringWithFormat:@"%@*q",njf_primaryKey]];
        //建表时此处加入额外的两个字段(createTime和updateTime).
        [keys addObject:[NSString stringWithFormat:@"%@*@\"NSString\"",njf_createTimeKey]];
        [keys addObject:[NSString stringWithFormat:@"%@*@\"NSString\"",njf_updateTimeKey]];
    }
    [self njf_enumerateClasses:cla complete:^(__unsafe_unretained Class c, BOOL *stop) {
        unsigned int numIvars; //成员变量个数
        Ivar *vars = class_copyIvarList(c, &numIvars);
        for(int i = 0; i < numIvars; i++) {
            Ivar thisIvar = vars[i];
            NSString* key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];//获取成员变量的名
            if ([key hasPrefix:@"_"]) {
                key = [key substringFromIndex:1];
            }
            if (!onlyKey) {
                //获取成员变量的数据类型
                NSString* type = [NSString stringWithUTF8String:ivar_getTypeEncoding(thisIvar)];
                key = [NSString stringWithFormat:@"%@*%@",key,type];
            }
            [keys addObject:key];//存储对象的变量名
        }
        free(vars);//释放资源
    }];
    [cache setObject:keys forKey:cacheKey];
    return keys;
}

+ (void)njf_enumerateClasses:(__unsafe_unretained Class)srcCla complete:(NJFClassesEnumeration)enumeration
{
    // 1.没有block就直接返回
    if (enumeration == nil) return;
    // 2.停止遍历的标记
    BOOL stop = NO;
    // 3.当前正在遍历的类
    Class c = srcCla;
    // 4.开始遍历每一个类
    while (c && !stop) {
        // 4.1.执行操作
        enumeration(c, &stop);
        // 4.2.获得父类
        c = class_getSuperclass(c);
        if ([self isClassFromFoundation:c]) break;
    }
}

+ (BOOL)isClassFromFoundation:(Class)c
{
    if (c == [NSObject class] || c == [NSManagedObject class]) return YES;
    __block BOOL result = NO;
    [[self foundationClasses] enumerateObjectsUsingBlock:^(Class foundationClass, BOOL *stop) {
        if ([c isSubclassOfClass:foundationClass]) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

+ (NSSet *)foundationClasses
{
    if (foundationClasses_ == nil) {
        // 集合中没有NSObject，因为几乎所有的类都是继承自NSObject，具体是不是NSObject需要特殊判断
        foundationClasses_ = [NSSet setWithObjects:
                              [NSURL class],
                              [NSDate class],
                              [NSValue class],
                              [NSData class],
                              [NSError class],
                              [NSArray class],
                              [NSDictionary class],
                              [NSString class],
                              [NSAttributedString class], nil];
    }
    return foundationClasses_;
}

/**
 存储转换用的字典转化成对象处理函数.
 */
+ (id)objectFromJsonStringWithTableName:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla valueDict:(NSDictionary*)valueDict{
    id object = [cla new];
    NSMutableArray* valueDictKeys = [NSMutableArray arrayWithArray:valueDict.allKeys];
    NSMutableArray* keyAndTypes = [NSMutableArray arrayWithArray:[self getClassIvarList:cla Object:nil onlyKey:NO]];
    for(int i=0;i<valueDictKeys.count;i++){
        NSString* sqlKey = valueDictKeys[i];
        NSString* tempSqlKey = sqlKey;
        if([sqlKey containsString:NJF]){
            tempSqlKey = [sqlKey stringByReplacingOccurrencesOfString:NJF withString:@""];
        }
        for(NSString* keyAndType in keyAndTypes){
            NSArray* arrKT = [keyAndType componentsSeparatedByString:@"*"];
            NSString* key = [arrKT firstObject];
            NSString* type = [arrKT lastObject];
            if ([tempSqlKey isEqualToString:key]){
                id tempValue = valueDict[sqlKey];
                id ivarValue = [self getSqlValue:tempValue type:type encode:NO];
                !ivarValue?:[object setValue:ivarValue forKey:key];
                [keyAndTypes removeObject:keyAndType];
                [valueDictKeys removeObjectAtIndex:i];
                i--;
                break;//匹配处理完后跳出内循环.
            }
        }
    }
    [object setValue:tablename forKey:njf_tableNameKey];
    return object;
}

//根据NSDictionary转换从数据库读取回来的数组数据
+ (id)valueForArrayRead:(NSDictionary*)dictionary{
    NSString* key = dictionary.allKeys.firstObject;
    if ([key isEqualToString:NJFValue]) {
        return dictionary[key];
    }else if ([key isEqualToString:NJFData]){
        return [[NSData alloc] initWithBase64EncodedString:dictionary[key] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }else if([key isEqualToString:NJFSet]){
        return [self arrayFromJsonString:dictionary[key]];
    }else if([key isEqualToString:NJFArray]){
        return [self arrayFromJsonString:dictionary[key]];
    }else if ([key isEqualToString:NJFDictionary]){
        return [self dictionaryFromJsonString:dictionary[key]];
    }else if ([key containsString:NJFModel]){
        NSString* claName = [key componentsSeparatedByString:@"*"].lastObject;
        NSDictionary* valueDict = [self jsonWtihString:dictionary[key]];
        id object = [self objectFromJsonStringWithTableName:claName class:NSClassFromString(claName) valueDict:valueDict];
        return object;
    }else{
        NSAssert(NO,@"没有找到匹配的解析类型");
        return nil;
    }
}

//根据NSDictionary转换从数据库读取回来的字典数据
+ (id)valueForDictionaryRead:(NSDictionary*)dictDest{
    NSString* keyDest = dictDest.allKeys.firstObject;
    if([keyDest isEqualToString:NJFValue]){
        return dictDest[keyDest];
    }else if ([keyDest isEqualToString:NJFData]){
        return [[NSData alloc] initWithBase64EncodedString:dictDest[keyDest] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }else if([keyDest isEqualToString:NJFSet]){
        return [self arrayFromJsonString:dictDest[keyDest]];
    }else if([keyDest isEqualToString:NJFArray]){
        return [self arrayFromJsonString:dictDest[keyDest]];
    }else if([keyDest isEqualToString:NJFDictionary]){
        return [self dictionaryFromJsonString:dictDest[keyDest]];
    }else if([keyDest containsString:NJFModel]){
        NSString* claName = [keyDest componentsSeparatedByString:@"*"].lastObject;
        NSDictionary* valueDict = [self jsonWtihString:dictDest[keyDest]];
        return [self objectFromJsonStringWithTableName:claName class:NSClassFromString(claName) valueDict:valueDict];
    }else{
        NSAssert(NO,@"没有找到匹配的解析类型");
        return nil;
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
+ (NSString *)jsonStringWithMapTable:(NSMapTable*)mapTable{
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
+ (NSString *)jsonStringWithNSHashTable:(NSHashTable*)hashTable{
    NSMutableArray* arrM = [NSMutableArray array];
    NSArray* values = hashTable.objectEnumerator.allObjects;
    for(id value in values){
        [arrM addObject:[self dictionaryForArrInsert:value]];
    }
    return  [self dataToJson:arrM];
}

/**
 json字符转json格式数据 .
 */
+ (id)jsonWtihString:(NSString *)jsonString{
    NSAssert(jsonString,@"数据不能为空!");
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                             options:NSJSONReadingMutableContainers
                                               error:&err];
    
    NSAssert(!err,@"json解析失败");
    return dic;
}

+ (NSArray *)arrayFromJsonString:(NSString *)jsonString{
    if (!jsonString || [jsonString isKindOfClass:[NSNull class]]) return nil;
    if ([jsonString containsString:NJFModel] || [jsonString containsString:NJFData]) {
        NSMutableArray *arrM = [NSMutableArray array];
        NSArray *arr = [self jsonWtihString:jsonString];
        for (NSDictionary *dict in arr) {
            [arrM addObject:[self valueForArrayRead:dict]];
        }
        return arrM;
    }else{
        return [self jsonWtihString:jsonString];
    }
}

//json字符串转NSDictionary
+ (NSDictionary *)dictionaryFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    if([jsonString containsString:NJFModel] || [jsonString containsString:NJFData]){
        NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
        NSDictionary* dictSrc = [self jsonWtihString:jsonString];
        for(NSString* keySrc in dictSrc.allKeys){
            NSDictionary* dictDest = dictSrc[keySrc];
            dictM[keySrc]= [self valueForDictionaryRead:dictDest];
        }
        return dictM;
    }else{
        return [self jsonWtihString:jsonString];
    }
}

//json字符串转NSMapTable
+ (NSMapTable *)mapTableFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    NSDictionary* dict = [self jsonWtihString:jsonString];
    NSMapTable* mapTable = [NSMapTable new];
    for(NSString* key in dict.allKeys){
        id value = [self valueForDictionaryRead:dict[key]];
        [mapTable setObject:value forKey:key];
    }
    return mapTable;
}

//json字符串转NSHashTable
+ (NSHashTable *)hashTableFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    NSArray* arr = [self jsonWtihString:jsonString];
    NSHashTable* hashTable = [NSHashTable new];
    for (id obj in arr) {
        id value = [self valueForArrayRead:obj];
        [hashTable addObject:value];
    }
    return hashTable;
}

//json字符串转NSDate
+ (NSDate *)dateFromString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    NSDate *date = [formatter dateFromString:jsonString];
    return date;
}

//NSDate转字符串,格式: yyyy-MM-dd HH:mm:ss
+ (NSString *)stringWithDate:(NSDate*)date{
    NSDateFormatter* formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    return [formatter stringFromDate:date];
}

/**
 判断类是否实现了某个类方法.
 */
+ (id)executeSelector:(SEL)selector forClass:(Class)cla{
    id obj = nil;
    if([cla respondsToSelector:selector]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        obj = [cla performSelector:selector];
#pragma clang diagnostic pop
    }
    return obj;
}

//对象转json字符
+ (NSString *)jsonStringWithObject:(id)object{
    NSMutableDictionary* keyValueDict = [NSMutableDictionary dictionary];
    NSArray* keyAndTypes = [self getClassIvarList:[object class] Object:object onlyKey:NO];
    //忽略属性
    NSArray* ignoreKeys = [self executeSelector:njf_ignoreKeysSelector forClass:[object class]];
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
+ (id _Nonnull)getSqlValue:(id _Nonnull)value type:(NSString* _Nonnull)type encode:(BOOL)encode{
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
            NSData *data = UIImageJPEGRepresentation(value, 1.0);
            NSNumber* maxLength = MaxData;
            NSAssert(data.length<maxLength.integerValue,@"最大存储限制为100M");
            return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }else{
            return [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters]];
        }
    }else if(([type hasPrefix:njf_typeHead_UI]||[type hasPrefix:njf_typeHead__UI])&&[type containsString:@"Color"]){
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
                return [self jsonStringWithArr:@[value]];
            }else{//特殊类型
                return [[NSKeyedArchiver archivedDataWithRootObject:value] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            }
        }else{
            if([value containsString:NJFModel]){//自定义的类
                return [self arrayFromJsonString:value].firstObject;
            }else{//特殊类型
                NSData* data = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
                return [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
        }
        
    }
}
@end
