//
//  ArxivPDFDownloadOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DumbOperation.h"
#import "PDFHelper.h"
@interface ArxivPDFDownloadOperation : ConcurrentOperation {
    Article*article;
    NSNumber* reloadDelay;
    BOOL shouldAsk;
}
-(ArxivPDFDownloadOperation*)initWithArticle:(Article*)a shouldAsk:(BOOL)ask;

@end
