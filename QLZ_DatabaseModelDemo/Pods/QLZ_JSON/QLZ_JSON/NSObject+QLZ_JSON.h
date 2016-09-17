//
//  NSObject+QLZ_JSON.h
//  QLZ_JSON
//
//  Created by 张庆龙 on 16/8/4.
//  Copyright © 2016年 张庆龙. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (QLZ_JSON)

- (id)JSONValue;
- (NSString *)JSONString;
- (NSData *)JSONData;

@end
