//
//  NSManagedObjectImportOperation.h
//  CRCoreDataThreading
//
//  Created by Collin Ruffenach on 7/18/13.
//
//

#import <Foundation/Foundation.h>

@interface NSManagedObjectImportOperation : NSOperation

+ (instancetype)operationWithData:(id)data
     managedObjectClass:(Class)class
       guaranteedInsert:(BOOL)guaranteedInsert
        saveOnBatchSize:(NSUInteger)batchSize
    pruneMissingObjects:(BOOL)pruneMissingObjects
               useCache:(BOOL)useCache
                  error:(NSError* __autoreleasing *)error;

@end