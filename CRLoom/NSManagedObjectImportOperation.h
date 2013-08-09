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
      managedModelClass:(Class)class
       guaranteedInsert:(BOOL)guaranteedInsert
       saveOnCompletion:(BOOL)saveOnCompletion
               useCache:(BOOL)useCache
                  error:(NSError**)error;

@end