//
//  Person.h
//  CRCoreDataThreader-iOS-Demo
//
//  Created by Collin Ruffenach on 7/18/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSManagedObject+CRLoom.h"

@class Person;

@interface Person : NSManagedObject
@property (nonatomic, retain) NSNumber * uuid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * age;
@property (nonatomic, retain) NSString * job;
@property (nonatomic, retain) NSSet *friends;
@end

@interface Person (CoreDataGeneratedAccessors)

- (void)addFriendsObject:(Person *)value;
- (void)removeFriendsObject:(Person *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

@end
