//
//  CBSCustomIndexDocument.h
//  CBSearchKitTests
//
//  Created by C. Bess on 3/3/18.
//  Copyright © 2018 C. Bess. All rights reserved.
//

#import "CBSIndexDocument.h"

@interface CBSCustomIndexDocument : CBSIndexDocument

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSNumber *index;
@property (nonatomic, copy) NSString *uid;

@end
