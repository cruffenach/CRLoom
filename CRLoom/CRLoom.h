//
//  CRLoom.h
//  
//
//  Created by Collin Ruffenach on 7/20/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSManagedObject+CRLoom.h"
#import "NSManagedObjectImportOperation.h"

@interface CRLoom : NSObject

+ (void)setMainThreadManagedObjectContext:(NSManagedObjectContext*)context;
+ (NSManagedObjectContext*)mainThreadContext;
+ (NSManagedObjectContext*)privateContext;

@end