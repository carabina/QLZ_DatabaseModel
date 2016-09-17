//
//  QLZ_DatabaseManager.m
//  QLZ_Database
//
//  Created by 张庆龙 on 16/3/18.
//  Copyright © 2016年 张庆龙. All rights reserved.
//

#import "QLZ_DatabaseManager.h"
#import <sqlite3.h>
#import "QLZ_DatabaseModel.h"
#import "NSObject+QLZ_JSON.h"

#define DATABASE_FILEPATH @"qlz_database_filepath.sqlite"
#define DATABASE_MANAGER_TABLENAME @"qlz_database_manager_tablename"

@interface QLZ_DatabaseManager () {
    sqlite3 *contactDatabase;
    dispatch_queue_t databaseQueue;
}
@property (nonatomic, strong) NSString *databaseFilePath;
@property (nonatomic, assign) BOOL databaseLog;

@end

static QLZ_DatabaseManager *manager = nil;

@implementation QLZ_DatabaseManager

+ (QLZ_DatabaseManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[QLZ_DatabaseManager alloc] init];
    });
    return manager;
}

+ (NSString *)tablePath {
    NSArray *myPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return myPaths[0];
}

- (id)init {
    self = [super init];
    if (self) {
        databaseQueue = dispatch_queue_create("QLZ_DatabaseQueue", DISPATCH_QUEUE_SERIAL);
        self.databaseFilePath = [[[self class] tablePath] stringByAppendingPathComponent:DATABASE_FILEPATH];
    }
    return self;
}

- (int)openDatabase {
    int result = sqlite3_open(self.databaseFilePath.UTF8String, &contactDatabase);
    return result;
}

#pragma mark CreateDatabase
- (void)createTableWithTableName:(NSString *)tableName databaseModel:(QLZ_DatabaseModel *)model success:(void (^)(BOOL finished, int resultCode))success {
    [self createTableWithTableName:tableName databaseDictionary:[[model class] databaseDictionary] primaryKey:[[model class] primaryKey] success:success];
}

- (void)createTableWithTableName:(NSString *)tableName databaseDictionary:(NSDictionary *)databaseDictionary primaryKey:(NSString *)primaryKey success:(void (^)(BOOL finished, int resultCode))success {
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:0];
    if (primaryKey.length > 0) {
        [params addObject:[NSString stringWithFormat:@"%@ TEXT PRIMARY KEY", primaryKey]];
    }
    for (NSString *key in databaseDictionary.allKeys) {
        if ([key isEqualToString:primaryKey]) {
            continue;
        }
        [params addObject:[NSString stringWithFormat:@"%@ TEXT", key]];
    }
    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", tableName, [params componentsJoinedByString:@", "]];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:nil success:success];
    [self createDataDatabaseTable];
}

#pragma mark InsertDatabase
- (void)insertDatabaseWithTableName:(NSString *)tableName databaseModel:(QLZ_DatabaseModel *)model success:(void (^)(BOOL finished, int resultCode))success {
    NSDictionary *databaseDictionary = [[model class] databaseDictionary];
    [self checkDatabaseColumnHasChangedWithTableName:tableName databaseDictionary:databaseDictionary];
    NSMutableArray *valuesArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *keysArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *questionArray = [NSMutableArray arrayWithCapacity:0];
    for (NSString *key in databaseDictionary.allKeys) {
        [keysArray addObject:key];
        NSString *value = [[self class] transValueToString:[model valueForKeyPath:databaseDictionary[key]]];
        [valuesArray addObject:value];
        [questionArray addObject:@"?"];
    }
    NSString *sqlString = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, [keysArray componentsJoinedByString:@", "], [questionArray componentsJoinedByString:@", "]];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:valuesArray success:success];
}

- (void)insertDatabaseWithTableName:(NSString *)tableName databaseModels:(NSArray *)models success:(void (^)(BOOL finished, int resultCode))success {
    if (models.count == 0) {
        if (success) {
            success(YES, 0);
        }
        return;
    }
    QLZ_DatabaseModel *firstModel = models[0];
    NSDictionary *databaseDictionary = [[firstModel class] databaseDictionary];
    [self checkDatabaseColumnHasChangedWithTableName:tableName databaseDictionary:databaseDictionary];
    NSMutableArray *keysArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *questionArray = [NSMutableArray arrayWithCapacity:0];
    for (NSString *key in databaseDictionary.allKeys) {
        [keysArray addObject:key];
        [questionArray addObject:@"?"];
    }
    NSMutableArray *multiValuesArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *valuesArray = [NSMutableArray arrayWithCapacity:0];
    for (QLZ_DatabaseModel *model in models) {
        for (NSString *key in keysArray) {
            NSString *value = [[self class] transValueToString:[model valueForKeyPath:databaseDictionary[key]]];
            [valuesArray addObject:value];
        }
        [multiValuesArray addObject:valuesArray];
    }
    NSString *sqlString = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tableName, [keysArray componentsJoinedByString:@", "], [questionArray componentsJoinedByString:@", "]];
    [self excuteUpdateDatabaseWithSqlString:sqlString mutiValues:multiValuesArray success:success];
}

#pragma mark ReplaceDatabase
- (void)replaceDatabaseWithTableName:(NSString *)tableName databaseModel:(QLZ_DatabaseModel *)model success:(void (^)(BOOL finished, int resultCode))success {
    NSDictionary *databaseDictionary = [[model class] databaseDictionary];
    [self checkDatabaseColumnHasChangedWithTableName:tableName databaseDictionary:databaseDictionary];
    NSMutableArray *valuesArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *keysArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *questionArray = [NSMutableArray arrayWithCapacity:0];
    for (NSString *key in databaseDictionary.allKeys) {
        [keysArray addObject:key];
        NSString *value = [[self class] transValueToString:[model valueForKeyPath:databaseDictionary[key]]];
        [valuesArray addObject:value];
        [questionArray addObject:@"?"];
    }
    NSString *sqlString = [NSString stringWithFormat:@"REPLACE INTO %@ (%@) VALUES (%@)", tableName, [keysArray componentsJoinedByString:@", "], [questionArray componentsJoinedByString:@", "]];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:valuesArray success:success];
}

- (void)replaceDatabaseWithTableName:(NSString *)tableName databaseModels:(NSArray *)models success:(void (^)(BOOL finished, int resultCode))success {
    if (models.count == 0) {
        if (success) {
            success(YES, 0);
        }
        return;
    }
    QLZ_DatabaseModel *firstModel = models[0];
    NSDictionary *databaseDictionary = [[firstModel class] databaseDictionary];
    [self checkDatabaseColumnHasChangedWithTableName:tableName databaseDictionary:databaseDictionary];
    NSMutableArray *keysArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *questionArray = [NSMutableArray arrayWithCapacity:0];
    for (NSString *key in databaseDictionary.allKeys) {
        [keysArray addObject:key];
        [questionArray addObject:@"?"];
    }
    NSMutableArray *multiValuesArray = [NSMutableArray arrayWithCapacity:0];
    for (QLZ_DatabaseModel *model in models) {
        NSMutableArray *valuesArray = [NSMutableArray arrayWithCapacity:0];
        for (NSString *key in keysArray) {
            NSString *value = [[self class] transValueToString:[model valueForKeyPath:databaseDictionary[key]]];
            [valuesArray addObject:value];
        }
        [multiValuesArray addObject:valuesArray];
    }
    NSString *sqlString = [NSString stringWithFormat:@"REPLACE INTO %@ (%@) VALUES (%@)", tableName, [keysArray componentsJoinedByString:@", "], [questionArray componentsJoinedByString:@", "]];
    [self excuteUpdateDatabaseWithSqlString:sqlString mutiValues:multiValuesArray success:success];
}

#pragma mark UpdateDatabase
- (void)updateDatabaseWithTableName:(NSString *)tableName databaseModel:(QLZ_DatabaseModel *)model sets:(NSArray *)sets where:(NSString *)where success:(void (^)(BOOL finished, int resultCode))success {
    NSDictionary *databaseDictionary = [[model class] databaseDictionary];
    [self checkDatabaseColumnHasChangedWithTableName:tableName databaseDictionary:databaseDictionary];
    NSMutableArray *setsArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *valuesArray = [NSMutableArray arrayWithCapacity:0];
    for (NSString *set in sets) {
        [setsArray addObject:[NSString stringWithFormat:@"%@ = ?", set]];
        NSString *value = [[self class] transValueToString:[model valueForKeyPath:databaseDictionary[set]]];
        [valuesArray addObject:value];
    }
    NSString *setsString = sets.count > 0 ? [NSString stringWithFormat:@"SET %@", [setsArray componentsJoinedByString:@", "]] : @"";
    if (where.length == 0) {
        where = [NSString stringWithFormat:@"%@ = '%@'", [[model class] primaryKey], [[self class] transValueToString:[model valueForKeyPath:databaseDictionary[[[model class] primaryKey]]]]];
    }
    NSString *whereString = where.length > 0 ? [NSString stringWithFormat:@"WHERE %@", where] : @"";
    NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ %@ %@", tableName, setsString, whereString];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:valuesArray success:success];
}

- (void)updateDatabaseWithTableName:(NSString *)tableName databaseDictionary:(NSDictionary *)databaseDictionary set:(NSString *)set where:(NSString *)where success:(void (^)(BOOL finished, int resultCode))success {
    [self checkDatabaseColumnHasChangedWithTableName:tableName databaseDictionary:databaseDictionary];
    NSString *setsString = set.length > 0 ? [NSString stringWithFormat:@"SET %@", set] : @"";
    NSString *whereString = where.length > 0 ? [NSString stringWithFormat:@"WHERE %@", where] : @"";
    NSString *sqlString = [NSString stringWithFormat:@"UPDATE %@ %@ %@", tableName, setsString, whereString];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:nil success:success];
}

#pragma mark DeleteDatabase
- (void)deleteFromTableName:(NSString *)tableName model:(QLZ_DatabaseModel *)model primaryKey:(NSString *)primaryKey success:(void (^)(BOOL finished, int resultCode))success {
    if (primaryKey.length == 0) {
        primaryKey = [[model class] primaryKey];
    }
    NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", tableName, primaryKey];
    NSString *value = [[self class] transValueToString:[model valueForKeyPath:[[model class] databaseDictionary][primaryKey]]];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:@[value] success:success];
}

- (void)deleteFromTableName:(NSString *)tableName where:(NSString *)where success:(void (^)(BOOL finished, int resultCode))success {
    NSString *whereString = where.length > 0 ? [NSString stringWithFormat:@"WHERE %@", where] : @"";
    NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM %@ %@", tableName, whereString];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:nil success:success];
}

#pragma mark DeleteWholeDatabase
- (void)deleteWholeTableWithTableName:(NSString *)tableName success:(void (^)(BOOL finished, int resultCode))success {
    NSString *sqlString = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:nil success:success];
    [self deleteDataDatabaseWithTableName:tableName];
}

#pragma mark SelectDatabase
- (void)selectDatabaseWithTableName:(NSString *)tableName where:(NSString *)where orderBy:(NSString *)orderBy desc:(BOOL)desc limit:(int)limit offset:(int)offset success:(void (^)(NSArray *resultArray, int resultCode))success {
    NSString *whereString = where.length > 0 ? [NSString stringWithFormat:@"WHERE %@", where] : @"";
    NSString *orderByString = orderBy.length > 0 ? [NSString stringWithFormat:@"ORDER BY %@%@", orderBy, (desc ? @" DESC" : @"")] : @"";
    NSString *limitString = limit > 0 ? [NSString stringWithFormat:@"LIMIT %d", limit] : @"";
    NSString *offsetString = offset > 0 ? [NSString stringWithFormat:@"OFFSET %d", offset] : @"";
    NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@ %@ %@ %@ %@", tableName, whereString, orderByString, limitString, offsetString];
    [self excuteQueueDatabaseWithSqlString:sqlString values:nil success:success];
}

- (void)selectDatabaseCountWithTableName:(NSString *)tableName where:(NSString *)where orderBy:(NSString *)orderBy desc:(BOOL)desc limit:(int)limit offset:(int)offset success:(void (^)(NSArray *resultArray, int resultCode))success {
    NSString *whereString = where.length > 0 ? [NSString stringWithFormat:@"WHERE %@", where] : @"";
    NSString *orderByString = orderBy.length > 0 ? [NSString stringWithFormat:@"ORDER BY %@%@", orderBy, (desc ? @" DESC" : @"")] : @"";
    NSString *limitString = limit > 0 ? [NSString stringWithFormat:@"LIMIT %d", limit] : @"";
    NSString *offsetString = offset > 0 ? [NSString stringWithFormat:@"OFFSET %d", offset] : @"";
    NSString *sqlString = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ %@ %@ %@ %@", tableName, whereString, orderByString, limitString, offsetString];
    [self excuteQueueDatabaseWithSqlString:sqlString values:nil success:success];
}

#pragma mark AddDatabaseColumn
- (void)addTableColumnWithTableName:(NSString *)tableName columnName:(NSString *)columnName success:(void (^)(BOOL finished, int resultCode))success {
    NSString *sqlString = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ TEXT", tableName, columnName];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:nil success:success];
}

#pragma mark DatabaseColumnNames
- (void)tableColumNamesWithTableName:(NSString *)tableName success:(void (^)(NSArray *resultArray, int resultCode))success {
    [self selectDataDatabaseWithTableName:tableName success:success];
}

#pragma mark DataDatabase
- (void)createDataDatabaseTable {
    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (TABLENAME TEXT PRIMARY KEY, COLUMNSNAME TEXT)", DATABASE_MANAGER_TABLENAME];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:nil success:nil];
}

- (void)replaceDataDatabaseWithTableName:(NSString *)tableName columnsName:(NSArray *)columnsArray {
    NSString *sqlString = [NSString stringWithFormat:@"REPLACE INTO %@ (TABLENAME, COLUMNSNAME) VALUES (?, ?)", DATABASE_MANAGER_TABLENAME];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:@[tableName, [columnsArray JSONString]] success:nil];
}

- (void)selectDataDatabaseWithTableName:(NSString *)tableName success:(void (^)(NSArray *resultArray, int resultCode))success {
    NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE TABLENAME = ?", DATABASE_MANAGER_TABLENAME];
    [self excuteQueueDatabaseWithSqlString:sqlString values:@[tableName] success:^(NSArray *resultArray, int resultCode) {
        NSArray *columns = nil;
        if (resultArray.count > 0) {
            NSDictionary *dict = resultArray[0];
            columns = [dict[@"COLUMNSNAME"] JSONValue];
        }
        if (success) {
            success(columns, resultCode);
        }
    }];
}

- (void)deleteDataDatabaseWithTableName:(NSString *)tableName {
    NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM %@ WHERE TABLENAME = ?", DATABASE_MANAGER_TABLENAME];
    [self excuteUpdateDatabaseWithSqlString:sqlString values:@[tableName] success:nil];
}

#pragma mark PublicMethods
- (void)excuteUpdateDatabaseWithSqlString:(NSString *)sqlString values:(NSArray *)values success:(void (^)(BOOL finished, int resultCode))success {
    sqlString = [sqlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    dispatch_sync(databaseQueue, ^{
        if (self.databaseLog) {
            NSLog(@"%@", sqlString);
        }
        int result = [self openDatabase];
        if (result == SQLITE_OK) {
            sqlite3_stmt *statement;
            result = sqlite3_prepare_v2(contactDatabase, sqlString.UTF8String, -1, &statement, NULL);
            if (result == SQLITE_OK) {
                for (int i = 0; i < values.count; i++) {
                    NSString *value = values[i];
                    if (value.length > 0) {
                        sqlite3_bind_text(statement, i + 1, value.UTF8String, -1, NULL);
                    }
                    else {
                        sqlite3_bind_null(statement, i + 1);
                    }
                }
                result = sqlite3_step(statement);
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(contactDatabase);
        if (success) {
            success((result == SQLITE_DONE), result);
        }
    });
}

//批量写入数据库
- (void)excuteUpdateDatabaseWithSqlString:(NSString *)sqlString mutiValues:(NSArray *)mutiValues success:(void (^)(BOOL finished, int resultCode))success {
    sqlString = [sqlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    dispatch_sync(databaseQueue, ^{
        if (self.databaseLog) {
            NSLog(@"%@", sqlString);
        }
        int result = [self openDatabase];
        if (result == SQLITE_OK) {
            sqlite3_stmt *statement;
            result = sqlite3_prepare_v2(contactDatabase, sqlString.UTF8String, -1, &statement, NULL);
            if (result == SQLITE_OK) {
                for (int i = 0; i < mutiValues.count; i++) {
                    NSArray *values = mutiValues[i];
                    for (int j = 0; j < values.count; j++) {
                        NSString *value = values[j];
                        if (value.length > 0) {
                            sqlite3_bind_text(statement, j + 1, value.UTF8String, -1, NULL);
                        }
                        else {
                            sqlite3_bind_null(statement, j + 1);
                        }
                    }
                    if (sqlite3_step(statement) != SQLITE_DONE) {
                        NSLog(@"%@", [[NSString alloc] initWithUTF8String:sqlite3_errmsg(contactDatabase)]);
                        continue;
                    }
                    sqlite3_reset(statement);
                }
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(contactDatabase);
        if (success) {
            success((result == SQLITE_OK), result);
        }
    });
}

- (void)excuteQueueDatabaseWithSqlString:(NSString *)sqlString values:(NSArray *)values success:(void (^)(NSArray *resultArray, int resultCode))success {
    sqlString = [sqlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    dispatch_sync(databaseQueue, ^{
        if (self.databaseLog) {
            NSLog(@"%@", sqlString);
        }
        NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:0];
        int result = [self openDatabase];
        if (result == SQLITE_OK) {
            sqlite3_stmt *statement;
            result = sqlite3_prepare_v2(contactDatabase, sqlString.UTF8String, -1, &statement, NULL);
            if (result == SQLITE_OK) {
                for (int i = 0; i < values.count; i++) {
                    NSString *value = values[i];
                    if (value.length > 0) {
                        sqlite3_bind_text(statement, i + 1, value.UTF8String, -1, NULL);
                    }
                    else {
                        sqlite3_bind_null(statement, i + 1);
                    }
                }
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
                    int count = sqlite3_column_count(statement);
                    for (int i = 0; i < count; i++) {
                        const char *text = (const char *)sqlite3_column_text(statement, i);
                        if (text) {
                            resultDictionary[[NSString stringWithUTF8String:sqlite3_column_name(statement, i)]] = [NSString stringWithUTF8String:text];
                        }
                    }
                    [resultArray addObject:resultDictionary];
                }
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(contactDatabase);
        if (success) {
            success(resultArray, result);
        }
    });
}

- (void)checkDatabaseColumnHasChangedWithTableName:(NSString *)tableName databaseDictionary:(NSDictionary *)databaseDictionary {
    NSMutableArray *changeArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableSet *modelSet = [NSMutableSet setWithArray:databaseDictionary.allKeys];
    NSMutableSet *resultSet = [NSMutableSet setWithCapacity:0];
    [self selectDataDatabaseWithTableName:tableName success:^(NSArray *resultArray, int resultCode) {
        [resultSet addObjectsFromArray:resultArray];
        [modelSet minusSet:resultSet];
        if (modelSet.count > 0 && resultSet.count > 0) {
            for (NSString *model in modelSet) {
                [changeArray addObject:model];
            }
        }
    }];
    if (changeArray.count > 0) {
        for (NSString *columnName in changeArray) {
            [self addTableColumnWithTableName:tableName columnName:columnName success:nil];
        }
        [self replaceDataDatabaseWithTableName:tableName columnsName:databaseDictionary.allKeys];
    }
    else if (resultSet.count == 0) {
        [self replaceDataDatabaseWithTableName:tableName columnsName:databaseDictionary.allKeys];
    }
}

#pragma mark BaseMethod
+ (NSString *)transValueToString:(id)value {
    NSString *valueString;
    if ([value isKindOfClass:[NSString class]]) {
        valueString = value;
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        valueString = ((NSNumber *)value).stringValue;
    }
    else if ([value isKindOfClass:[QLZ_JSONModel class]]) {
        valueString = [[(QLZ_JSONModel *)value transToDictionary] JSONString];
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
        for (id object in value) {
            if ([object isKindOfClass:[QLZ_JSONModel class]]) {
                [array addObject:[[(QLZ_JSONModel *)object transToDictionary] JSONString]];
            }
            else {
                [array addObject:object];
            }
        }
        valueString = [array JSONString];
    }
    else if (![value isKindOfClass:[NSString class]]) {
        valueString = [value JSONString];
    }
    if (!valueString) {
        valueString = @"";
    }
    return valueString;
}

- (void)setDatabaseLog:(BOOL)log {
    _databaseLog = log;
}

@end
