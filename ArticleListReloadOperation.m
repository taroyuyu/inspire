//
//  ArxivNewReloadOperation.m
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArticleListReloadOperation.h"
#import "ArticleList.h"

@implementation ArticleListReloadOperation
-(ArticleListReloadOperation*)initWithArticleList:(ArticleList*)l;
{
    self=[super init];
    list=l;
    return self;
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"reload %@",list.name];
}
-(void)main
{
    [list performSelectorOnMainThread:@selector(reload) withObject:nil waitUntilDone:YES];
}
@end
