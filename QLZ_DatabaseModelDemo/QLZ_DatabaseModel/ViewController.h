//
//  ViewController.h
//  QLZ_Database
//
//  Created by 张庆龙 on 16/3/18.
//  Copyright © 2016年 张庆龙. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *databaseTableView;
    NSMutableArray *itemsArray;
    UITextField *nameTextField;
    UITextField *ageTextField;
}

@end

