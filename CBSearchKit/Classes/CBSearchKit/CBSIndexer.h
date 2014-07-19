//
//  CBSIndexer.h
//  CBSearchKit
//
//  Created by C. Bess on 2/23/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBSIndexDocument.h"

extern NSString * const kCBSDefaultIndexName;
extern NSString * const kCBSFTSEngineVersion3; // fts3
extern NSString * const kCBSFTSEngineVersion4; // fts4

typedef void(^CBSIndexerReindexCompletionHandler)(NSUInteger itemCount, NSError *error);
typedef void(^CBSIndexerItemsCompletionHandler)(NSArray *indexItems, NSError *error);

@class FMDatabaseQueue;

@interface CBSIndexer : NSObject

/**
 Set the internal FTS engine used.
 
 @param version Use kCBSFTSEngineVersion* constant.
 @discussion Defaults to kCBSFTSEngineVersion3.
 */
+ (void)setFTSEngineVersion:(NSString *)version;

/**
 The path to the index database by appending the specified path component (usually the file name).
 
 @param pathComponent The path component to append. If nil or empty, then an empty path will be returned.
 @discussion The path will be in the caches directory.
 */
+ (NSString *)stringWithDatabasePathWithPathComponent:(NSString *)pathComponent;

#pragma mark - Init

/**
 Initializes the receiver using the specified database name.
 
 @param dbName The name of the database to be opened or created in the cache directory. If empty, then an in-memory
 database is used.
 */
- (instancetype)initWithDatabaseNamed:(NSString *)dbName;

/**
 Initializes the receiver using the specified database name.
 
 @param dbName The name of the database file to be opened or created in the cache directory. If empty, then an in-memory
 database is used.
 @param indexName The name of the index within the database. If nil or empty, then the default index name is used (kCBSDefaultIndexName).
 */
- (instancetype)initWithDatabaseNamed:(NSString *)dbName indexName:(NSString *)indexName;

/**
 Initializes the receiver using the specified database path.
 
 @param dbName The name of the database to be opened or created in the cache directory. If empty, then an in-memory
 database is used.
 @param indexName The name of the index within the database. If nil or empty, then the default index name is used.
 */
- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath indexName:(NSString *)indexName;

#pragma mark - Indexing

- (id<CBSIndexItem>)addTextContents:(NSString *)contents itemType:(CBSIndexItemType)itemType completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler;
- (id<CBSIndexItem>)addTextContents:(NSString *)contents completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler;
- (void)addItem:(id<CBSIndexItem>)item completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler;
- (void)addItems:(NSArray *)items completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler;

- (void)removeItemWithID:(CBSIndexItemIdentifier)identifier;
- (void)removeItem:(id<CBSIndexItem>)item;
- (void)removeItems:(NSArray *)items completionHandler:(dispatch_block_t)completionHandler;

/**
 Reindexes the entire database.
 
 @param completionHandler The completion block for this operation. Runs on the main thread.
 @discussion Rebuilds the indexes. Asynchronous operation.
 */
- (void)reindexWithCompletionHandler:(CBSIndexerReindexCompletionHandler)completionHandler;

/**
 Optimizes the index database.
 
 @param completionHandler The completion block for the operation. Runs on main thread.
 @discussion Asynchronous operation.
 @see http://www.sqlite.org/fts3.html#*fts4optcmd
 */
- (void)optimizeIndexWithCompletionHandler:(dispatch_block_t)completionHandler;

#pragma mark - Misc

/**
 The path to the index database.
 */
- (NSString *)databasePath;

/**
 The name of the index in the database.
 
 @discussion This is the table name.
 */
- (NSString *)indexName;

/**
 The total number of index items in the database.
 
 @discussion Performs a COUNT query.
 */
- (NSUInteger)indexCount;

/**
 Used mostly for unit test or custom/special queries.
 
 @discussion The db queue used internally for prebuilt queries.
 */
- (FMDatabaseQueue *)databaseQueue;

@end
