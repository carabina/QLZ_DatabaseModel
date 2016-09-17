//
//  QLZ_JSONModel.m
//  MerchantPlatform
//
//  Created by 张庆龙 on 15/12/22.
//  Copyright © 2015年 张庆龙. All rights reserved.
//

#import "QLZ_JSONModel.h"
#import <objc/runtime.h>
#import "NSObject+QLZ_JSON.h"

@interface QLZ_JSONModelClass : NSObject

+ (NSDictionary *)readPropertiesAndPropertiesName:(Class)aClass;

@end

@implementation QLZ_JSONModelClass

+ (NSDictionary *)readPropertiesAndPropertiesName:(Class)aClass {
    NSMutableDictionary *propertiesDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    BOOL stop = NO;
    while (!stop && ![aClass isEqual:[QLZ_JSONModel class]]) {
        unsigned count = 0;
        objc_property_t *properties = class_copyPropertyList(aClass, &count);
        aClass = aClass.superclass;
        if (properties == NULL) {
            continue;
        }
        for (unsigned i = 0; i < count; i++) {
            NSString *propertyName = [QLZ_JSONModelClass getClassNameWithProperty:(properties[i])];
            if (propertyName.length == 0) {
                continue;
            }
            [propertiesDictionary setObject:propertyName forKey:@(property_getName(properties[i]))];
        }
        free(properties);
    }
    return propertiesDictionary;
}

+ (NSString *)getClassNameWithProperty:(objc_property_t)property {
    const char * const attrString = property_getAttributes(property);
    if (!attrString) {
        fprintf(stderr, "ERROR: Could not get attribute string from property %s\n", property_getName(property));
        return nil;
    }
    if (attrString[0] != 'T') {
        fprintf(stderr, "ERROR: Expected attribute string \"%s\" for property %s to start with 'T'\n", attrString, property_getName(property));
        return nil;
    }
    const char *typeString = attrString + 1;
    const char *next = NSGetSizeAndAlignment(typeString, NULL, NULL);
    if (!next) {
        fprintf(stderr, "ERROR: Could not read past type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return nil;
    }
    size_t typeLength = next - typeString;
    if (!typeLength) {
        fprintf(stderr, "ERROR: Invalid type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return nil;
    }
    if (typeString[0] == *(@encode(id)) && typeString[1] == '"') {
        const char *className = typeString + 2;
        next = strchr(className, '"');
        if (!next) {
            fprintf(stderr, "ERROR: Could not read class name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
            return nil;
        }
        if (next[2] == 'R') {
            fprintf(stderr, "ERROR: Could not read readonly class name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
            return nil;
        }
        if (className != next) {
            size_t classNameLength = next - className;
            char trimmedName[classNameLength + 1];
            strncpy(trimmedName, className, classNameLength);
            trimmedName[classNameLength] = '\0';
            return NSStringFromClass(objc_getClass(trimmedName));
        }
    }
    if (typeString[0] == 'c') {
        //当属性是布尔值的时候默认返回是char 需要转成NSNumber储存
        return NSStringFromClass(NSClassFromString(@"NSNumber"));
    }
    return NSStringFromClass(NSClassFromString(@"NSString"));
}

@end

@interface QLZ_JSONModel ()

@property (nonatomic, strong) NSMutableDictionary *propertiesDictionary;

@end

@implementation QLZ_JSONModel

- (id)init {
    self = [super init];
    if (self) {
        self.propertiesDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
        [self.propertiesDictionary addEntriesFromDictionary:[QLZ_JSONModelClass readPropertiesAndPropertiesName:[self class]]];
    }
    return self;
}

- (id)initWithJSON:(NSDictionary *)json {
    self = [self init];
    if (self) {
        if ([json isKindOfClass:[NSDictionary class]]) {
            [super setValuesForKeysWithDictionary:json];
        }
        else {
            id jsonValue = [json JSONValue];
            if ([jsonValue isKindOfClass:[NSDictionary class]]) {
                json = jsonValue;
                [super setValuesForKeysWithDictionary:json];
            }
        }
    }
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSString *propertyName = [[self class] JSONDictionary][key];
    if (propertyName.length == 0) {
        propertyName = key;
    }
    if ([self.propertiesDictionary.allKeys indexOfObject:propertyName] != NSNotFound) {
        [self setValue:value forKey:propertyName];
    }
    else if ([value isKindOfClass:[NSDictionary class]]) {
//        Class aClass = [[self class] classToProperty:propertyName];
//        if (aClass) {
//            return;
//        }
        NSDictionary *dict = (NSDictionary *)value;
        for (NSString *dictKey in dict.allKeys) {
            NSString *keyString = [NSString stringWithFormat:@"%@.%@", key, dictKey];
            [self setValue:dict[dictKey] forKey:keyString];
        }
    }
}

- (void)setValue:(id)value forKey:(NSString *)key {
    NSString *propertyName = [[self class] JSONDictionary][key];
    if (propertyName.length == 0) {
        propertyName = key;
    }
    NSString *property = self.propertiesDictionary[propertyName];
    id jsonValue = [value JSONValue];
    if ([jsonValue isKindOfClass:[NSArray class]] || [jsonValue isKindOfClass:[NSDictionary class]]) {
        value = jsonValue;
    }
    if (property.length > 0) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            Class aClass = [[self class] classToProperty:propertyName];
            if (!aClass) {
                aClass = NSClassFromString(property);
            }
            if (aClass && [aClass isSubclassOfClass:[QLZ_JSONModel class]]) {
                QLZ_JSONModel *model = [(QLZ_JSONModel *)[aClass alloc] initWithJSON:value];
                [super setValue:model forKey:propertyName];
            }
            else {
                [super setValue:value forKey:propertyName];
            }
            return;
        }
        if ([value isKindOfClass:NSClassFromString(property)]) {
            if ([value isKindOfClass:[NSArray class]]) {
                NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
                Class aClass = [[self class] classToProperty:propertyName];
                for (id obj in value) {
                    if (aClass) {
                        QLZ_JSONModel *model = [(QLZ_JSONModel *)[aClass alloc] initWithJSON:obj];
                        [array addObject:model];
                    }
                    else {
                        [array addObject:obj];
                    }
                }
                [super setValue:array forKey:propertyName];
                return;
            }
            [super setValue:value forKey:propertyName];
        }
        else {
            if ([value isKindOfClass:[NSNumber class]] && [NSClassFromString(property) isSubclassOfClass:[NSString class]]) {
                [super setValue:[NSString stringWithFormat:@"%@", value] forKey:key];
            }
            else if ([value isKindOfClass:[NSString class]] && [NSClassFromString(property) isSubclassOfClass:[NSNumber class]]) {
                [super setValue:value forKey:key];
            }
            else {
                id obj = [[NSClassFromString(property) alloc] init];
                if (obj) {
                    [super setValue:obj forKey:propertyName];
                }
            }
        }
        return;
    }
    [super setValue:value forKey:key];
}

+ (NSDictionary *)JSONDictionary {
    return nil;
}

+ (Class)classToProperty:(NSString *)propertyName {
    return nil;
}

- (NSDictionary *)transToDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    for (NSString *key in self.propertiesDictionary) {
        NSString *keyString = key;
        for (NSString *attribute in [[self class] JSONDictionary]) {
            NSString *property = [[self class] JSONDictionary][attribute];
            if ([property isEqualToString:key]) {
                keyString = attribute;
                break;
            }
        }
        id object = [self valueForKey:key];
        if (!object) {
            continue;
        }
        NSArray *array = [keyString componentsSeparatedByString:@"."];
        if (array.count <= 1) {
            dictionary[keyString] = [self valueWithObject:object];
        }
        else {
            NSMutableDictionary *dict;
            NSMutableDictionary *currentDict = dictionary;
            for (int i = 0; i < array.count; i++) {
                if (i == array.count - 1) {
                    dict[array[i]] = [self valueWithObject:object];
                }
                else {
                    dict = currentDict[array[i]];
                    if (!dict) {
                        dict = [NSMutableDictionary dictionaryWithCapacity:0];
                        currentDict[array[i]] = dict;
                    }
                }
                currentDict = dict;
            }
        }
    }
    return dictionary;
}

- (id)valueWithObject:(id)object {
    if (!object) {
        return nil;
    }
    if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
        for (id obj in object) {
            if ([obj isKindOfClass:[QLZ_JSONModel class]]) {
                [array addObject:[(QLZ_JSONModel *)obj transToDictionary]];
            }
            else {
                [array addObject:obj];
            }
        }
        return array;
    }
    else if ([object isKindOfClass:[QLZ_JSONModel class]]) {
        return [(QLZ_JSONModel *)object transToDictionary];
    }
    return object;
}

- (id)copyWithZone:(NSZone *)zone {
    QLZ_JSONModel *model = [[[self class] alloc] initWithJSON:[self transToDictionary]];
    return model;
}

@end

@implementation QLZ_JSONModelArray

+ (NSArray *)JSONWithClass:(Class)aClass json:(NSArray *)json {
    if (![aClass isSubclassOfClass:[QLZ_JSONModel class]]) {
        NSLog(@"传入的class不是QLZ_JSONModel的子类");
        return nil;
    }
    if ([json isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
        for (NSDictionary *dict in json) {
            QLZ_JSONModel *model = [(QLZ_JSONModel *)[aClass alloc] initWithJSON:dict];
            [array addObject:model];
        }
        return array;
    }
    NSLog(@"传入json不是数组");
    return nil;
}

@end

