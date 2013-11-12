//
//  Job+Import.m
//  CRLoomDemo
//
//  Created by Collin Ruffenach on 11/11/13.
//  Copyright (c) 2013 Notion. All rights reserved.
//

#import "Job+Import.h"

@implementation Job (Import)

+ (NSString*)uniqueDataIdentifierKey {
    return @"id";
}

+ (NSString*)uniqueModelIdentifierKey {
    return @"uuid";
}

- (BOOL)isIdenticalToData:(NSDictionary*)data {
    return (self.uuid.integerValue == [data[[Job uniqueDataIdentifierKey]] integerValue] &&
            [self.name isEqualToString:data[@"name"]]);
}

- (BOOL)updateWithData:(NSDictionary *)data
           intoContext:(NSManagedObjectContext *)moc
             withCache:(NSCache *)cache
                 error:(NSError **)error {
    self.uuid = data[[Job uniqueDataIdentifierKey]];
    self.name = data[@"name"];
    return YES;
}


@end