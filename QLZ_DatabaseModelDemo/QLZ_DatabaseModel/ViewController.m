//
//  ViewController.m
//  QLZ_Database
//
//  Created by 张庆龙 on 16/3/18.
//  Copyright © 2016年 张庆龙. All rights reserved.
//

#import "ViewController.h"
#import "User.h"
#import "NSObject+QLZ_JSON.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    itemsArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < 10; i++) {
        NSDictionary *dict = @{@"hello" : @"hello", @"name" : @"测试", @"age" : @(i * 10), @"sex" : @"1", @"father" : @{@"name" : @"father", @"age" : @(i + 20), @"sex" : @"1", @"father" : @{@"name" : @"fatherfather", @"age" : @(i + 30), @"sex" : @"1"}}, @"mother" : @{@"name" : @"mother", @"age" : @(i + 15), @"sex" : @"0"}};
        [array addObject:dict];
    }
    NSArray *userArray = [QLZ_JSONModelArray JSONWithClass:[User class] json:array];
    [itemsArray addObjectsFromArray:userArray];
    
    for (User *user in itemsArray) {
        NSLog(@"%@", [user transToDictionary]);
    }
    
    nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, (CGRectGetWidth(self.view.bounds) - 30) / 2, 50)];
    nameTextField.borderStyle = UITextBorderStyleLine;
    nameTextField.placeholder = @"姓名";
    [self.view addSubview:nameTextField];
    
    ageTextField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(nameTextField.frame) + 10, CGRectGetMinY(nameTextField.frame), CGRectGetWidth(nameTextField.bounds), 50)];
    ageTextField.borderStyle = UITextBorderStyleLine;
    ageTextField.keyboardType = UIKeyboardTypeNumberPad;
    ageTextField.placeholder = @"年龄";
    [self.view addSubview:ageTextField];
    
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    addButton.frame = CGRectMake(CGRectGetMinX(nameTextField.frame), CGRectGetMaxY(nameTextField.frame) + 10, CGRectGetWidth(nameTextField.bounds), CGRectGetHeight(nameTextField.bounds));
    [addButton setTitle:@"add" forState:UIControlStateNormal];
    [addButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(insertUser) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addButton];
    
    UIButton *selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    selectButton.frame = CGRectMake(CGRectGetMinX(ageTextField.frame), CGRectGetMaxY(ageTextField.frame) + 10, CGRectGetWidth(ageTextField.bounds), CGRectGetHeight(ageTextField.bounds));
    [selectButton setTitle:@"select" forState:UIControlStateNormal];
    [selectButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [selectButton addTarget:self action:@selector(selectUser) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:selectButton];
    
    databaseTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(addButton.frame) + 10, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(addButton.frame) - 10)];
    databaseTableView.delegate = self;
    databaseTableView.dataSource = self;
    [self.view addSubview:databaseTableView];
}

- (void)insertUser {
    if (nameTextField.text.length == 0 || ageTextField.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"输入不正确" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    NSDictionary *dict = @{@"name" : nameTextField.text, @"age" : @(ageTextField.text.intValue), @"sex" : @"1", @"father" : @{@"name" : @"father", @"age" : @(ageTextField.text.intValue), @"sex" : @"1"}, @"mother" : @{@"name" : @"mother", @"age" : @(ageTextField.text.intValue), @"sex" : @"1"}};
    User *user = [[User alloc] initWithJSON:dict];
    [user insertToDatabaseWithTableName:@"User" success:^(BOOL finished, int resultCode) {
        if (finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"添加成功" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil];
                [alertView show];
            });
        }
    }];
}

- (void)selectUser {
    [User selectModelInDatabaseWithTableName:@"User" where:@"user_sex = 1" orderBy:@"user_name" desc:NO success:^(NSArray *resultArray, int resultCode) {
        [itemsArray removeAllObjects];
        [itemsArray addObjectsFromArray:resultArray];
        dispatch_async(dispatch_get_main_queue(), ^{
            [databaseTableView reloadData];
        });
    }];
    //    [User selectModelInDatabaseWithTableName:@"User" success:^(NSArray *resultArray, int resultCode) {
    //        [itemsArray removeAllObjects];
    //        [itemsArray addObjectsFromArray:resultArray];
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            [databaseTableView reloadData];
    //        });
    //    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return itemsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *NameCell = @"NameCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NameCell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:NameCell];
    }
    User *user = itemsArray[indexPath.row];
    cell.textLabel.text = user.username;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", user.age];
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
