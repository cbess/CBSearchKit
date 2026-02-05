//
//  CBSIndexDocument.h
//  CBSearchKit
//
//  Created by C. Bess on 2/27/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import <Foundation/Foundation.h>

/// identifier alias
typedef NSString *CBSIndexItemIdentifier;

/// index item type
typedef NSInteger CBSIndexItemType;

/**
 Index item type that indicates the type should be ignored.
 
 @discussion This is usually used by index item queries to include all items in the results.
 */
extern NSInteger const CBSIndexItemTypeIgnore;


/// Forwards the call to the internal index item object.
@protocol CBSIndexItem <NSObject>

/// The identifier for the receiver in the index database.
- (nonnull CBSIndexItemIdentifier)indexItemIdentifier;

/**
 The text contents to index.
 
 @discussion This is used to index the item. It is searchable.
 */
- (nonnull NSString *)indexTextContents;

/**
 A value indicating if the receiver can be indexed.
 
 @discussion This is only evaluated during indexing operations.
 */
- (BOOL)canIndex;

/// The item type for the receiver.
- (CBSIndexItemType)indexItemType;

/**
 Additional data to store with the index item.
 
 @discussion This data is not searchable, but is returned with the item. Should contain Foundation objects only (NSNumber, NSString, etc).
 */
- (nullable NSDictionary *)indexMeta;

/// Invoked before the document is indexed. Called on background thread.
- (void)willIndex;

/// Invoked after the document has been indexed. Called on background thread.
/// This will not be called if indexing for this document fails to complete.
- (void)didIndex;

@end


/// Represents a concrete `CBIndexItem` type.
@interface CBSIndexDocument : NSObject <CBSIndexItem, NSCopying>

@property (nonatomic, copy, nonnull, readonly) CBSIndexItemIdentifier indexItemIdentifier;
@property (nonatomic, copy, nonnull) NSString *indexTextContents;
@property (nonatomic, assign) CBSIndexItemType indexItemType;
@property (nonatomic, copy, nullable) NSDictionary *indexMeta;

/// Creates a new instance with a unique ID assigned
+ (nonnull instancetype)newWithUID;

/// Creates a new instance with the specified ID
+ (nonnull instancetype)newWithID:(nonnull CBSIndexItemIdentifier)identifier;

/// Creates a new instance with the specified ID and text
+ (nonnull instancetype)newWithID:(nonnull CBSIndexItemIdentifier)identifier text:(nullable NSString *)text;

/// Initializes a new instance with specified identifier
- (nonnull instancetype)initWithID:(nonnull CBSIndexItemIdentifier)identifier;

- (nonnull id)init NS_UNAVAILABLE;

@end
