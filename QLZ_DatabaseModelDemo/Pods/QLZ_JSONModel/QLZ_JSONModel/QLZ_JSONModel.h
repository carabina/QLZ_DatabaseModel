//
//  QLZ_JSONModel.h
//  MerchantPlatform
//
//  Created by 张庆龙 on 15/12/22.
//  Copyright © 2015年 张庆龙. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QLZ_JSONModel : NSObject <NSCopying>

- (id)initWithJSON:(NSDictionary *)json;

/**
 *	@brief	按照json字段和自定义property的映射字典 @{json字段:自定义property}，如果二者相同，可不写该方法
 *
 */
+ (NSDictionary *)JSONDictionary;

/**
 *	@brief 自定义property解析成特殊类，此类必须是QLZ_JSONModel的子类，如不写该方法，如果是QLZ_JSONModel的子类则也可以自动赋值，如是QLZ_JSONModel子类则返回正常json解析数据
 *
 *	@param propertyName 要解析成特殊类的自定义property字段名字
 */
+ (Class)classToProperty:(NSString *)propertyName;

/**
 *	@brief	把此类按照JSONDictionary的字段解析成json
 *
 */
- (NSDictionary *)transToDictionary;

@end

@interface QLZ_JSONModelArray : NSObject

/**
 *	@brief 把json数组按照aClass类解析成array aClass必须是QLZ_JSONModel的子类
 *
 *	@param json 要解析的json数组
 *              aClass 要解析数组的类
 */
+ (NSArray *)JSONWithClass:(Class)aClass json:(NSArray *)json;

@end
