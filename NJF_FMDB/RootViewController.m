//
//  RootViewController.m
//  NJF_FMDB
//
//  Created by niujf on 2018/10/10.
//  Copyright © 2018年 jinfeng niu. All rights reserved.
//

#import "RootViewController.h"
#import "NJF_People.h"
#import "NSArray+NJF_ArrModel.h"
#import "NSDictionary+NJF_DicModel.h"

@interface RootViewController ()
- (IBAction)creatDB:(id)sender;
- (IBAction)modifyDB:(id)sender;
- (IBAction)addDB:(id)sender;
- (IBAction)removeDB:(id)sender;
- (IBAction)searchDB:(id)sender;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self testDict];
}

- (void)testDict{
//    NSDictionary *dict = @{@"haha":@"我是谁",@"hehe":@"我那知道"};
//    NJF_People *people = [[NJF_People alloc] init];
//    people.name = @"小明";
//    people.age = @(25);
//    people.height = 178.86;
//    NSDictionary *dict = @{@"666":@"我是谁",@"hehe":people};
//    [dict njf_saveDictWithName:@"niujinfeng"];
    //保存某个字典数据
    //[NSDictionary njf_setValueWithName:@"niujinfeng" value:@[@"lol",@"wzry"] key:@"sss"];
    //更新字典元素
    [NSDictionary njf_updateValueWithName:@"niujinfeng" value:@"是他是他就是他" key:@"666"];
    [NSDictionary njf_enumerateKeysAndObjectsName:@"niujinfeng" block:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        NSLog(@"存储的字典数据为%@:%@",key,value);
    }];
}

- (void)testArray{
    //存储数组
        NSArray *arr = @[@"哈哈",@"9527",@"3.5"];
        NSMutableArray *arrM = [NSMutableArray arrayWithArray:arr];
        NJF_People *people = [[NJF_People alloc] init];
        people.name = @"小明";
        people.age = @(25);
        people.height = 178.86;
        [arrM addObject:people];
        [arrM njf_saveArrWithName:@"niujinfeng"];
    //插入数据
    //    [NSArray njf_addObjWithName:@"niujinfeng" obj:@[@"双击666",@"帅是一种态度"]];
    //    [NSArray njf_addObjWithName:@"niujinfeng" obj:@"今天天气很冷"];
    //更新数据
    //    [NSArray njf_updateObjWithName:@"niujinfeng" obj:@"9875" index:1];
    //删除数据
    //    [NSArray njf_deleteObjWithName:@"niujinfeng" index:1];
    //获取表名下面某个索引的数据
    //    id value = [NSArray nif_ObjWithName:@"niujinfeng" index:1];
    //    NSLog(@"%@",value);
    [NSArray njf_clearArrayWithName:@"niujinfeng"];
    NSArray *array = [NSArray njf_arrayWithName:@"niujinfeng"];
    NSLog(@"查询得到的数组中的数据%@",array);
}

//创建数据库
- (IBAction)creatDB:(id)sender {
}
//修改
- (IBAction)modifyDB:(id)sender {
}
//增加
- (IBAction)addDB:(id)sender {
}
//移除
- (IBAction)removeDB:(id)sender {
}
//搜索
- (IBAction)searchDB:(id)sender {
}
@end
