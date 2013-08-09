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
 *  saveOnCompletion:(BOOL)saveOnCompletion
 *             error:(NSError**)error
 *
 *  This is the method through which NSManagedObject's can be created and updated.
 */

SEL NSManagedObjectImportSelector();
SEL NSManagedObjectImportSelector() {
    SEL importSelector = sel_registerName("importData:intoContext:withCache:guaranteedInsert:saveOnCompletion:error:");
    return importSelector;
}

@interface NSManagedObjectImportOperation ()
@property (nonatomic, assign) BOOL guaranteedInsert;
@property (nonatomic, retain) NSManagedObjectContext *moc;
@property (nonatomic, retain) NSArray *data;
@property (nonatomic, assign) Class targetClass;
@property (nonatomic, assign) BOOL saveOnCompletion;
@property (nonatomic, assign) BOOL useCache;
@property (nonatomic, retain) NSError *error;
@end

@implementation NSManagedObjectImportOperation

+ (id)operationWithData:(id)data
      managedModelClass:(Class)class
       guaranteedInsert:(BOOL)guaranteedInsert
       saveOnCompletion:(BOOL)saveOnCompletion
               useCache:(BOOL)useCache
                  error:(NSError**)error {
    NSManagedObjectImportOperation *op = [[self alloc] initWithData:data
                                                  managedModelClass:class
                                                   guaranteedInsert:guaranteedInsert
                                                   saveOnCompletion:saveOnCompletion
                                                           useCache:useCache
                                                              error:error];
    return op;
}

- (id)initWithData:(NSArray*)data
 managedModelClass:(Class)class
  guaranteedInsert:(BOOL)guaranteedInsert
  saveOnCompletion:(BOOL)saveOnCompletion
          useCache:(BOOL)useCache
             error:(NSError**)error {
    self = [super init];
    if (self) {
        self.data = data;
        self.targetClass = class;
        self.guaranteedInsert = guaranteedInsert;
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
        objc_msgSend(self.targetClass, importSelector, self.data, self.moc, cache, self.guaranteedInsert, YES, &_error);
    } else {
        NSAssert(NO, @"The object of type %@ supplied to NSManagedObjectImportOperation doesn't respond to %@", NSStringFromClass(self.targetClass), NSStringFromSelector(importSelector));
    }
}

@end
