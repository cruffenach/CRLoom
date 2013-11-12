//
//  Job.h
//  CRLoomDemo
//
//  Created by Collin Ruffenach on 11/11/13.
//  Copyright (c) 2013 Notion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Person;

@interface Job : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * uuid;
@property (nonatomic, retain) NSSet *people;
@end

@interface Job (CoreDataGeneratedAccessors)

- (void)addPeopleObject:(Person *)value;
- (void)removePeopleObject:(Person *)value;
- (void)addPeople:(NSSet *)values;
- (void)removePeople:(NSSet *)values;

@end
