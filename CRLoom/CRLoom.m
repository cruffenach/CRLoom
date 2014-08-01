//
//  CRLoom.m
//
//
//  Created by Collin Ruffenach on 7/20/13.
//
//

#import "CRLoom.h"

#define CRLogCoreDataNote(note) NSLog(@"Inserted: %@ Modified: %@ Deleted: %@", \
@([note.userInfo[@"inserted"] count]),  \
@([note.userInfo[@"updated"] count]),   \
@([note.userInfo[@"deleted"] count]))

static NSString *const kCRLoomContextKey = @"kCRLoomContextKey";

@interface CRLoom ()
@property (nonatomic, strong) NSManagedObjectContext *moc;
@end

@implementation CRLoom

- (void)setMoc:(NSManagedObjectContext *)moc {
    _moc = moc;
    __block CRLoom *blockSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification* note) {
        
        id object = note.object;

        if ([object isKindOfClass:[NSManagedObjectContext class]]) {
         
            NSManagedObjectContext *context = (NSManagedObjectContext*)object;
            
            if ([context.userInfo[kCRLoomContextKey] boolValue] && context != [CRLoom mainThreadContext]) {
                CRLogCoreDataNote(note);
                
                //Fix for bug where NSFetchedResultsControllerDelegate's controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:
                //isn't called when updates come in from a Managed Object Context on another thread.
                //http://stackoverflow.com/questions/14018068/nsfetchedresultscontroller-doesnt-call-controllerdidchangecontent-after-update
        
                for(NSManagedObject *object in [[note userInfo] objectForKey:NSUpdatedObjectsKey]) {
                    [[blockSelf.moc objectWithID:[object objectID]] willAccessValueForKey:nil];
                }
                
                [blockSelf.moc mergeChangesFromContextDidSaveNotification:note];
            }
        }
    }];
}

+ (CRLoom*)loom {
    static dispatch_once_t once;
    static CRLoom *loom;
    dispatch_once(&once, ^ { loom = [[self alloc] init]; });
    return loom;
}

+ (void)setMainThreadManagedObjectContext:(NSManagedObjectContext*)context {
    if (context && context.concurrencyType != NSMainQueueConcurrencyType) {
        NSLog(@"Error setting context, must be context with concurrency type NSMainQueueConcurrencyType");
        return;
    }
    [[self loom] setMoc:context];
}

+ (NSManagedObjectContext*)mainThreadContext {
    return [[self loom] moc];
}

+ (NSManagedObjectContext*)privateContext {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.userInfo[kCRLoomContextKey] = @(1);
    context.persistentStoreCoordinator = [self loom].moc.persistentStoreCoordinator;
    return context;
}

- (void)dealloc {
    self.moc = nil;
}

@end