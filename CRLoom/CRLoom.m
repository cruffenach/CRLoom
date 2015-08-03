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
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = [self mainThreadContext];
    return privateContext;
}

- (void)dealloc {
    self.moc = nil;
}

@end