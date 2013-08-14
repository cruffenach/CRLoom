//
//  NSManagedObject+CRLoom.h
//  CRCoreDataThreading
//
//  Created by Collin Ruffenach on 7/18/13.
//
//

#import <CoreData/CoreData.h>

@protocol CRLoomImport <NSObject>

/**
 The key the data uses as the unique identifier for the model
 @return The key the API uses for this model's unique identifier
 */

+ (NSString*)uniqueDataIdentifierKey;

/**
 The key the NSManagedObject use as the unique identifier for the model
 @return The key the model uses for its unique identifier
 */

+ (NSString*)uniqueModelIdentifierKey;

/**
 Updates an NSManagedObject subclass with data
 @param data The data to hydate the NSManagedObject with
 @param moc The Managed Object Context the work should be done in
 @param error An error pointer that will be returned hydrated if there is any problem
 occurs while updating the NSManagedObject's relationships
 @return A BOOL that will be YES upon success and NO upon receiving an error
 */

- (BOOL)updateWithData:(NSDictionary*)data
           intoContext:(NSManagedObjectContext*)moc
             withCache:(NSCache*)cache
                 error:(NSError**)error;

/**
 Returns YES if the dictionary representing this object has identical data to the NSManagedObject it represents
 @param data The data to check the NSManagedObject against
 @return A BOOL that will be YES if the objects are identical, no otherwise
 */

- (BOOL)isIdenticalToData:(NSDictionary*)data;

@optional

/**
 Provides the predicate for this class given an identifier value
 @param identifierValue The uniqueIdentifierValue for the object
 @return A predicate that can be used on objects of this type that maps the identifier value to an instance
 */

+ (NSPredicate*)predicateWithIdentiferValue:(id)identifierValue;

/**
 Provides the predicate for this class given an identifier collection
 @param identifierCollection A collection of identifer values for this object
 @return A predicate that can be used on this collection to identify instances of this object from the collection
 */

+ (NSPredicate*)predicateWithIdentiferCollection:(NSArray*)identifierCollection;

@end

@interface NSManagedObject (CRLoom) <CRLoomImport>

/**
 Imports data for the NSManagedObject subclass into the managed object context provided.
 Can optionally update/create.
 @param data The data to be synthesized into NSManagedObjects. The data should be either
 an array of dictionaries for a collection of objects, or a single dictionary for a
 single object
 @param moc The Managed Object Context the work should be done in
 @param cache An optional cache a caller can provide that will be used as a first layer
 before performing a full fetch request to find an existing object
 @param guaranteedInsert A flag to optionally directly create these as new objects and
 skip the work of checking for an existing instance to update
 @param batchSize The numbers of objects processed that should trigger a save to the 
 managed object context. A value of 0 will have no save occur, a value of NSUIntegerMax
 will have 1 save occur after processing all objects.
 @param error An error pointer that will be returned hydrated if there is any problem
 @return An array of the objects created
 */

+ (NSArray*)importData:(id)data
           intoContext:(NSManagedObjectContext*)moc
             withCache:(NSCache*)cache
      guaranteedInsert:(BOOL)guaranteedInsert
       saveOnBatchSize:(NSUInteger)batchSize
                 error:(NSError**)error;

/**
 Finds an existing object for this class with the provided identifier value
 @param value The uniqueIdentifierValue for the object
 @param moc The Managed Object Context the work should be done in
 @param error An error pointer that will be returned hydrated if there is any problem
 @param cache An optional cache that will be used as the first place checked for the
 existing object
 @return The object of this type with the provided identifier value if it exists or nil
 */

+ (instancetype)existingObjectWithIdentifierValue:(id)value
                                        inContext:(NSManagedObjectContext*)moc
                                        withCache:(NSCache*)cache
                                            error:(NSError**)error;

/**
 Finds an existing object for this class with the provided identifier value
 @param identifierCollection An array of unique identifier values for this object type
 @param moc The Managed Object Context the work should be done in
 @param error An error pointer that will be returned hydrated if there is any problem
 @param cache An optional cache that will be used as the first place checked for existing
 objects.
 @return The object of this type with the provided identifier value if it exists or nil
 */

+ (NSArray*)existingObjectsWithIdentifierCollection:(NSArray*)identifierCollection
                                          inContext:(NSManagedObjectContext*)moc
                                          withCache:(NSCache*)cache
                                              error:(NSError**)error;

@end