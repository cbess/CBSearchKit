//
//  CBSIndexDocument.m
//  CBSearchKit
//
//  Created by C. Bess on 2/27/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#import "CBSIndexDocument.h"

NSInteger const CBSIndexItemTypeIgnore = -1;

@interface CBSIndexDocument ()
@property (readwrite, copy) CBSIndexItemIdentifier indexItemIdentifier;
@end

@implementation CBSIndexDocument

+ (instancetype)newWithID:(CBSIndexItemIdentifier)identifier text:(NSString *)text {
    CBSIndexDocument *doc = [[self alloc] initWithID:identifier];
    doc.indexTextContents = text;
    return doc;
}

+ (instancetype)newWithID:(CBSIndexItemIdentifier)identifier {
    return [self newWithID:identifier text:nil];
}

+ (instancetype)newWithUID {
    return [self newWithID:[[NSUUID UUID] UUIDString]];
}

- (instancetype)initWithID:(CBSIndexItemIdentifier)identifier {
    self = [self init];
    if (self) {
        self.indexItemIdentifier = identifier;
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        _indexItemType = CBSIndexItemTypeIgnore;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    CBSIndexDocument *doc = [[self class] new];
    doc.indexItemIdentifier = self.indexItemIdentifier;
    doc.indexTextContents = self.indexTextContents;
    doc.indexItemType = self.indexItemType;
    doc.indexMeta = self.indexMeta;
    
    return doc;
}

- (BOOL)canIndex {
    return YES;
}

- (void)willIndex {
    // empty
}

- (void)didIndex {
    // empty
}

@end
