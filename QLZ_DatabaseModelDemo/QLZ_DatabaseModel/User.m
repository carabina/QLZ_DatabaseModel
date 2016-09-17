//
//  User.m
//  QLZ_Database
//
//  Created by 张庆龙 on 16/3/27.
//  Copyright © 2016年 张庆龙. All rights reserved.
//

#import "User.h"

@implementation User

+ (NSDictionary *)JSONDictionary {
    return @{@"name" : @"username",
//             @"age" : @"age",
//             @"sex" : @"sex",
//             @"father" : @"father",
//             @"mother" : @"mother",
             };
}

+ (Class)classToProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"father"] || [propertyName isEqualToString:@"mother"]) {
        return [User class];
    }
    return nil;
}

+ (NSDictionary *)databaseDictionary {
    return @{@"user_name" : @"username",
             @"user_age" : @"age",
             @"user_sex" : @"sex",
             @"user_father_name" : @"father.username",
             @"user_mother_name" : @"mother.username"};
}

+ (NSArray *)databaseAnalysisEgnoreData {
    return @[@"user_name"];
}

- (void)analysisWithEgnoreData:(NSDictionary *)egnoreDictionary {
    self.username = egnoreDictionary[@"user_name"];
}

- (NSString *)readonly {
    return @"";
}

@end
