//
//  QLZ_DatabaseModel.m
//  QLZ_Database
//
//  Created by 张庆龙 on 16/3/18.
//  Copyright © 2016年 张庆龙. All rights reserved.
//

#import "QLZ_DatabaseModel.h"
#import "QLZ_DatabaseManager.h"
#import "NSObject+QLZ_JSON.h"

#define kDefaultTableName NSStringFromClass([self class])

@implementation QLZ_DatabaseModel

+ (NSString *)primaryKey {
    return nil;
}

+ (NSDictionary *)databaseDictionary {
    return [[self class] JSONDictionary];
}

+ (NSArray *)databaseAnalysisEgnoreData {
    return nil;
}

- (void)analysisWithEgnoreData:(NSDictionary *)egnoreDictionary {
    
}

- (id)initWithDatabaseJSON:(NSDictionary *)JSON {
    NSDictionary *databaseDictionary = [[self class] databaseDictionary];
    NSArray *egnoreData = [[self class] databaseAnalysisEgnoreData];
    NSMutableDictionary *egnoreDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    NSDictionary *jsonDictionary = [[self class] JSONDictionary];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    for (NSString *key in JSON.allKeys) {
        id jsonValue = JSON[key];
        if ([[jsonValue JSONValue] isKindOfClass:[NSArray class]] || [[jsonValue JSONValue] isKindOfClass:[NSDictionary class]]) {
            jsonValue = [jsonValue JSONValue];
        }
        if ([egnoreData containsObject:key]) {
            [egnoreDictionary setObject:jsonValue forKey:key];
            continue;
        }
        if ([databaseDictionary[key] isEqualToString:jsonDictionary[key]]) {
            [dictionary setObject:jsonValue forKey:key];
            continue;
        }
        BOOL changeValue = NO;
        NSString *value = databaseDictionary[key];
        for (NSString *jsonKey in jsonDictionary.allKeys) {
            if ([jsonDictionary[jsonKey] isEqualToString:value]) {
                [dictionary setObject:jsonValue forKey:jsonKey];
                changeValue = YES;
                break;
            }
        }
        if (changeValue) {
            continue;
        }
        NSString *keyPath = databaseDictionary[key];
        NSArray *array = [keyPath componentsSeparatedByString:@"."];
        if (array.count <= 1) {
            [dictionary setObject:jsonValue forKey:databaseDictionary[key]];
            continue;
        }
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
        NSMutableDictionary *currentDict;
        for (int i = 0; i < array.count; i++) {
            if (i == 0) {
                dict = dictionary[array[i]];
                if (!dict) {
                    dict = [NSMutableDictionary dictionaryWithCapacity:0];
                    [dictionary setObject:dict forKey:array[i]];
                }
            }
            else {
                if (i == array.count - 1) {
                    [currentDict setObject:jsonValue forKey:array[i]];
                }
                else {
                    dict = currentDict[array[i]];
                    if (!dict) {
                        dict = [NSMutableDictionary dictionaryWithCapacity:0];
                        [currentDict setObject:dict forKey:array[i]];
                    }
                }
            }
            currentDict = dict;
        }
    }
    self = [self initWithJSON:dictionary];
    if (egnoreData.count > 0) {
        [self analysisWithEgnoreData:egnoreDictionary];
    }
    return self;
}

#pragma mark CreateDatabase
+ (void)createDatabase {
    [[self class] createDatabaseWithTableName:nil];
}

+ (void)createDatabaseWithTableName:(NSString *)tableName {
    [[self class] createDatabaseWithTableName:tableName primaryKey:nil];
}

+ (void)createDatabaseWithTableName:(NSString *)tableName primaryKey:(NSString *)primaryKey {
    [[self class] createDatabaseWithTableName:tableName primaryKey:primaryKey success:nil];
}

+ (void)createDatabaseWithTableName:(NSString *)tableName primaryKey:(NSString *)primaryKey success:(void (^)(BOOL finished, int resultCode))success {
    if (primaryKey.length == 0) {
        primaryKey = [[self class] primaryKey];
    }
    [[QLZ_DatabaseManager sharedManager] createTableWithTableName:[[self class] getTableName:tableName] databaseDictionary:[[self class] databaseDictionary] primaryKey:primaryKey success:success];
}

#pragma mark InsertDatabase
- (void)insertToDatabase {
    [self insertToDatabaseWithTableName:nil];
}

- (void)insertToDatabaseWithTableName:(NSString *)tableName {
    [self insertToDatabaseWithTableName:tableName];
}

- (void)insertToDatabaseWithTableName:(NSString *)tableName success:(void (^)(BOOL finished, int resultCode))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName]];
    [[QLZ_DatabaseManager sharedManager] insertDatabaseWithTableName:[[self class] getTableName:tableName] databaseModel:self success:success];
}

- (void)insertToDatabaseWithPrimaryKey:(NSString *)primaryKey {
    [self insertToDatabaseWithTableName:nil primaryKey:primaryKey];
}

- (void)insertToDatabaseWithTableName:(NSString *)tableName primaryKey:(NSString *)primaryKey {
    [self insertToDatabaseWithTableName:tableName primaryKey:primaryKey];
}

- (void)insertToDatabaseWithTableName:(NSString *)tableName primaryKey:(NSString *)primaryKey success:(void (^)(BOOL, int))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName] primaryKey:primaryKey];
    [[QLZ_DatabaseManager sharedManager] insertDatabaseWithTableName:[[self class] getTableName:tableName] databaseModel:self success:success];
}

+ (void)insertToDatabaseWithTableName:(NSString *)tableName models:(NSArray *)models success:(void (^)(BOOL finished, int resultCode))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName]];
    [[QLZ_DatabaseManager sharedManager] insertDatabaseWithTableName:[[self class] getTableName:tableName] databaseModels:models success:success];
}

+ (void)insertToDatabaseWithTableName:(NSString *)tableName models:(NSArray *)models primaryKey:(NSString *)primaryKey success:(void (^)(BOOL finished, int resultCode))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName] primaryKey:primaryKey];
    [[QLZ_DatabaseManager sharedManager] insertDatabaseWithTableName:[[self class] getTableName:tableName] databaseModels:models success:success];
}

#pragma mark ReplaceDatabase
- (void)replaceToDatabase {
    [self replaceToDatabaseWithTableName:nil];
}

- (void)replaceToDatabaseWithTableName:(NSString *)tableName {
    [self replaceToDatabaseWithTableName:tableName success:nil];
}

- (void)replaceToDatabaseWithTableName:(NSString *)tableName success:(void (^)(BOOL finished, int resultCode))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName]];
    [[QLZ_DatabaseManager sharedManager] replaceDatabaseWithTableName:[[self class] getTableName:tableName] databaseModel:self success:success];
}

- (void)replaceToDatabaseWithPrimaryKey:(NSString *)primaryKey {
    [self replaceToDatabaseWithTableName:nil primaryKey:primaryKey];
}

- (void)replaceToDatabaseWithTableName:(NSString *)tableName primaryKey:(NSString *)primaryKey {
    [self replaceToDatabaseWithTableName:tableName primaryKey:primaryKey success:nil];
}

- (void)replaceToDatabaseWithTableName:(NSString *)tableName primaryKey:(NSString *)primaryKey success:(void (^)(BOOL, int))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName] primaryKey:primaryKey];
    [[QLZ_DatabaseManager sharedManager] replaceDatabaseWithTableName:[[self class] getTableName:tableName] databaseModel:self success:success];
}

+ (void)replaceToDatabaseWithTableName:(NSString *)tableName models:(NSArray *)models success:(void (^)(BOOL finished, int resultCode))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName]];
    [[QLZ_DatabaseManager sharedManager] replaceDatabaseWithTableName:[[self class] getTableName:tableName] databaseModels:models success:success];
}

+ (void)replaceToDatabaseWithTableName:(NSString *)tableName models:(NSArray *)models primaryKey:(NSString *)primaryKey success:(void (^)(BOOL, int))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName] primaryKey:primaryKey];
    [[QLZ_DatabaseManager sharedManager] replaceDatabaseWithTableName:[[self class] getTableName:tableName] databaseModels:models success:success];
}

#pragma mark UpdateDatabase
- (void)updateToDatabaseSets:(NSArray *)sets {
    [self updateToDatabaseWithTableName:nil sets:sets];
}

- (void)updateToDatabaseWithTableName:(NSString *)tableName sets:(NSArray *)sets {
    [self updateToDatabaseWithTableName:tableName sets:sets where:nil];
}

- (void)updateToDatabaseWithTableName:(NSString *)tableName sets:(NSArray *)sets where:(NSString *)where {
    [self updateToDatabaseWithTableName:tableName sets:sets where:where success:nil];
}

- (void)updateToDatabaseWithTableName:(NSString *)tableName sets:(NSArray *)sets where:(NSString *)where success:(void (^)(BOOL finished, int resultCode))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName]];
    [[QLZ_DatabaseManager sharedManager] updateDatabaseWithTableName:[[self class] getTableName:tableName] databaseModel:self sets:sets where:where success:success];
}

- (void)updateToDatabaseSets:(NSArray *)sets primaryKey:(NSString *)primaryKey {
    [self updateToDatabaseWithTableName:nil sets:sets primaryKey:primaryKey];
}

- (void)updateToDatabaseWithTableName:(NSString *)tableName sets:(NSArray *)sets primaryKey:(NSString *)primaryKey {
    [self updateToDatabaseWithTableName:tableName sets:sets where:nil primaryKey:primaryKey];
}

- (void)updateToDatabaseWithTableName:(NSString *)tableName sets:(NSArray *)sets where:(NSString *)where primaryKey:(NSString *)primaryKey {
    [self updateToDatabaseWithTableName:tableName sets:sets where:where primaryKey:primaryKey success:nil];
}

- (void)updateToDatabaseWithTableName:(NSString *)tableName sets:(NSArray *)sets where:(NSString *)where primaryKey:(NSString *)primaryKey success:(void (^)(BOOL, int))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName] primaryKey:primaryKey];
    [[QLZ_DatabaseManager sharedManager] updateDatabaseWithTableName:[[self class] getTableName:tableName] databaseModel:self sets:sets where:where success:success];
}

+ (void)updateToDatabaseSet:(NSString *)set where:(NSString *)where {
    [[self class] updateToDatabaseWithTableName:nil set:set where:where];
}

+ (void)updateToDatabaseWithTableName:(NSString *)tableName set:(NSString *)set where:(NSString *)where {
    [[self class] updateToDatabaseWithTableName:tableName set:set where:where success:nil];
}

+ (void)updateToDatabaseWithTableName:(NSString *)tableName set:(NSString *)set where:(NSString *)where success:(void (^)(BOOL finished, int resultCode))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName]];
    [[QLZ_DatabaseManager sharedManager] updateDatabaseWithTableName:[[self class] getTableName:tableName] databaseDictionary:[[self class] databaseDictionary] set:set where:where success:success];
}

+ (void)updateToDatabaseSet:(NSString *)set where:(NSString *)where primaryKey:(NSString *)primaryKey {
    [[self class] updateToDatabaseWithTableName:nil set:set where:where primaryKey:primaryKey];
}

+ (void)updateToDatabaseWithTableName:(NSString *)tableName set:(NSString *)set where:(NSString *)where primaryKey:(NSString *)primaryKey {
    [[self class] updateToDatabaseWithTableName:nil set:set where:where primaryKey:primaryKey success:nil];
}

+ (void)updateToDatabaseWithTableName:(NSString *)tableName set:(NSString *)set where:(NSString *)where primaryKey:(NSString *)primaryKey success:(void (^)(BOOL finished, int resultCode))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName] primaryKey:primaryKey];
    [[QLZ_DatabaseManager sharedManager] updateDatabaseWithTableName:[[self class] getTableName:tableName] databaseDictionary:[[self class] databaseDictionary] set:set where:where success:success];
}

#pragma mark DeleteDatabase
- (void)deleteFromDatabase {
    [self deleteFromDatabaseWithTableName:nil];
}

- (void)deleteFromDatabaseWithTableName:(NSString *)tableName {
    [self deleteFromDatabaseWithTableName:tableName success:nil];
}

- (void)deleteFromDatabaseWithTableName:(NSString *)tableName success:(void (^)(BOOL finished, int resultCode))success {
    [[QLZ_DatabaseManager sharedManager] deleteFromTableName:[[self class] getTableName:tableName] model:self primaryKey:nil success:success];
}

- (void)deleteFromDatabaseWithPrimaryKey:(NSString *)primaryKey {
    [self deleteFromDatabaseWithTableName:nil primaryKey:primaryKey];
}

- (void)deleteFromDatabaseWithTableName:(NSString *)tableName primaryKey:(NSString *)primaryKey {
    [self deleteFromDatabaseWithTableName:tableName primaryKey:primaryKey success:nil];
}

- (void)deleteFromDatabaseWithTableName:(NSString *)tableName primaryKey:(NSString *)primaryKey success:(void (^)(BOOL finished, int resultCode))success {
    [[QLZ_DatabaseManager sharedManager] deleteFromTableName:[[self class] getTableName:tableName] model:self primaryKey:primaryKey success:success];
}

+ (void)deleteFromDatabaseWithWhere:(NSString *)where {
    [[self class] deleteFromDatabaseWithTableName:nil where:where];
}

+ (void)deleteFromDatabaseWithTableName:(NSString *)tableName where:(NSString *)where {
    [[self class] deleteFromDatabaseWithTableName:tableName where:where success:nil];
}

+ (void)deleteFromDatabaseWithTableName:(NSString *)tableName where:(NSString *)where success:(void (^)(BOOL finished, int resultCode))success {
    [[QLZ_DatabaseManager sharedManager] deleteFromTableName:[[self class] getTableName:tableName] where:where success:success];
}

#pragma mark DeleteWholeDatabase
+ (void)deleteWholeDatabase {
    [[self class] deleteWholeDatabaseWithTableName:nil];
}

+ (void)deleteWholeDatabaseWithTableName:(NSString *)tableName {
    [[self class] deleteWholeDatabaseWithTableName:tableName success:nil];
}

+ (void)deleteWholeDatabaseWithTableName:(NSString *)tableName success:(void (^)(BOOL finished, int resultCode))success {
    [[QLZ_DatabaseManager sharedManager] deleteWholeTableWithTableName:[[self class] getTableName:tableName] success:success];
}

#pragma mark SelectDatabase
+ (void)selectModelInDatabaseWithSuccess:(void (^)(NSArray *, int))success {
    [[self class] selectModelInDatabaseWithTableName:nil success:success];
}

+ (void)selectModelInDatabaseWithTableName:(NSString *)tableName success:(void (^)(NSArray *, int))success {
    [[self class] selectModelInDatabaseWithTableName:tableName where:nil orderBy:nil desc:NO success:success];
}

+ (void)selectModelInDatabaseWithTableName:(NSString *)tableName where:(NSString *)where orderBy:(NSString *)orderBy desc:(BOOL)desc success:(void (^)(NSArray *, int))success {
    [[self class] selectModelInDatabaseWithTableName:tableName where:where orderBy:orderBy desc:desc limit:0 offset:0 success:success];
}

+ (void)selectModelInDatabaseWithTableName:(NSString *)tableName where:(NSString *)where orderBy:(NSString *)orderBy desc:(BOOL)desc limit:(int)limit offset:(int)offset success:(void (^)(NSArray *resultArray, int resultCode))success {
    [[QLZ_DatabaseManager sharedManager] selectDatabaseWithTableName:[[self class] getTableName:tableName] where:where orderBy:orderBy desc:desc limit:limit offset:offset success:^(NSArray *resultArray, int resultCode) {
        if (success) {
            success([[self class] analysisDataWithResultArray:resultArray], resultCode);
        }
    }];
}

+ (void)selectModelCountInDataBaseWithSuccess:(void (^)(int count, int resultCode))success {
    [[self class] selectModelCountInDatabaseWithTableName:nil success:success];
}

+ (void)selectModelCountInDatabaseWithTableName:(NSString *)tableName success:(void (^)(int count, int resultCode))success {
    [[self class] selectModelCountInDatabaseWithTableName:tableName where:nil orderBy:nil desc:NO success:success];
}

+ (void)selectModelCountInDatabaseWithTableName:(NSString *)tableName where:(NSString *)where orderBy:(NSString *)orderBy desc:(BOOL)desc success:(void (^)(int count, int resultCode))success {
    [[self class] selectModelCountInDatabaseWithTableName:tableName where:where orderBy:orderBy desc:desc limit:0 offset:0 success:success];
}

+ (void)selectModelCountInDatabaseWithTableName:(NSString *)tableName where:(NSString *)where orderBy:(NSString *)orderBy desc:(BOOL)desc limit:(int)limit offset:(int)offset success:(void (^)(int count, int resultCode))success {
    [[QLZ_DatabaseManager sharedManager] selectDatabaseCountWithTableName:[[self class] getTableName:tableName] where:where orderBy:orderBy desc:desc limit:limit offset:offset success:^(NSArray *resultArray, int resultCode) {
        if (success) {
            if (resultArray.count > 0) {
                NSDictionary *dict = resultArray[0];
                success([dict[@"COUNT(*)"] intValue], resultCode);
            }
            else {
                success(0, resultCode);
            }
        }
    }];
}

#pragma mark AddDatabaseColumn
+ (void)addColumnWithColumnName:(NSString *)columnName {
    [[self class] addColumnWithColumnName:columnName tableName:nil];
}

+ (void)addColumnWithColumnName:(NSString *)columnName tableName:(NSString *)tableName {
    [[self class] addColumnWithColumnName:columnName tableName:tableName success:nil];
}

+ (void)addColumnWithColumnName:(NSString *)columnName tableName:(NSString *)tableName success:(void (^)(BOOL finished, int resultCode))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName]];
    [[QLZ_DatabaseManager sharedManager] addTableColumnWithTableName:[[self class] getTableName:tableName] columnName:columnName success:success];
}

+ (void)addColumnWithColumnName:(NSString *)columnName primaryKey:(NSString *)primaryKey {
    [[self class] addColumnWithColumnName:columnName tableName:nil primaryKey:primaryKey];
}

+ (void)addColumnWithColumnName:(NSString *)columnName tableName:(NSString *)tableName primaryKey:(NSString *)primaryKey {
    [[self class] addColumnWithColumnName:columnName tableName:tableName primaryKey:primaryKey success:nil];
}

+ (void)addColumnWithColumnName:(NSString *)columnName tableName:(NSString *)tableName primaryKey:(NSString *)primaryKey success:(void (^)(BOOL finished, int resultCode))success {
    [[self class] createDatabaseWithTableName:[[self class] getTableName:tableName] primaryKey:primaryKey];
    [[QLZ_DatabaseManager sharedManager] addTableColumnWithTableName:[[self class] getTableName:tableName] columnName:columnName success:success];
}

#pragma mark DatabaseColumnNames
+ (void)tableColumnNamesWithSuccess:(void (^)(NSArray *resultArray, int resultCode))success {
    [[self class] tableColumnNamesWithTableName:nil success:success];
}

+ (void)tableColumnNamesWithTableName:(NSString *)tableName success:(void (^)(NSArray *resultArray, int resultCode))success {
    [[QLZ_DatabaseManager sharedManager] tableColumNamesWithTableName:[[self class] getTableName:tableName] success:success];
}

+ (NSString *)getTableName:(NSString *)tableName {
    if (tableName.length == 0) {
        return kDefaultTableName;
    }
    return tableName;
}

+ (NSArray *)analysisDataWithResultArray:(NSArray *)resultArray {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:0];
    for (NSDictionary *dict in resultArray) {
        QLZ_DatabaseModel *model = [(QLZ_DatabaseModel *)[[self class] alloc] initWithDatabaseJSON:dict];
        [result addObject:model];
    }
    return result;
}

+ (void)setDatabaseLog:(BOOL)log {
    [[QLZ_DatabaseManager sharedManager] setDatabaseLog:log];
}

@end
