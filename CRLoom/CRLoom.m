//
//  CRLoom.m
//  
//
//  Created by Collin Ruffenach on 7/20/13.
//
//

#import "CRLoom.h"

#define CRLogCoreDataNote(note) NSLog(@"Inserted: %d Modified: %d Deleted: %d", \
                                        [note.userInfo[@"inserted"] count],     \
                                        [note.userInfo[@"updated"] count],      \
                                        [note.userInfo[@"deleted"] count])


@interface CRLoom ()
@property (nonatomic, strong) NSManagedObjectContext *moc;
@end

@implementation CRLoom

- (void)setMoc:(NSManagedObjectContext *)moc {
    _moc = moc;
    __block CRLoom *blockSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* note) {
                                                      CRLogCoreDataNote(note);
                                                      [blockSelf.moc mergeChangesFromContextDidSaveNotification:note];
                                                  }];
}

+ (CRLoom*)loom {
    static dispatch_once_t once;
    static CRLoom *loom;
    dispatch_once(&once, ^ { loom = [[self alloc] init]; });
    return loom;
}

+ (void)setMainThreadManagedObjectContext:(NSManagedObjectContext*)context {
    if (context.concurrencyType != NSMainQueueConcurrencyType) {
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
    context.persistentStoreCoordinator = [self loom].moc.persistentStoreCoordinator;
    return context;
}

@end