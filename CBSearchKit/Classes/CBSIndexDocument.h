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

/**
 An index database item.
 */
@protocol CBSIndexItem <NSObject>

/**
 The name of the property/key that will store the indexer item identifier.
 
 @discussion This will be used to get/set the identifier value. Uses KVC.
 */
- (NSString *)indexItemIdentifierKey;

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
 Additional data to store with the index item.
 
 @discussion This data is not searchable, but is returned with the item.
 */
// not supported, yet
//- (NSDictionary *)indexMeta;

@end


/**
 Represents a concrete CBIndexItem type.
 */
@interface CBSIndexDocument : NSObject <CBSIndexItem>

@property (nonatomic, copy) CBSIndexItemIdentifier indexItemIdentifier;
@property (nonatomic, copy) NSString *indexTextContents;
// not supported, yet
@property (nonatomic, copy) NSDictionary *indexMeta;

@end
