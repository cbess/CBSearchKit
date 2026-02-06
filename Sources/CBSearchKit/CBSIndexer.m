//
//  CBSIndexer.m
//  CBSearchKit
//
//  Created by C. Bess on 2/23/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

@import FMDB;

#import "CBSIndexer.h"
#import "CBSMacros.h"

NSString * const kCBSDefaultIndexName = @"cbs_fts";

@interface CBSIndexer () {
    BOOL _supportsRanking;
}

@property (nonatomic, copy) NSString *databasePath;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, copy) NSString *indexName;
@property (nonatomic, assign) BOOL databaseCreated;

@end

@implementation CBSIndexer

+ (NSString *)stringWithDatabasePathWithPathComponent:(NSString *)pathComp {
    if (!pathComp.length) {
        return [NSString string];
    }
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:pathComp];
}

+ (id)indexer {
    return [[self alloc] initWithDatabaseNamed:nil];
}

#pragma mark - Init

- (instancetype)initWithDatabaseNamed:(NSString *)dbName {
    return [self initWithDatabaseNamed:dbName indexName:nil];
}

- (instancetype)initWithDatabaseNamed:(NSString *)dbName indexName:(NSString *)indexName {
    NSString *dbPath = @":memory:";
    if (dbName.length) {
        dbPath = [[self class] stringWithDatabasePathWithPathComponent:dbName];
    }
    
    return [self initWithDatabaseAtPath:dbPath indexName:indexName];
}

- (instancetype)initWithDatabaseAtPath:(NSString *)dbPath indexName:(NSString *)indexName {
    self = [self init];
    if (self) {
        _databasePath = [dbPath copy];
        _indexName = [indexName copy];
        
        if (!_databasePath.length) {
            _databasePath = @":memory:";
        }
        
        if (!_indexName.length) {
            _indexName = kCBSDefaultIndexName;
        }
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        _indexQueue = dispatch_queue_create("com.cbsindexer", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Misc

- (void)createDatabaseQueueIfNeeded {
    NSAssert(self.indexName, @"No index name.");
    NSAssert(self.databasePath, @"No database path.");
    
    // no queue or the db path is different
    if (self.databaseQueue == nil || ![self.databasePath isEqualToString:self.databaseQueue.path]) {
        self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
    }
}

- (void)createFTSIfNeeded {
    if (self.databaseCreated) {
        return;
    }
    
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        // FTS table
        NSString *query = [NSString stringWithFormat:
                           @"CREATE VIRTUAL TABLE IF NOT EXISTS %@ USING fts5 (contents, item_meta UNINDEXED, priority UNINDEXED)",
                           self.indexName];
        BOOL success = [db executeUpdate:query];
        
        if (!success) {
            CBSError([db lastError]);
            *rollback = YES;
            return;
        }
        
        // Meta table
        NSString *metaTableName = [self.indexName stringByAppendingString:@"_meta"];
        NSString *metaQuery = [NSString stringWithFormat:
                               @"CREATE TABLE IF NOT EXISTS %@ (rowid INTEGER PRIMARY KEY, item_id TEXT NOT NULL UNIQUE, item_type INTEGER NOT NULL)",
                               metaTableName];
        success = [db executeUpdate:metaQuery];
        
        if (!success) {
            CBSError([db lastError]);
            *rollback = YES;
            return;
        }
        
        // Indices
        [db executeUpdate:[NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS %@_item_type_idx ON %@ (item_type)", metaTableName, metaTableName]];
        
        self.databaseCreated = success;
    }];
}

#pragma mark - Indexing

- (void)addItem:(id<CBSIndexItem>)item completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    [self addItems:@[item] completionHandler:completionHandler];
}

- (void)addItems:(id<NSFastEnumeration>)items completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    [self createFTSIfNeeded];
    
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(self.indexQueue, ^{
        NSMutableArray *indexedItems = [NSMutableArray array];
        __block NSError *error = nil;
        
        [weakSelf.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:5];

            // try to index all documents
            for (id<CBSIndexItem> item in items) {
                // check self, if released, bail
                if (!weakSelf) {
                    error = [NSError errorWithDomain:@"com.cbsindexer"
                                                         code:0
                                                     userInfo:@{NSLocalizedDescriptionKey: @"indexer released"}];
                    CBSError(error);
                    
                    *rollback = YES;
                    return;
                }
                
                if ([item respondsToSelector:@selector(canIndex)] && ![item canIndex]) {
                    continue;
                }
                
                // validate identifier
                NSString *identifer = item.indexItemIdentifier;
                if (!identifer.length) {
                     error = [NSError errorWithDomain:@"com.cbsindexer"
                                                 code:1
                                             userInfo:@{NSLocalizedDescriptionKey: @"Missing item identifier."}];
                     CBSError(error);
                     *rollback = YES;
                     break;
                }

                @autoreleasepool {
                    [item willIndex];
                    
                    // priority
                    NSInteger priority = 0;
                    if ([item respondsToSelector:@selector(indexItemPriority)]) {
                        priority = item.indexItemPriority;
                    }

                    // insert into FTS
                    NSMutableArray *ftsColumns = [NSMutableArray arrayWithObjects:@"contents", @"priority", nil];
                    NSMutableArray *ftsParams = [NSMutableArray arrayWithObjects:@":contents", @":priority", nil];
                    
                    params[@"contents"] = item.indexTextContents;
                    params[@"priority"] = @(priority);

                    // meta
                    if ([item indexMeta].count) {
                        [ftsColumns addObject:@"item_meta"];
                        [ftsParams addObject:@":meta"];
                        params[@"meta"] = [NSJSONSerialization dataWithJSONObject:item.indexMeta
                                                                          options:0
                                                                            error:&error];
                        if (error) {
                            CBSError(error);
                            *rollback = YES;
                            break;
                        }
                    }
                    
                    NSString *ftsQuery = [NSString stringWithFormat:
                                       @"INSERT INTO %@ (%@) VALUES (%@)",
                                       weakSelf.indexName,
                                       [ftsColumns componentsJoinedByString:@","],
                                       [ftsParams componentsJoinedByString:@","]];
                    
                    [db executeUpdate:ftsQuery withParameterDictionary:params];
                    [params removeAllObjects];
                    
                    if ([db hadError]) {
                        error = [db lastError];
                        CBSError(error);
                        
                        *rollback = YES;
                        break;
                    }
                    
                    // insert into meta table
                    long long rowId = [db lastInsertRowId];
                    NSString *metaTableName = [NSString stringWithFormat:@"%@_meta", weakSelf.indexName];
                    NSString *metaQuery = [NSString stringWithFormat:
                                           @"INSERT INTO %@ (rowid, item_id, item_type) VALUES (?, ?, ?)",
                                           metaTableName];
                    
                    [db executeUpdate:metaQuery, @(rowId), identifer, @(item.indexItemType)];
                    
                    if ([db hadError]) {
                        error = [db lastError];
                        CBSError(error);
                        
                        *rollback = YES;
                        break;
                    }
                    
                    [indexedItems addObject:item];
                    [item didIndex];
                }
            }
        }];
        
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(indexedItems, error);
            });
        }
    });
}

- (id<CBSIndexItem>)addTextContents:(NSString *)contents itemType:(CBSIndexItemType)itemType meta:(NSDictionary *)meta completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    CBSIndexDocument *doc = [CBSIndexDocument newWithUID];
    doc.indexTextContents = contents;
    doc.indexItemType = itemType;
    doc.indexMeta = meta;
        
    [self addItem:doc completionHandler:completionHandler];
    
    return doc;
}

- (id<CBSIndexItem>)addTextContents:(NSString *)contents itemType:(CBSIndexItemType)itemType completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    return [self addTextContents:contents itemType:itemType meta:nil completionHandler:completionHandler];
}

- (id<CBSIndexItem>)addTextContents:(NSString *)contents completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    return [self addTextContents:contents itemType:CBSIndexItemTypeIgnore completionHandler:completionHandler];
}

- (void)updateItem:(id<CBSIndexItem>)item completionHandler:(CBSIndexerItemsCompletionHandler)completionHandler {
    __typeof__(self) __weak weakSelf = self;
    [self removeItems:@[item] completionHandler:^(NSError * _Nullable error) {
        if (error) {
            if (completionHandler) {
                completionHandler(@[], error);
            }
            return;
        }
        
        // re-add item
        [weakSelf addItem:item completionHandler:completionHandler];
    }];
}

- (void)removeItem:(id<CBSIndexItem>)item {
    [self removeItems:@[item] completionHandler:nil];
}

- (void)removeItems:(id<NSFastEnumeration>)items completionHandler:(CBSIndexerCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    
    __block NSError *error = nil;
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(self.indexQueue, ^{
        [weakSelf.databaseQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            NSString *metaTableName = [NSString stringWithFormat:@"%@_meta", weakSelf.indexName];
            
            for (id<CBSIndexItem> item in items) {
                NSAssert(item.indexItemIdentifier, @"Unable to remove item. No item identifier.");
                
                NSString *itemID = item.indexItemIdentifier;
                
                // get rowid
                FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT rowid FROM %@ WHERE item_id = ?", metaTableName], itemID];
                long long rowId = -1;
                if ([rs next]) {
                    rowId = [rs longLongIntForColumnIndex:0];
                }
                [rs close];
                
                if (rowId == -1) {
                    continue;
                }
                
                // delete from FTS
                [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE rowid = ?", weakSelf.indexName], @(rowId)];
                
                // delete from meta
                [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE rowid = ?", metaTableName], @(rowId)];
                
                if ([db hadError]) {
                    error = [db lastError];
                    CBSError(error);
                }
            }
        }];
        
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(error);
            });
        }
    });
}

- (void)removeItemWithID:(CBSIndexItemIdentifier)identifier {
    // create a temp doc
    CBSIndexDocument *item = [CBSIndexDocument newWithID:identifier];
    
    [self removeItem:item];
}

- (BOOL)removeAllItems {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.databasePath error:&error];
    
    if (error) {
        CBSError(error);
        return NO;
    }
    
    self.databaseQueue = nil;
    self.databaseCreated = NO;
    return YES;
}

- (void)reindexWithCompletionHandler:(CBSIndexerReindexCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    
    __block NSUInteger itemCount = 0;
    __block NSError *error = nil;
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(self.indexQueue, ^{
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            // rebuild FTS index structure
            [db executeUpdate:[NSString stringWithFormat:
                               @"INSERT INTO %@ (%@) VALUES ('rebuild')",
                               weakSelf.indexName,
                               weakSelf.indexName]];

            // rebuild meta table indices
            [db executeUpdate:[NSString stringWithFormat:@"REINDEX %@_meta", weakSelf.indexName]];
            
            if ([db hadError]) {
                error = [db lastError];
                CBSError(error);
            }
        }];
        
        itemCount = [weakSelf itemCount];
        
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(itemCount, error);
            });
        }
    });
}

- (void)optimizeIndexWithCompletionHandler:(CBSIndexerCompletionHandler)completionHandler {
    [self createDatabaseQueueIfNeeded];
    
    __block NSError *error = nil;
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(self.indexQueue, ^{
        [weakSelf.databaseQueue inDatabase:^(FMDatabase *db) {
            // optimize the internal structure of FTS table
            [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES ('optimize')",
             weakSelf.indexName,
             weakSelf.indexName]];
            
            // analyze meta table
            [db executeUpdate:[NSString stringWithFormat:@"ANALYZE %@_meta", weakSelf.indexName]];
            
            if ([db hadError]) {
                error = [db lastError];
                CBSError(error);
            }
        }];
        
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(error);
            });
        }
    });
}

- (NSUInteger)itemCount {
    __block NSUInteger count = 0;
    [self createDatabaseQueueIfNeeded];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:[@"SELECT COUNT(rowid) FROM " stringByAppendingString:self.indexName]];
        if ([result next]) {
            count = (NSUInteger) [result unsignedLongLongIntForColumnIndex:0];
        }
        [result close];
        
        if ([db hadError]) {
            CBSError([db lastError]);
        }
    }];
    
    return count;
}

@end
