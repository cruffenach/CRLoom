//
//  NSManagedObjectImportOperation.h
//  CRCoreDataThreading
//
//  Created by Collin Ruffenach on 7/18/13.
//
//

#import <Foundation/Foundation.h>

@interface NSManagedObjectImportOperation : NSOperation

+ (id)operationWithData:(id)data
     managedObjectClass:(Class)class
       guaranteedInsert:(BOOL)guaranteedInsert
        saveOnBatchSize:(NSUInteger)batchSize
               useCache:(BOOL)useCache
                  error:(NSError* __autoreleasing *)error;

@end