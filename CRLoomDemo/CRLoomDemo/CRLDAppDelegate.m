//
//  CRLDAppDelegate.m
//  CRLoomDemo
//
//  Created by Collin Ruffenach on 7/20/13.
//
//

#import "CRLDAppDelegate.h"
#import "CRTableViewController.h"
#import "NSManagedObjectImportOperation.h"
#import "Person+Import.h"
#import "CRLoom.h"

@implementation CRLDAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

id randomObject (NSArray *array) {
    return array[arc4random() % array.count];
}

NSArray * firstNames() {
    return @[@"Collin",
             @"Caitlin",
             @"Sean",
             @"James",
             @"Bill",
             @"Tom",
             @"Jim",
             @"Dustin",
             @"Kate",
             @"Ashley",
             @"Mellissa",
             @"Doug",
             @"Robert",
             @"Jake",
             @"Lucas",
             @"Brent",
             @"Stephen",
             @"Brett",
             @"Kristen",
             @"Courtney",
             @"Bethany",
             @"Natalie",
             @"Jeniffer",
             @"Gene",
             @"Ryan",
             @"Jesus",
             @"Jay",
             @"Ned",
             @"Tad",
             @"Tristan",
             @"Josh",
             @"Shamir",
             @"John",
             @"Mark",
             @"Luke",
             @"Paul"];
}

NSArray * lastNames() {
    return @[@"Ford",
             @"Doe",
             @"Jones",
             @"Ruffenach",
             @"Acker",
             @"Schepman",
             @"Schauder",
             @"Pitt",
             @"Damon",
             @"Wilson",
             @"Shedlock",
             @"Ridgeway",
             @"Freed",
             @"Freeman",
             @"Hartwig",
             @"Nu"];
}

NSString * randomName() {
    return [NSString stringWithFormat:@"%@ %@", randomObject(firstNames()), randomObject(lastNames())];
}

NSArray * jobs() {
    return @[@"Plumber",
             @"Programmer",
             @"IT",
             @"Web Developer",
             @"Accountant",
             @"Teacher",
             @"Salesman",
             @"Customer Support Rep",
             @"Realestate Agent",
             @"Doctor",
             @"Lawyer",
             @"Investor",
             @"Painter",
             @"Mechanic",
             @"Carpenter",
             @"HR Rep"];
}

NSInteger randomJobID() {
    return arc4random() % jobs().count;
}

void generateRandomData() {
    NSInteger numberOfObjects = 1000;
    
    NSMutableArray *jobsData = [@[] mutableCopy];
    for (int i = 0; i < jobs().count; i++) {
        jobsData[i] = @{@"id"    : @(i),
                       @"name"  : jobs()[i]};
    }
    
    NSMutableArray *people = [NSMutableArray arrayWithCapacity:numberOfObjects];
    for (int i = 0; i < 1000; i++) {
        people[i] = @{@"id"   : @(i),
                      @"name" : randomName(),
                      @"job"  : @(randomJobID()),
                      @"age"  : @(arc4random() % 100)};
    }
    
    __autoreleasing NSError *error = nil;
    [[NSJSONSerialization dataWithJSONObject:@{@"jobs" : jobsData, @"people" : people} options:NSJSONWritingPrettyPrinted error:&error] writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"data.json"] atomically:YES];
}

- (void)importData:(BOOL)thread useCache:(BOOL)useCache {
    __autoreleasing NSError *error = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SampleData"
                                                                                                                                                      ofType:@"json"]]]
                                                         options:0
                                                           error:&error];
    if (thread) {
        NSManagedObjectImportOperation *jobOperation = [NSManagedObjectImportOperation operationWithData:data[@"jobs"]
                                                                                      managedObjectClass:[Job class]
                                                                                        guaranteedInsert:NO
                                                                                         saveOnBatchSize:25
                                                                                                useCache:NO
                                                                                                   error:&error];
        
        NSManagedObjectImportOperation *peopleImportOperation = [NSManagedObjectImportOperation operationWithData:data[@"people"]
                                                                                               managedObjectClass:[Person class]
                                                                                                 guaranteedInsert:NO
                                                                                                  saveOnBatchSize:25
                                                                                                         useCache:useCache
                                                                                                            error:&error];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [queue addOperation:jobOperation];
        [queue addOperation:peopleImportOperation];
    } else {
        [Job importData:data[@"jobs"]
            intoContext:[self managedObjectContext]
              withCache:nil
       guaranteedInsert:YES
        saveOnBatchSize:25
                  error:&error];
        [Person importData:data[@"people"]
               intoContext:[self managedObjectContext]
                 withCache:nil
          guaranteedInsert:YES
           saveOnBatchSize:25
                     error:&error];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [CRLoom setMainThreadManagedObjectContext:[self managedObjectContext]];
    [self importData:YES useCache:YES];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    CRTableViewController *tableViewController = [[CRTableViewController alloc] init];
    self.window.rootViewController = tableViewController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CRLoomDemo" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CRLoomDemo.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end