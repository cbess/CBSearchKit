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

typedef void(^CBSIndexerReindexCompletionHandler)(NSUInteger docCount, NSError *error);
typedef void(^CBSIndexerItemsCompletionHandler)(NSArray *indexItems, NSError *error);


@interface CBSIndexer : NSObject

/**
 Set the internal FTS engine used.
 @param version Use kCBSFTSEngineVersion* constant.
 @discussion Defaults to kCBSFTSEngineVersion3.
 */
+ (void)setFTSEngineVersion:(NSString *)version;

- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath;
- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath indexName:(NSString *)indexName;

#pragma mark - Indexing

- (id<CBSIndexItem>)addTextContents:(NSString *)contents completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler;
- (void)addItem:(id<CBSIndexItem>)item completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler;
- (void)addItems:(NSArray *)items completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler;

- (void)removeItemWithID:(CBSIndexItemIdentifier)identifier;
- (void)removeItem:(id<CBSIndexItem>)item;
- (void)removeItems:(NSArray *)items;

/**
 Reindexes the specified items.
 
 @param completionHandler The completion block for this operation. Runs on main thread.
 @discussion Asynchronous operation.
 */
- (void)reindexWithItems:(NSArray *)items completionHandler:(CBSIndexerReindexCompletionHandler)completionHandler;

/**
 Reindexes the entire database.
 
 @discussion Rebuilds the indexes.
 */
- (void)reindexWithCompletionHandler:(CBSIndexerReindexCompletionHandler)completionHandler;

/**
 Optimizes the index database.
 
 @param completionHandler The completion block for the operation. Runs on main thread.
 @discussion Asynchronous operation.
 @see http://www.sqlite.org/fts3.html#*fts4optcmd
 */
- (void)optimizeIndexWithCompletionHandler:(dispatch_block_t)completionHandler;

/**
 The path to the index database.
 */
- (NSString *)databasePath;

/**
 The name of the index in the database.
 @discussion This is the table name.
 */
- (NSString *)indexName;

@end
