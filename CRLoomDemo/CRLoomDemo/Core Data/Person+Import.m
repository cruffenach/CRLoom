//
//  Person+Import.m
//  CRCoreDataThreader-iOS-Demo
//
//  Created by Collin Ruffenach on 7/18/13.
//
//

#import "Person+Import.h"

@implementation Person (Import)

+ (NSString*)uniqueDataIdentifierKey {
    return @"id";
}

+ (NSString*)uniqueModelIdentifierKey {
    return @"uuid";
}

- (BOOL)isIdenticalToData:(NSDictionary*)data {
    return (self.uuid.integerValue == [data[[Person uniqueDataIdentifierKey]] integerValue] &&
            [self.name isEqualToString:data[@"name"]]                                       &&
            [self.job isEqualToString:data[@"job"]]                                         &&
            self.age.integerValue == [data[@"age"] integerValue]);
}

- (BOOL)updateWithData:(NSDictionary *)data
           intoContext:(NSManagedObjectContext *)moc
             withCache:(NSCache *)cache
                 error:(NSError **)error {    
    self.uuid = data[[Person uniqueDataIdentifierKey]];
    self.name = data[@"name"];
    self.job = data[@"job"];
    self.age = data[@"age"];
    return YES;
}

@end