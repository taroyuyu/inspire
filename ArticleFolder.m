//
//  ArticleFolder.m
//  spires
//
//  Created by Yuji on 09/03/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArticleFolder.h"


@implementation ArticleFolder
+(ArticleFolder*)createArticleFolderWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"ArticleFolder" inManagedObjectContext:moc];
    ArticleFolder* mo=(ArticleFolder*)[[NSManagedObject alloc] initWithEntity:entity 
			       insertIntoManagedObjectContext:moc];
    mo.name=s;
    return mo;
}
-(void)reload
{
}
-(NSImage*)icon
{
    return [[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle mainBundle] resourcePath]];
}
-(BOOL)searchStringEnabled
{
    return NO;
}
@end
