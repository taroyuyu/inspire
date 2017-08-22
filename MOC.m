//
//  MOC.m
//  spires
//
//  Created by Yuji on 09/02/28.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "MOC.h"
#if !TARGET_OS_IPHONE
#import "Migrator.h"
#endif
#import "DumbOperation.h"

NSString* UIMOCDidMergeNotification=@"UIMOCDidMergeNotification";


@implementation NSManagedObjectContext (TrivialAddition)
-(void)enableUndo
{
    [self processPendingChanges];
    [[self undoManager] enableUndoRegistration];    
}
-(void)disableUndo
{
    [self processPendingChanges];
    [[self undoManager] disableUndoRegistration];    
}

@end


@implementation MOC
{
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *persistingManagedObjectContext;
    NSManagedObjectContext *uiManagedObjectContext;
    BOOL isUIready;
}

@synthesize isUIready;
+(MOC*)sharedMOCManager
{
    static MOC*_sharedMOCManager=nil;
    static dispatch_once_t once;
    dispatch_once(&once,^{
        _sharedMOCManager=[[MOC alloc] init];
    });
    return _sharedMOCManager;
}
+(NSManagedObjectContext*)moc
{
    return [[MOC sharedMOCManager] managedObjectContext];
}
-(MOC*)init
{
    return [super init];
}
- (NSString *)applicationSupportFolder {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? paths[0] : NSTemporaryDirectory();
    NSString* appSupportFolder= [basePath stringByAppendingPathComponent:@"spires"];
    
    NSFileManager *fileManager=[NSFileManager defaultManager];
    NSError *error=nil;
    if ( ![fileManager fileExistsAtPath:appSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:appSupportFolder 
	       withIntermediateDirectories:YES 
				attributes:nil 
				     error:&error];
    }
    return appSupportFolder;
    
}

/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];    
    
    return managedObjectModel;
}



-(NSString*)dataFilePath
{
    NSString* extension=[[NSUserDefaults standardUserDefaults] stringForKey:@"CoreDataStoreType"];
    NSString* debug=@"";
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"debugMode"]){
	debug=@"_debug";
    }
    //    NSLog(@"%@",extension);
    if(!extension){
	extension=@".sqlite";
    }
    return [[self applicationSupportFolder] stringByAppendingPathComponent: [NSString stringWithFormat:@"spiresDatabase%@%@",debug,extension]];
}

-(NSString*)storeType
{
    return NSSQLiteStoreType;
}
- (BOOL)migrationNeeded
{
#if TARGET_OS_IPHONE
    return NO;
#else
    if(![[NSFileManager defaultManager] fileExistsAtPath:[self dataFilePath]]){
	return NO;
    }
    NSError*error=nil;
    NSDictionary *sourceMetadata =
    [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:[self storeType]
							       URL:[NSURL fileURLWithPath:[self dataFilePath]]
							     error:&error];
    
    if (sourceMetadata == nil) {
	// deal with error
	// but don't care here
	return YES;
    }
    return ![[self managedObjectModel] isConfiguration:nil
			   compatibleWithStoreMetadata:sourceMetadata];
#endif
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The folder for the store is created, 
 if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    
   persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
#if !TARGET_OS_IPHONE
    if([self migrationNeeded]){
	Migrator*migrator=[[Migrator alloc] initWithDataPath:[self dataFilePath]];
	[migrator performMigration];
    }
#endif
    
#if TARGET_OS_IPHONE
    NSURL*docDir=[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL*dataURL=[docDir URLByAppendingPathComponent:@"spiresDatabase.sqlite"];
#else
    NSURL*dataURL=[NSURL fileURLWithPath:[self dataFilePath]];
#endif
    
    NSError*error=nil;
    if (![persistentStoreCoordinator addPersistentStoreWithType:[self storeType]
						  configuration:nil 
							    URL:dataURL
							options:@{NSSQLitePragmasOption:@{ @"journal_mode" :@"DELETE" }}
							  error:&error]){
//        [[NSApplication sharedApplication] presentError:error];
    }
    
    return persistentStoreCoordinator;
}

/*
 Merge policies:
 Main moc: error on conflict. I should arrange no conflict occurs in the save: operation from the main thread on the main moc.
 2ndary moc:  changes in moc forced into the disk. This alone will surely cause the conflict, so all of the saved objects are passed
           to the main thread as the managed object ID, and then conflict resolution is done immediately.
	   Now, the conflict resolution is easy for Articles because I should prefer them on the main moc,
           but once one starts mingling with the ArticleLists in the secondary moc various messy things happen.
           Currently registration into lists are done on the main thread, on the main moc only. Mar/2/2009
 */
/*
 Changed main moc merge policy to ObjectTrump. Mar/30/2009
 */
/*
 After a few months of intermittent works, the coredata stack is now moved to the modern one.
 At the latest stage I learned of 
    https://github.com/bignerdranch/CoreDataStack/
 which was very helpful. 
 Somehow setting a merge policy in this child-parent setup makes everything crash-prone, 
 although I don't know why.
 
 Sep/29/2015
 */
/*
 After a long hiatus I'm thinking of restarting to work on this app. Somehow the CoreDataStack above with Cocoa Binding seems to lead to mysterious crashes (or maybe I'm not doing it right.) Anyway, to make it less crash-prone, I'm temporarily removing the root private MOC below the UI MOC. 
 May/6/2016
 */
-(void)saveNotified:(NSNotification*)n
{
    NSManagedObjectContext*moc=n.object;
/*    if(moc.parentContext){
        [moc.parentContext performBlock:^{
            [moc.parentContext save:NULL];
        }];
    }
 */
    if(moc!=uiManagedObjectContext){
        // this is from secondary context, need to merge
        [uiManagedObjectContext performBlock:^{
            [uiManagedObjectContext mergeChangesFromContextDidSaveNotification:n];
            [[NSNotificationCenter defaultCenter] postNotificationName:UIMOCDidMergeNotification object:nil];
        }];
    }
}
- (NSManagedObjectContext *) managedObjectContext {
    
    if (uiManagedObjectContext != nil) {
        return uiManagedObjectContext;
    }
    if(![[NSThread currentThread] isMainThread]){
        NSLog(@"the first call should be from the main thread");
        abort();
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
//        persistingManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//        [persistingManagedObjectContext setPersistentStoreCoordinator: coordinator];
        uiManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//       [uiManagedObjectContext setParentContext:persistingManagedObjectContext];
        uiManagedObjectContext.persistentStoreCoordinator=coordinator;
        uiManagedObjectContext.mergePolicy=NSMergeByPropertyObjectTrumpMergePolicy;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveNotified:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:nil];
        

    }
    
    return uiManagedObjectContext;
}

- (NSManagedObjectContext *) createSecondaryMOC {
    
    
    NSManagedObjectContext*secondaryManagedObjectContext=[[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    secondaryManagedObjectContext.persistentStoreCoordinator=[self persistentStoreCoordinator];
//    [secondaryManagedObjectContext setParentContext:[self managedObjectContext]];
//    [secondaryManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [secondaryManagedObjectContext setUndoManager:nil];

    return secondaryManagedObjectContext;
}

-(void)presentMOCSaveError:(NSError*)error
{
    // Note that this method is sometimes called from a secondary thread...
    NSLog(@"moc error:%@",error);
    NSDictionary* dict=[error userInfo];
    NSLog(@"userInfo:%@",dict);
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"debugMOCsave"]){
	NSArray* detailedErrors=dict[@"NSDetailedErrors"];
	if(detailedErrors){
	    for(NSError*e in detailedErrors){
		NSLog(@"moc suberror:%@",e);
		NSDictionary* d=[e userInfo];
		if(d){
		    NSLog(@"userInfo:%@",d);	 
		}
	    }
	}    
    }
}
#pragma mark Vacuum-cleaner
-(void)vacuum
{
    NSError*error=nil;
    if(![[self managedObjectContext] save:&error]){
	NSLog(@"save error:%@. Proceed...",error);
    }
    NSPersistentStoreCoordinator*psc=[self persistentStoreCoordinator];
    NSArray*stores=[psc persistentStores];
    error=nil;
    if(![psc removePersistentStore:stores[0] error:&error]){
	NSLog(@"couldn't remove:%@",error);
	return;
    }
    error=nil;
    NSMutableDictionary*options=[NSMutableDictionary dictionary];
    options[NSSQLiteManualVacuumOption] = @YES;
    options[NSSQLiteAnalyzeOption] = @YES;
    if (![psc addPersistentStoreWithType:[self storeType]
			   configuration:nil 
				     URL:[NSURL fileURLWithPath:[self dataFilePath]] 
				 options:options
				   error:&error]){
	NSLog(@"something really bad:%@",error);
    }
}


@end
