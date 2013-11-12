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
 *  + (id)importData:(id)data
 *       intoContext:(NSManagedObjectContext*)moc
 *         withCache:(NSCache*)cache
 *  guaranteedInsert:(BOOL)guaranteedInsert
 *   saveOnBatchSize:(NSUInteger)batchSize
 *             error:(NSError**)error
 *
 *  This is the method through which NSManagedObject's can be created and updated.
 */

SEL NSManagedObjectImportSelector();
SEL NSManagedObjectImportSelector() {
    SEL importSelector = sel_registerName("importData:intoContext:withCache:guaranteedInsert:saveOnBatchSize:error:");
    return importSelector;
}

@interface NSManagedObjectImportOperation ()
@property (nonatomic, assign) BOOL guaranteedInsert;
@property (nonatomic, retain) NSManagedObjectContext *moc;
@property (nonatomic, retain) NSArray *data;
@property (nonatomic, assign) Class targetClass;
@property (nonatomic, assign) NSUInteger batchSize;
@property (nonatomic, assign) BOOL useCache;
@property (nonatomic, retain) NSError *error;
@end

@implementation NSManagedObjectImportOperation

+ (id)operationWithData:(id)data
     managedObjectClass:(Class)class
       guaranteedInsert:(BOOL)guaranteedInsert
        saveOnBatchSize:(NSUInteger)batchSize
               useCache:(BOOL)useCache
                  error:(NSError**)error {
    NSManagedObjectImportOperation *op = [[self alloc] initWithData:data
                                                 managedObjectClass:class
                                                   guaranteedInsert:guaranteedInsert
                                                    saveOnBatchSize:batchSize
                                                           useCache:useCache
                                                              error:error];
    return op;
}

- (id)initWithData:(NSArray*)data
managedObjectClass:(Class)class
  guaranteedInsert:(BOOL)guaranteedInsert
   saveOnBatchSize:(NSUInteger)batchSize
          useCache:(BOOL)useCache
             error:(NSError**)error {
    self = [super init];
    if (self) {
        self.data = data;
        self.targetClass = class;
        self.guaranteedInsert = guaranteedInsert;
        self.batchSize = batchSize;
        self.useCache = useCache;
        self.error = *error;
    }
    return self;
}

- (void)main {
    self.moc = [CRLoom privateContext];
    self.moc.undoManager = nil;
    __block NSManagedObjectImportOperation *blockSelf = self;
    [self.moc performBlockAndWait:^{
        [blockSelf import];
    }];
}

- (void)import {
    SEL importSelector = NSManagedObjectImportSelector();
    if (class_getClassMethod(self.targetClass, importSelector) != NULL) {
        NSCache *cache = self.useCache ? [[NSCache alloc] init] : nil ;
        objc_msgSend(self.targetClass, importSelector, self.data, self.moc, cache, self.guaranteedInsert, self.batchSize, &_error);
    } else {
        NSAssert(NO, @"The object of type %@ supplied to NSManagedObjectImportOperation doesn't respond to %@", NSStringFromClass(self.targetClass), NSStringFromSelector(importSelector));
    }
}

@end
