//
//  CBSIndexDocument.h
//  CBSearchKit
//
//  Created by C. Bess on 2/27/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>

// identifier alias
typedef NSString* CBSIndexItemIdentifier;
// index item type
typedef NSInteger CBSIndexItemType;
/**
 Index item type that indicates the type should be ignored.
 
 @discussion This is usually used by index item queries to include all items in the results.
 */
extern NSInteger const CBSIndexItemTypeIgnore;


/**
 An index database item.
 */
@protocol CBSIndexItem <NSObject>

/**
 The identifier for the receiver in the index database.
 */
@property (nonatomic, copy) CBSIndexItemIdentifier indexItemIdentifier;

/**
 The text contents to index.
 
 @discussion This is used to index the item. It is searchable.
 */
- (NSString *)indexTextContents;

/**
 A value indicating if the receiver can be indexed.
 
 @discussion This is only evaluated during indexing operations.
 */
- (BOOL)canIndex;

/**
 The item type for the receiver.
 */
- (CBSIndexItemType)indexItemType;

/**
 Additional data to store with the index item.
 
 @discussion This data is not searchable, but is returned with the item.
 */
// not supported, yet
//- (NSDictionary *)indexMeta;

@end


/**
 Represents a concrete CBIndexItem type.
 */
@interface CBSIndexDocument : NSObject <CBSIndexItem, NSCopying>

@property (nonatomic, copy) CBSIndexItemIdentifier indexItemIdentifier;
@property (nonatomic, copy) NSString *indexTextContents;
@property (nonatomic, assign) CBSIndexItemType indexItemType;
// not supported, yet
@property (nonatomic, copy) NSDictionary *indexMeta;

@end
