// 
//  AllArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "AllArticleList.h"
#import "MOC.h"

static AllArticleList*_allArticleList=nil;
@implementation AllArticleList 

+(AllArticleList*)allArticleListInMOC:(NSManagedObjectContext*)moc
{
    NSArray* a=nil;
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"AllArticleList" inManagedObjectContext:moc];
    {
	NSFetchRequest*req=[[NSFetchRequest alloc]init];
	[req setEntity:authorEntity];
	NSError*error=nil;
	a=[moc executeFetchRequest:req error:&error];
    }
    if([a count]==1){
	return [a objectAtIndex:0];
    }else if([a count]>1){
	NSLog(@"inconsistency detected ... there are more than one AllArticleLists!");
        AllArticleList*max=[a objectAtIndex:0];
	for(NSUInteger i=1;i<[a count];i++){
	    AllArticleList*al=[a objectAtIndex:i];
            if([al.articles count]>[max.articles count]){
                max=al;
            }
	}
        for(AllArticleList*al in a){
            if(al!=max){
                [moc deleteObject:al];
            }
        }
	return max;
    }else{
	return nil;
    }
}
+(AllArticleList*)createAllArticleListInMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"AllArticleList" inManagedObjectContext:moc];

    AllArticleList* mo=(AllArticleList*)[[NSManagedObject alloc] initWithEntity:entity
				insertIntoManagedObjectContext:nil];
    [mo setValue:@"spires" forKey:@"name"];
    [mo setValue:[NSNumber numberWithInt:0] forKey:@"positionInView"];
    mo.sortDescriptors=[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"eprintForSorting" ascending:NO]];
    [moc insertObject:mo];	
    
    NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:articleEntity];
    [req setPredicate:[NSPredicate predicateWithValue:YES]];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    NSSet* s=[NSSet setWithArray:a];
    [mo addArticles:s];
    error=nil;
    [moc save:&error];
    return mo;    
}
+(AllArticleList*)allArticleList
{
    if(!_allArticleList){
	_allArticleList=[self allArticleListInMOC:[MOC moc]];
    }
    if(!_allArticleList){
	_allArticleList=[self createAllArticleListInMOC:[MOC moc]];
    }
    return _allArticleList;
}
-(void)reload
{
}
-(NSImage*)icon
{
    return [NSImage imageNamed:@"spires-blue.png"];
}
-(NSString*)placeholderForSearchField
{
    return @"Enter SPIRES query and hit return";
}
@end
