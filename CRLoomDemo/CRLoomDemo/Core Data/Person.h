//
//  Person.h
//  CRLoomDemo
//
//  Created by Collin Ruffenach on 11/11/13.
//  Copyright (c) 2013 Notion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Job.h"

@interface Person : NSManagedObject

@property (nonatomic, retain) NSNumber * age;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * uuid;
@property (nonatomic, retain) Job *job;

@end
