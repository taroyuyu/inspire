//
//  ArxivPDFDownloadOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArxivPDFDownloadOperation.h"
#import "Article.h"
#import "PDFHelper.h"
#import "ArxivHelper.h"
#import "AppDelegate.h"

@interface ArxivPDFDownloadOperation ()
-(void)pdfDownloadDidEnd:(NSDictionary*)dict;
-(void)retryAlertDidEnd:(NSAlert*)alert code:(int)choice context:(void*)ignore;
-(void)retry;
@end

@implementation ArxivPDFDownloadOperation

-(ArxivPDFDownloadOperation*)initWithArticle:(Article*)a shouldAsk:(BOOL)ask;
{
    self=[super init];
    article=a;
    shouldAsk=ask;
    return self;
}

-(void)downloadAlertDidEnd:(NSAlert*)alert code:(int)choice context:(id)ignore
{
    if(choice==NSAlertDefaultReturn){
	[[NSApp appDelegate] startProgressIndicator];
	[[NSApp appDelegate] postMessage:@"Downloading PDF from arXiv..."]; 
	[[ArxivHelper sharedHelper] startDownloadPDFforID:article.eprint
						 delegate:self 
					   didEndSelector:@selector(pdfDownloadDidEnd:)];
    }else{
	[self finish];
    }
}

-(void)pdfDownloadDidEnd:(NSDictionary*)dict
{
    BOOL success=[[dict valueForKey:@"success"] boolValue];
    [[NSApp appDelegate] postMessage:nil]; 
    [[NSApp appDelegate] stopProgressIndicator];
    
    if(success){
	NSData* data=[dict valueForKey:@"pdfData"];
	if(![data writeToFile:article.pdfPath atomically:NO]){
	    [[NSApp appDelegate] presentFileSaveError];
	}else{
	    [article associatePDF:article.pdfPath];
	}
	[self finish];
    }else if([dict objectForKey:@"shouldReloadAfter"]){
	reloadDelay=[dict objectForKey:@"shouldReloadAfter"];
	NSAlert*alert=[NSAlert alertWithMessageText:@"PDF Download"
				      defaultButton:@"OK" 
				    alternateButton:@"Cancel downloading"
					otherButton:nil
			  informativeTextWithFormat:@"arXiv is now generating %@. Retrying in %@ seconds.", article.eprint,reloadDelay];
	[alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
			  modalDelegate:self 
			 didEndSelector:@selector(retryAlertDidEnd:code:context:)
			    contextInfo:nil];
    }else{//failure
	[self finish];
    }
}
-(void)retryAlertDidEnd:(NSAlert*)alert code:(int)choice context:(void*)ignore
{
    if(choice==NSAlertDefaultReturn){
//	NSLog(@"OK, retry in %@ seconds",reloadDelay);
	[[NSApp appDelegate] postMessage:@"Waiting for arXiv to generate PDF..."]; 
	[self performSelector:@selector(retry) withObject:nil afterDelay:[reloadDelay intValue]];
    }else{
	[self finish];
    }
}

-(void)retry
{
    //    NSLog(@"retry timer fired");
    [[NSApp appDelegate] startProgressIndicator];
    [[NSApp appDelegate] postMessage:@"Downloading PDF from arXiv..."]; 
    [[ArxivHelper sharedHelper] startDownloadPDFforID:article.eprint
					     delegate:self 
				       didEndSelector:@selector(pdfDownloadDidEnd:)];
}
-(void)run
{
    self.isExecuting=YES;
    if(shouldAsk && [[NSUserDefaults standardUserDefaults] boolForKey:@"askBeforeDownloadingPDF"]){
	NSAlert*alert=[NSAlert alertWithMessageText:@"PDF Download"
				      defaultButton:@"Download" 
				    alternateButton:@"Cancel"
					otherButton:nil
			  informativeTextWithFormat:@"%@v%@ is not yet downloaded ...", article.eprint,article.version];
	[alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
			  modalDelegate:self 
			 didEndSelector:@selector(downloadAlertDidEnd:code:context:)
			    contextInfo:nil];
    }else{
	[self downloadAlertDidEnd:nil code:NSAlertDefaultReturn context:nil];
    }
}
-(void)cleanupToCancel
{
    [[NSApp appDelegate] postMessage:nil]; 
    [[NSApp appDelegate] stopProgressIndicator];
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"arxiv download for %@",article.eprint];
}

@end
