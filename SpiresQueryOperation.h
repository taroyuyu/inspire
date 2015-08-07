//
//  SpiresQueryOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
#import "DumbOperation.h"
@class Article;
@class JSONImportOperation;
typedef void (^ActionOnBatchImportBlock)(JSONImportOperation*);
@interface SpiresQueryOperation : ConcurrentOperation
-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m;
-(void)setBlockToActOnBatchImport:(ActionOnBatchImportBlock)actionBlock;
@end
