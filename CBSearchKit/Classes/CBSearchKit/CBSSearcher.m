//
//  CBSSearcher.m
//  CBSearchKit
//
//  Created by C. Bess on 2/26/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import "CBSSearcher.h"
#import "CBSIndexer.h"
#import <FMDB/FMDatabaseQueue.h>
#import <FMDB/FMDatabase.h>
#import <FMDB/FMResultSet.h>

@interface CBSSearcher ()

@property (nonatomic, strong) CBSIndexer *indexer;
@property (nonatomic, copy) NSString *databasePath;
@property (nonatomic, copy) NSString *indexName;
@property (nonatomic, copy) CBSSearcherItemsEnumerationHandler enumerationHandler;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, copy) CBSSearcherItemFactoryHandler itemFactoryBlock;

@end

@implementation CBSSearcher

- (instancetype)initWithIndexer:(CBSIndexer *)indexer {
    self = [self initWithDatabaseAtPath:[indexer databasePath] indexName:[indexer indexName]];
    if (self) {
        _indexer = indexer;
        _databaseQueue = [indexer databaseQueue];
    }
    return self;
}

- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath indexName:(NSString *)indexName {
    self = [self init];
    if (self) {
        if (!dbPath.length) {
            dbPath = @":memory:";
        }
        
        _databasePath = [dbPath copy];
        _indexName = [indexName copy];
    }
    return self;
}

- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath {
    return [self initWithDatabaseAtPath:dbPath indexName:kCBSDefaultIndexName];
}

- (instancetype)initWithDatabaseNamed:(NSString *)dbName indexName:(NSString *)indexName {
    return [self initWithDatabaseAtPath:[CBSIndexer stringWithDatabasePathWithPathComponent:dbName] indexName:indexName];
}

- (instancetype)initWithDatabaseNamed:(NSString *)dbName {
    return [self initWithDatabaseNamed:dbName indexName:kCBSDefaultIndexName];
}

- (id)init {
    self = [super init];
    if (self) {
        _searchQueue = dispatch_queue_create("com.cbess.cbssearcher", 0);
    }
    return self;
}

- (void)setItemFactoryHandler:(CBSSearcherItemFactoryHandler)handler {
    self.itemFactoryBlock = handler;
}

#pragma mark - Misc

- (void)createDatabaseQueueIfNeeded {
    if (self.databaseQueue == nil) {
        self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
    }
}

#pragma mark - Searcher

- (void)itemsWithText:(NSString *)textContents itemType:(CBSIndexItemType)itemType offset:(NSInteger)offset limit:(NSInteger)limit completionHandler:(CBSSearcherItemsCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(self.searchQueue, ^{
        __block NSError *error = nil;
        NSMutableArray *resultItems = [NSMutableArray arrayWithCapacity:MAX(limit, 10)];
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
            params[@"contents"] = textContents;
            
            NSMutableString *query = [[NSMutableString alloc] initWithFormat:
                                      // change 'contents' column, change in 'CBSIndexer.m'
                                      @"SELECT * FROM %@ WHERE contents MATCH :contents ",
                                      weakSelf.indexName];
            
            // use the index item type if not ignored
            if (itemType != CBSIndexItemTypeIgnore) {
                params[@"itemtype"] = @(itemType);
                [query appendString:@" AND item_type = :itemtype "];
            }
            
            // add limit info
            if (limit > 0) {
                [query appendFormat:@" LIMIT %lu ", limit];
            }
            
            // add offset info
            if (offset > 0) {
                [query appendFormat:@" OFFSET %lu ", offset];
            }
            
            FMResultSet *result = [db executeQuery:query withParameterDictionary:params];
            while ([result next]) {
                CBSIndexDocument *document = [CBSIndexDocument new];
                document.indexTextContents = result[@"contents"];
                document.indexItemIdentifier = result[@"item_id"];
                
                if (![result columnIsNull:@"item_meta"]) {
                    NSData *metaData = result[@"item_meta"];
                    document.indexMeta = [NSJSONSerialization JSONObjectWithData:metaData options:0 error:&error];
                }
                
                if (error) {
                    break;
                }
                
                // build custom object from the item factory, if factory handler available
                id<CBSIndexItem> indexItem = document;
                if (weakSelf.itemFactoryBlock) {
                    indexItem = weakSelf.itemFactoryBlock(document);
                }
                
                // use the enumerator, if provided
                if (weakSelf.enumerationHandler) {
                    BOOL stop = NO;
                    weakSelf.enumerationHandler(indexItem, &stop);
                    
                    if (stop) {
                        break;
                    }
                } else {
                    [resultItems addObject:indexItem];
                }
            }
            [result close];
            
            if ([db hadError]) {
                error = [db lastError];
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(resultItems, error);
            }
        });
    });
}

- (void)itemsWithText:(NSString *)textContents completionHandler:(CBSSearcherItemsCompletionHandler)completionHandler {
    [self itemsWithText:textContents itemType:CBSIndexItemTypeIgnore completionHandler:completionHandler];
}

- (void)itemsWithText:(NSString *)textContents itemType:(CBSIndexItemType)itemType completionHandler:(CBSSearcherItemsCompletionHandler)completionHandler {
    [self itemsWithText:textContents itemType:itemType offset:0 limit:0 completionHandler:completionHandler];
}

- (void)enumerateItemsWithText:(NSString *)textContents enumerationHandler:(CBSSearcherItemsEnumerationHandler)enumerationHandler {
    [self enumerateItemsWithText:textContents itemType:CBSIndexItemTypeIgnore enumerationHandler:enumerationHandler];
}

- (void)enumerateItemsWithText:(NSString *)textContents itemType:(CBSIndexItemType)itemType enumerationHandler:(CBSSearcherItemsEnumerationHandler)enumerationHandler {
    self.enumerationHandler = enumerationHandler;
    [self itemsWithText:textContents itemType:itemType offset:0 limit:-1 completionHandler:nil];
}

@end
