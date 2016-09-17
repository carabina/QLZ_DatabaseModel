//
//  NSObject+QLZ_JSON.m
//  QLZ_JSON
//
//  Created by 张庆龙 on 16/8/4.
//  Copyright © 2016年 张庆龙. All rights reserved.
//

#import "NSObject+QLZ_JSON.h"

@implementation NSObject (QLZ_JSON)

- (id)JSONValue {
    if ([self isKindOfClass:[NSString class]]) {
        NSData *jsonData = [(NSString *)self dataUsingEncoding:NSUTF8StringEncoding];
        return [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    }
    return self;
}

- (NSData *)JSONData {
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSError *error;
        return [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    }
    return nil;
}

- (NSString *)JSONString {
    return [[NSString alloc] initWithData:[self JSONData] encoding:NSUTF8StringEncoding];
}

@end
