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
             @"Carpender",
             @"HR Rep"];
}

NSString * randomJob() {
    return randomObject(jobs());
}

void generateRandomData() {
    NSInteger numberOfObjects = 1000;
    NSMutableArray *data = [NSMutableArray arrayWithCapacity:numberOfObjects];
    for (int i = 0; i < 1000; i++) {
        data[i] = @{@"id"   : @(i),
                    @"name" : randomName(),
                    @"job"  : randomJob(),
                    @"age"  : @(arc4random() % 100)};
    }
    
    __autoreleasing NSError *error = nil;
    [[NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error] writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"data.json"] atomically:YES];
}

- (void)importData {
    __autoreleasing NSError *error = nil;
    NSArray *data = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SampleData"
                                                                                                                                                 ofType:@"json"]]]
                                                    options:0
                                                      error:&error];
    NSManagedObjectImportOperation *importOperation = [NSManagedObjectImportOperation operationWithData:data
                                                                                     managedObjectClass:[Person class]
                                                                                       guaranteedInsert:NO
                                                                                        saveOnBatchSize:25
                                                                                               useCache:NO
                                                                                                  error:&error];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:importOperation];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [CRLoom setMainThreadManagedObjectContext:[self managedObjectContext]];
    [self importData];
    
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

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
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

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CRLoomDemo" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CRLoomDemo.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
