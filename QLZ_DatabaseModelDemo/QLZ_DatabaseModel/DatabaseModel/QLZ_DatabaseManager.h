//
//  QLZ_DatabaseManager.h
//  QLZ_Database
//
//  Created by 张庆龙 on 16/3/18.
//  Copyright © 2016年 张庆龙. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QLZ_DatabaseModel;

@interface QLZ_DatabaseManager : NSObject

+ (QLZ_DatabaseManager *)sharedManager;
+ (NSString *)tablePath;

#pragma mark CreateDatabase
/**
 *	@brief	创建数据库
 *              默认在更改数据库时会查找是否存在该数据库，如果不存在则会默认创建。
 *
 *	@param tableName 表明
 *               model 操作数据库的对象
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)createTableWithTableName:(NSString *)tableName databaseModel:(QLZ_DatabaseModel *)model success:(void (^)(BOOL finished, int resultCode))success;

/**
 *	@brief	创建数据库
 *              默认在更改数据库时会查找是否存在该数据库，如果不存在则会默认创建。
 *
 *	@param tableName 表明
 *               databaseDictionary 数据库对应的Dictionary
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)createTableWithTableName:(NSString *)tableName databaseDictionary:(NSDictionary *)databaseDictionary primaryKey:(NSString *)primaryKey success:(void (^)(BOOL finished, int resultCode))success;

#pragma mark InsertDatabase
/**
 *	@brief	把当前对象插入数据库，调用insert语句
 *
 *	@param tableName 表明
 *               model 操作数据库的对象
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)insertDatabaseWithTableName:(NSString *)tableName databaseModel:(QLZ_DatabaseModel *)model success:(void (^)(BOOL finished, int resultCode))success;

/**
 *	@brief	批量插入数据库，调用insert语句
 *
 *	@param tableName 表明
 *               models 要插入的数据数组，数组里面必须是同一种数据类型
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)insertDatabaseWithTableName:(NSString *)tableName databaseModels:(NSArray *)models success:(void (^)(BOOL finished, int resultCode))success;

#pragma mark ReplaceDatabase
/**
 *	@brief	把当前对象插入数据库，调用replace语句
 *
 *	@param tableName 表明
 *               model 操作数据库的对象
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)replaceDatabaseWithTableName:(NSString *)tableName databaseModel:(QLZ_DatabaseModel *)model success:(void (^)(BOOL finished, int resultCode))success;

/**
 *	@brief	批量插入数据库，调用replace语句
 *
 *	@param tableName 表明
 *               models 要插入的数据数组，数组里面必须是同一种数据类型
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)replaceDatabaseWithTableName:(NSString *)tableName databaseModels:(NSArray *)models success:(void (^)(BOOL finished, int resultCode))success;

#pragma mark UpdateDatabase
/**
 *	@brief	以当前对象更新数据库操作，调用update语句
 *
 *	@param tableName 表明
 *               model 操作数据库的对象
 *               sets 要更改的数据参数名的数组，不需要添加参数值，会以当前的参数值赋值
 *               where 要更改的条件，如果为nil或者为空，则默认按照primaryKey查找
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)updateDatabaseWithTableName:(NSString *)tableName databaseModel:(QLZ_DatabaseModel *)model sets:(NSArray *)sets where:(NSString *)where success:(void (^)(BOOL finished, int resultCode))success;

/**
 *	@brief	以当前对象更新数据库操作，调用update语句
 *
 *	@param tableName 表明
 *               databaseDictionary 数据库对应的Dictionary
 *               sets 要更改的语句
 *               where 要更改的条件，如果为nil或者为空，则默认按照primaryKey查找
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)updateDatabaseWithTableName:(NSString *)tableName databaseDictionary:(NSDictionary *)databaseDictionary set:(NSString *)set where:(NSString *)where success:(void (^)(BOOL finished, int resultCode))success;

#pragma mark DeleteDatabase
/**
 *	@brief	从数据库中删除当前对象，调用delete语句
 *
 *	@param tableName 表明
 *               model 操作数据库的对象
 *               primaryKey 主键，如果为空取类方法的primaryKey;
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)deleteFromTableName:(NSString *)tableName model:(QLZ_DatabaseModel *)model primaryKey:(NSString *)primaryKey success:(void (^)(BOOL finished, int resultCode))success;

/**
 *	@brief	从数据库中删除当前对象，调用delete语句
 *
 *	@param tableName 表明
 *               where 要更改的条件，如果为nil或者为空，则默认按照primaryKey查找
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)deleteFromTableName:(NSString *)tableName where:(NSString *)where success:(void (^)(BOOL finished, int resultCode))success;

#pragma mark DeleteWholeDatabase
/**
 *	@brief	删除整个表
 *
 *	@param tableName 表明
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)deleteWholeTableWithTableName:(NSString *)tableName success:(void (^)(BOOL finished, int resultCode))success;

#pragma mark SelectDatabase
/**
 *	@brief	 查询数据库
 *
 *	@param tableName 表明
 *               where 要更改的条件，如果为nil或者为空，则查找全部
 *               orderBy 排序的字段
 *               desc 是否倒序排列
 *               limit 最多返回多少条
 *               offset 从第几条开始返回
 *               success 返回调取的block，resultArray:查找结果，resultCode:返回数据库操作的code
 */
- (void)selectDatabaseWithTableName:(NSString *)tableName where:(NSString *)where orderBy:(NSString *)orderBy desc:(BOOL)desc limit:(int)limit offset:(int)offset success:(void (^)(NSArray *resultArray, int resultCode))success;

- (void)selectDatabaseCountWithTableName:(NSString *)tableName where:(NSString *)where orderBy:(NSString *)orderBy desc:(BOOL)desc limit:(int)limit offset:(int)offset success:(void (^)(NSArray *resultArray, int resultCode))success;

#pragma mark AddDatabaseColumn
/**
 *	@brief	在表中增加一个列
 *
 *	@param tableName 表明
 *               columnName 要增加的列名
 *               success 返回调取的block，finished:是否成功，resultCode:返回数据库操作的code
 */
- (void)addTableColumnWithTableName:(NSString *)tableName columnName:(NSString *)columName success:(void (^)(BOOL finished, int resultCode))success;

#pragma mark DatabaseColumnName
/**
 *	@brief	 查找一个表中所有的列名
 *
 *	@param tableName 表明
 *               columnName 要增加的列名
 *               success 返回调取的block，resultArray:查找结果，resultCode:返回数据库操作的code
 */
- (void)tableColumNamesWithTableName:(NSString *)tableName success:(void (^)(NSArray *resultArray, int resultCode))success;

#pragma mark BaseMethod
/**
 *	@brief	 把value转成NSString类型
 *
 *	@param value
 *
 * @return value对应的字符串
 */
+ (NSString *)transValueToString:(id)value;

- (void)setDatabaseLog:(BOOL)log;

@end
