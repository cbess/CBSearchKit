//
//  CBSSearchKit.h
//  CBSearchKit
//
//  Created by C. Bess on 2/24/14.
//  Copyright (c) 2014 C. Bess. All rights reserved.
//

#ifndef CBSearchKit_CBSSearchKit_h
#define CBSearchKit_CBSSearchKit_h

#import "CBSIndexer.h"
#import "CBSSearcher.h"
#import "CBSSearchManager.h"

#if defined(DEBUG) && defined(CBS_LOGS)
#   define CBSLog(PREFIX, MSG, ...) NSLog((PREFIX@" [%s:%d] "MSG), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define CBSLog(PREFIX, MSG, ...) ;
#endif

#endif
