//
//  NSManagedObjectImportOperation.m
//  CRCoreDataThreading
//
//  Created by Collin Ruffenach on 7/18/13.
//
//

#import "NSManagedObjectImportOperation.h"
#import "NSManagedObject+CRLoom.h"
#import "CRLoom.h"
#import <objc/message.h>

/**
 *  NSManagedObject implements.
 *
 *  + (NSArray*)importData:(id)data
 *             intoContext:(NSManagedObjectContext*)moc
 *               withCache:(NSCache*)cache
 *        guaranteedInsert:(BOOL)guaranteedInsert
 *         saveOnBatchSize:(NSUInteger)batchSize
 *    pruneExistingObjects:(BOOL)pruneExistingObjects
 *                   error:(NSError* __autoreleasing *)error
 *
 *  This is the method through which NSManagedObject's can be created and updated.
 */

SEL NSManagedObjectImportSelector();
SEL NSManagedObjectImportSelector() {
    return sel_registerName("importData:intoContext:withCache:guaranteedInsert:saveOnBatchSize:pruneExistingObjects:error:");
}

@interface NSManagedObjectImportOperation ()
@property (nonatomic, assign) BOOL guaranteedInsert;
@property (nonatomic, strong) NSManagedObjectContext *moc;
@property (nonatomic, strong) NSArray *data;
@property (nonatomic, assign) Class targetClass;
@property (nonatomic, assign) NSUInteger batchSize;
@property (nonatomic, assign) BOOL pruneMissingObjects;
@property (nonatomic, assign) BOOL useCache;
@property (nonatomic, assign) NSError* __autoreleasing *error;
@end

@implementation NSManagedObjectImportOperation

+ (instancetype)operationWithData:(id)data
               managedObjectClass:(Class)class
                 guaranteedInsert:(BOOL)guaranteedInsert
                  saveOnBatchSize:(NSUInteger)batchSize
              pruneMissingObjects:(BOOL)pruneMissingObjects
                         useCache:(BOOL)useCache
                            error:(NSError* __autoreleasing *)error{
    NSManagedObjectImportOperation *op = [[self alloc] initWithData:data
                                                 managedObjectClass:class
                                                   guaranteedInsert:guaranteedInsert
                                                    saveOnBatchSize:batchSize
                                                pruneMissingObjects:pruneMissingObjects
                                                           useCache:useCache
                                                              error:error];
    return op;
}

- (instancetype)initWithData:(NSArray*)data
          managedObjectClass:(Class)class
            guaranteedInsert:(BOOL)guaranteedInsert
             saveOnBatchSize:(NSUInteger)batchSize
         pruneMissingObjects:(BOOL)pruneMissingObjects
                    useCache:(BOOL)useCache
                       error:(NSError* __autoreleasing *)error {
    self = [super init];
    if (self) {
        self.data = data;
        self.targetClass = class;
        self.guaranteedInsert = guaranteedInsert;
        self.batchSize = batchSize;
        self.pruneMissingObjects = pruneMissingObjects;
        self.useCache = useCache;
        self.error = error;
    }
    return self;
}

- (void)dealloc {
    self.moc = nil;
    self.data = nil;
}

- (void)main {
    __block NSManagedObjectImportOperation *blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        if (![[CRLoom mainThreadContext] save:&error]) {
            NSLog(@"[CRLOOM] ERROR SAVING MAIN THEAD MANAGED OBJECT CONTEXT BEFORE IMPORTING DATA FOR CLASS %@", NSStringFromClass(blockSelf.targetClass));
        }
    });
    
    self.moc = [CRLoom privateContext];
    self.moc.undoManager = nil;
    [self.moc performBlockAndWait:^{
        [blockSelf import];
    }];
}

- (void)import {
    SEL importSelector = NSManagedObjectImportSelector();
    if (class_getClassMethod(self.targetClass, importSelector) != NULL) {
        NSCache *cache = self.useCache ? [[NSCache alloc] init] : nil ;
        [self.targetClass importData:self.data
                         intoContext:self.moc
                           withCache:cache
                    guaranteedInsert:self.guaranteedInsert
                     saveOnBatchSize:self.batchSize
                pruneExistingObjects:self.pruneMissingObjects
                               error:self.error];
    } else {
        NSAssert(NO, @"The object of type %@ supplied to NSManagedObjectImportOperation doesn't respond to %@", NSStringFromClass(self.targetClass), NSStringFromSelector(importSelector));
    }
}

@end