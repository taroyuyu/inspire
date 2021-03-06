//
//  AppDelegate.m
//  inspire
//
//  Created by Yuji on 2015/08/27.
//
//

#import "InspireAppDelegate.h"
#import "ArticleTableViewController.h"
#import "ArticleListTableViewController.h"
#import "NSUserDefaults+defaults.h"
#import "MOC.h"
#import "DumbOperation.h"
#import "SpiresQueryOperation.h"
#import "SpiresHelper.h"
#import "ArticleList.h"
#import "AllArticleList.h"
#import "Article.h"
#import "PDFHelper.h"
#import "SyncManager.h"
#import "NSString+magic.h"

@interface InspireAppDelegate () <UISplitViewControllerDelegate>

@end

static InspireAppDelegate*globalAppDelegate=nil;


@implementation InspireAppDelegate
{
    SyncManager*syncManager;
    IntroViewController*ivc;
    NSTimer*timer;
}

-(void)closed:(id)sender
{
    [[NSApp appDelegate].presentingViewController dismissViewControllerAnimated:ivc completion:^{}];
    ivc=nil;
}
#pragma mark Global AppDelegate methods
+(id<AppDelegate>)appDelegate
{
    return globalAppDelegate;
}
-(void)startProgressIndicator
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}
-(void)stopProgressIndicator
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}
-(void)querySPIRES:(NSString*)search
{
    if(!search)return;
    NSPredicate*pred=[[SpiresHelper sharedHelper] predicateFromSPIRESsearchString:search];
    if(!pred)return;
    [AllArticleList allArticleList].searchString=search;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"newSearchInitiated" object:nil];
    [[OperationQueues spiresQueue] addOperation:[[SpiresQueryOperation alloc] initWithQuery:search andMOC:[MOC moc]]];
}
-(void)postMessage:(NSString*)message
{
    if(message){
        [self startProgressIndicator];
    }else{
        [self stopProgressIndicator];
    }
}
-(void)clearingUpAfterRegistration:(id)sender
{
    
}
-(BOOL)currentListIsArxivReplaced
{
    return NO;
}
-(UIViewController*)presentingViewController
{
    if(ivc){
        return ivc;
    }else{
        return self.window.rootViewController;
    }
}
#pragma mark PDF
-(void)setupPDFdir
{
    NSURL*docDirURL=[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString*docDir=[docDirURL path];
    NSString*dir=[docDir stringByAppendingPathComponent:@"pdf"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSUserDefaults standardUserDefaults] setObject:dir forKey:@"pdfDir"];
}

-(void)handleURL:(NSURL*) url
{
    //    NSLog(@"handles %@",url);
    if([[url scheme] isEqualToString:@"spires-search"]){
        NSString*searchString=[[url absoluteString] substringFromIndex:[(NSString*)@"spires-search://" length]];
        searchString=[searchString stringByRemovingPercentEncoding];
        [self querySPIRES:searchString];
    }else if([[url scheme] isEqualToString:@"spires-open-pdf-internal"]){
        NSString*x=[url absoluteString];
        NSString*y=[x substringFromIndex:[@"spires-open-pdf-internal://" length]];
        y=[y stringByReplacingOccurrencesOfString:@"x-coredata//" withString:@"x-coredata://"];
        NSURL*z=[NSURL URLWithString:y];
        Article*a=(Article*)[[MOC moc] objectRegisteredForID:[[MOC moc].persistentStoreCoordinator managedObjectIDForURIRepresentation:z]];
        [[PDFHelper sharedHelper] openPDFforArticle:a usingViewer:openWithPrimaryViewer];
    }else if([[url scheme] isEqualToString:@"spires-flag"]){
        NSString*x=[url absoluteString];
        NSString*y=[x substringFromIndex:[@"spires-flag://" length]];
        y=[y stringByReplacingOccurrencesOfString:@"x-coredata//" withString:@"x-coredata://"];
        NSURL*z=[NSURL URLWithString:y];
        Article*a=(Article*)[[MOC moc] objectRegisteredForID:[[MOC moc].persistentStoreCoordinator managedObjectIDForURIRepresentation:z]];
       [a setFlag: a.flag | AFIsFlagged];
        [[MOC moc] save:NULL];
    }else if([[url scheme] isEqualToString:@"spires-unflag"]){
        NSString*x=[url absoluteString];
        NSString*y=[x substringFromIndex:[@"spires-unflag://" length]];
        y=[y stringByReplacingOccurrencesOfString:@"x-coredata//" withString:@"x-coredata://"];
        NSURL*z=[NSURL URLWithString:y];
        Article*a=(Article*)[[MOC moc] objectRegisteredForID:[[MOC moc].persistentStoreCoordinator managedObjectIDForURIRepresentation:z]];
        [a setFlag: a.flag & ~AFIsFlagged];
        [[MOC moc] save:NULL];
    }else if([[url scheme] isEqualToString:@"spires-lookup-eprint"]){
        NSString*eprint=[[url absoluteString] extractArXivID];
        if(eprint){
            NSString*searchString=[@"spires-search://eprint%20" stringByAppendingString:eprint];
            [self performSelector:@selector(handleURL:)
                       withObject:[NSURL URLWithString:searchString]
                       afterDelay:.5];
        }
    }else if([[url scheme] isEqualToString:@"spires-open-journal"]){
//        [self openJournal:self];
    }else if([[url scheme] hasPrefix:@"http"]){
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}
#pragma mark Other pieces

+(void)initialize
{
    [NSUserDefaults loadInitialDefaults];
}

-(void)selectAllArticleList
{
    self.articleTableViewController.articleList=[AllArticleList allArticleList];
}
-(BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}
-(BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return YES;
}
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    globalAppDelegate=self;

    [ArticleList createStandardArticleListsInMOC:[MOC moc]];
    [self setupPDFdir];

    self.splitViewController = (UISplitViewController *)self.window.rootViewController;
    self.splitViewController.delegate = self;

    self.masterNavigationController=self.splitViewController.viewControllers[0];
    self.articleListTableViewController=(ArticleListTableViewController*)self.masterNavigationController.topViewController;
    self.articleListTableViewController.parent=nil;
    
    self.detailNavigationController=self.splitViewController.viewControllers[1];
    self.articleTableViewController=(ArticleTableViewController*)self.detailNavigationController.topViewController;
    
    self.articleTableViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.articleTableViewController.navigationItem.leftItemsSupplementBackButton = YES;

    
    [self selectAllArticleList];
    
    syncManager=[[SyncManager alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showIntro:) name:@"showIntro" object:nil];
    
    
    return YES;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"introShown"]){
            [self showIntro:nil];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"introShown"];
        }
    });
    return YES;
}
-(void)showIntro:(NSNotification*)n
{
    if(ivc)
        return;
    ivc=[[IntroViewController alloc] init];
    ivc.delegate=self;
    [self.splitViewController presentViewController:ivc animated:YES completion:^{}];
}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [[MOC moc] save:NULL];
}

#pragma mark - Split view

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    return self.masterNavigationController;
}
- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController {
    return self.masterNavigationController;
}
- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    return YES;
}
- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
    self.articleTableViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.articleTableViewController.navigationItem.leftItemsSupplementBackButton = YES;

    return self.detailNavigationController;
}
@end
