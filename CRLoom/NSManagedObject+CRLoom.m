//
//  NSManagedObject+CRLoom.m
//  CRCoreDataThreading
//
//  Created by Collin Ruffenach on 7/18/13.
//
//

#import "NSManagedObject+CRLoom.h"

#define CRAssertSubclassShouldImplementMethod() NSAssert1(false, @"%s: Error: Your subclass must implement this method", __PRETTY_FUNCTION__);

BOOL CRShouldSaveContext(NSManagedObjectContext *moc) {
    return moc.insertedObjects.count||moc.updatedObjects.count||moc.deletedObjects.count;
}
NSArray * CRIdentifierValuesFromDataWithKey(NSArray *data, NSString *identifierKey);
NSArray * CRIdentifierValuesFromDataWithKey(NSArray *data, NSString *identifierKey) {
    return [data valueForKeyPath:[NSString stringWithFormat:@"@distinctUnionOfObjects.%@", identifierKey]];
}

@implementation NSManagedObject (CRLoom)

#pragma mark - Subclass Responsibilities

+ (NSString*)uniqueDataIdentifierKey {
    CRAssertSubclassShouldImplementMethod();
    return nil;
}

+ (NSString*)uniqueModelIdentifierKey {
    CRAssertSubclassShouldImplementMethod();
    return nil;
}

- (BOOL)updateWithData:(NSDictionary*)data
           intoContext:(NSManagedObjectContext*)moc
             withCache:(NSCache*)cache
                 error:(NSError**)error {
    CRAssertSubclassShouldImplementMethod();
    return NO;
}

- (BOOL)isIdenticalToData:(NSDictionary*)data {
    CRAssertSubclassShouldImplementMethod();
    return NO;
}

#pragma mark - Cache Helpers

+ (NSString*)cacheKeyForIdentifierValue:(id)identifierValue {
    NSString *className = NSStringFromClass([self class]);
    NSString *uniqueModelIdentifierKey = [self uniqueModelIdentifierKey];
    NSString *uniqueModelIdentifierValue = [identifierValue description];
    char *buffer;
    asprintf(&buffer, "%s-%s-%s", [className UTF8String], [uniqueModelIdentifierKey UTF8String], [uniqueModelIdentifierValue UTF8String]);
    NSString *hash = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    free(buffer);
    return hash;
}

+ (id)objectFromCache:(NSCache*)cache identifierValue:(id)identifierValue {
    return [cache objectForKey:[self cacheKeyForIdentifierValue:identifierValue]];
}

+ (void)setObject:(id)object withIdentifierValue:(id)identifierValue inCache:(NSCache*)cache {
    [cache setObject:object forKey:[self cacheKeyForIdentifierValue:identifierValue]];
}

#pragma mark - Predicate Generation

+ (NSPredicate*)predicateWithIdentiferValue:(id)identifierValue {
    return [NSPredicate predicateWithFormat:@"%K == %@", [self uniqueModelIdentifierKey], identifierValue];
}

+ (NSPredicate*)predicateWithIdentiferCollection:(NSArray*)identifierCollection {
    return [NSPredicate predicateWithFormat:@"(%K IN %@)", [self uniqueModelIdentifierKey], identifierCollection];
}

#pragma mark - Fetch Request Generation

+ (NSFetchRequest*)emptyFetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self class])];
}

+ (NSFetchRequest*)fetchRequestForObjectWithIdentifierValue:(id)identifierValue
                                                  inContext:(NSManagedObjectContext*)moc {
    
    NSFetchRequest *fetchRequest = [self emptyFetchRequest];
    [fetchRequest setPredicate:[self predicateWithIdentiferValue:identifierValue]];
    fetchRequest.fetchLimit = 1;
    return fetchRequest;
}

+ (NSFetchRequest*)fetchRequestForObjectsWithIdentifierCollection:(NSArray*)identifierCollection
                                                        inContext:(NSManagedObjectContext*)moc {
    
    NSFetchRequest *fetchRequest = [self emptyFetchRequest];
    [fetchRequest setPredicate:[self predicateWithIdentiferCollection:identifierCollection]];
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:[self uniqueModelIdentifierKey] ascending:YES]]];
    return fetchRequest;
}

#pragma mark - Fetch Existing Objects

+ (id)findObjectWithData:(NSDictionary*)data
               inContext:(NSManagedObjectContext*)moc
               withCache:(NSCache*)cache
                   error:(NSError* __autoreleasing *)error {
    id identifierValue = data[[self uniqueDataIdentifierKey]];
    id object = [self objectFromCache:cache identifierValue:identifierValue];
    if (!object) {
        NSFetchRequest *fetchRequest = [self fetchRequestForObjectWithIdentifierValue:identifierValue
                                                                            inContext:moc];
        object = [[moc executeFetchRequest:fetchRequest error:error] lastObject];
        if (object) {
            [self setObject:object withIdentifierValue:identifierValue inCache:cache];
        }
    }
    return object;
}

+ (NSArray*)findObjectsInIdentifierCollection:(NSArray*)identifierCollection
                                    inContext:(NSManagedObjectContext*)moc
                                    withCache:(NSCache*)cache
                                        error:(NSError* __autoreleasing *)error {
    NSMutableArray *identifiers = [NSMutableArray arrayWithArray:identifierCollection];
    NSMutableArray *objects = [NSMutableArray array];
    for (id identifierValue in identifierCollection) {
        id object = [self objectFromCache:cache identifierValue:identifierValue];
        if (object) {
            [identifiers removeObject:identifierValue];
            [objects addObject:object];
        }
    }
    
    if (identifiers.count > 0) {
        NSFetchRequest *fetchRequest = [self fetchRequestForObjectsWithIdentifierCollection:[NSArray arrayWithArray:identifiers]
                                                                                  inContext:moc];
        [objects addObjectsFromArray:[moc executeFetchRequest:fetchRequest error:error]];
    }
    return objects;
}

#pragma mark - Create Objects

+ (NSManagedObject*)createObjectInContext:(NSManagedObjectContext*)moc {
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([self class])
                                         inManagedObjectContext:moc];
}

+ (NSDictionary*)createObjectsWithData:(NSArray*)data
                             inContext:(NSManagedObjectContext*)moc
                             withCache:(NSCache*)cache {
    NSArray *identifierValues = CRIdentifierValuesFromDataWithKey(data, [self uniqueDataIdentifierKey]);
    NSMutableDictionary *objects = [NSMutableDictionary dictionaryWithCapacity:identifierValues.count];
    for (NSString *identifierValue in identifierValues) {
        objects[identifierValue] = [self createObjectInContext:moc];
        [self setObject:objects[identifierValue] withIdentifierValue:identifierValue inCache:cache];
    }
    return [NSDictionary dictionaryWithDictionary:objects];
}

#pragma mark - Find or Create Objects

+ (NSManagedObject*)findOrCreateObjectWithData:(NSDictionary*)data
                                     inContext:(NSManagedObjectContext*)moc
                                     withCache:(NSCache*)cache
                                         error:(NSError* __autoreleasing *)error {
    __autoreleasing NSError *myError = nil;
    
    //I want to ensure I find out about an error that occurs in findObjectWithData:inContext:error: even if the user
    //of this API didn't privide one.
    id object = [self findObjectWithData:data inContext:moc withCache:cache error:error ?: &myError];
    
    //If a nil object was returned I want to ensure there wasn't an error searching for an existing object before
    //creating one
    if (!object && ((error && !*error) || !myError)) {
        object = [self createObjectInContext:moc];
        [self setObject:object withIdentifierValue:data[[self uniqueDataIdentifierKey]] inCache:cache];
    }
    return object;
}

+ (NSDictionary*)findOrCreateObjectsWithData:(NSArray*)data
                                   inContext:(NSManagedObjectContext*)moc
                                   withCache:(NSCache*)cache
                                       error:(NSError* __autoreleasing *)error {
    __autoreleasing NSError *myError = nil;
    NSArray *identifierValues = CRIdentifierValuesFromDataWithKey(data, [self uniqueDataIdentifierKey]);
    
    //I want to ensure I find out about an error that occurs in findObjectsInIdentifierCollection:inContext:error:
    //even if the user of this API didn't privide one.
    NSArray *existingObjects = [self findObjectsInIdentifierCollection:identifierValues
                                                             inContext:moc
                                                             withCache:cache
                                                                 error:error ?: &myError];
    
    //If a nil object was returned I want to ensure there wasn't an error searching for existing objects before
    //creating new ones
    if (!existingObjects && ((error && *error) || myError)) {
        return nil;
    }
    
    NSMutableDictionary *objects = [NSMutableDictionary dictionaryWithCapacity:identifierValues.count];
    for (NSString *identifierValue in identifierValues) {
        NSManagedObject *object = [[existingObjects filteredArrayUsingPredicate:[self predicateWithIdentiferValue:identifierValue]] lastObject];
        if (!object) {
            object = [self createObjectInContext:moc];
            [self setObject:object withIdentifierValue:identifierValue inCache:cache];
        }
        objects[identifierValue] = object;
    }
    
    return [NSDictionary dictionaryWithDictionary:objects];
}

#pragma mark - Import Objects

+ (NSManagedObject*)importObject:(NSDictionary*)data
                     intoContext:(NSManagedObjectContext*)moc
                       withCache:(NSCache*)cache
                guaranteedInsert:(BOOL)guaranteedInsert
                saveOnCompletion:(BOOL)saveOnCompletion
                           error:(NSError* __autoreleasing *)error {
    
    NSManagedObject *object = guaranteedInsert ?
    [self createObjectInContext:moc] :
    [self findOrCreateObjectWithData:data inContext:moc withCache:cache error:error];
    if (!object) {
        return nil;
    }
    if (guaranteedInsert || ![object isIdenticalToData:data]) {
        [object updateWithData:data intoContext:moc withCache:cache error:error];
    }
    return (CRShouldSaveContext(moc) && saveOnCompletion) ? [moc save:error] ? object : nil : object;
}

+ (void)prepareForImportOfData:(NSArray*)data
                   intoContext:(NSManagedObjectContext*)moc
                         error:(NSError* __autoreleasing *)error {
    NSArray *idsToImport = [data valueForKeyPath:[@"@distinctUnionOfObjects." stringByAppendingString:[self uniqueDataIdentifierKey]]];
    NSArray *existingObjects = [[moc executeFetchRequest:[self emptyFetchRequest] error:error] mutableCopy];
    [[existingObjects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return ![idsToImport containsObject:[evaluatedObject valueForKey:[self uniqueModelIdentifierKey]]];
    }]] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [moc deleteObject:obj];
    }];
}

+ (NSArray*)importDataCollection:(NSArray*)data
                     intoContext:(NSManagedObjectContext*)moc
                       withCache:(NSCache*)cache
                guaranteedInsert:(BOOL)guaranteedInsert
                 saveOnBatchSize:(NSUInteger)batchSize
            pruneExistingObjects:(BOOL)pruneExistingObjects
                           error:(NSError* __autoreleasing *)error {
    
    if (pruneExistingObjects) {
        [self prepareForImportOfData:data
                         intoContext:moc
                               error:error];
    }
    
    NSDictionary *objects = guaranteedInsert ?
    [self createObjectsWithData:data inContext:moc withCache:cache] :
    [self findOrCreateObjectsWithData:data inContext:moc withCache:cache error:error];
    
    if (!objects) {
        return nil;
    }
    
    NSMutableArray *returnObjects = [NSMutableArray arrayWithCapacity:data.count];
    NSUInteger objectsAvailableToSave = 0;
    for (NSDictionary *objectData in data) {
        NSManagedObject *object = objects[objectData[[self uniqueDataIdentifierKey]]];
        if (guaranteedInsert || ![object isIdenticalToData:objectData]) {
            if ([object updateWithData:objectData intoContext:moc withCache:cache error:error]) {
                [returnObjects addObject:object];
            } else {
                return nil;
            }
        } else {
            [returnObjects addObject:object];
        }
        objectsAvailableToSave++;
        
        if (CRShouldSaveContext(moc) && batchSize > 0 && objectsAvailableToSave == batchSize) {
            if (![moc save:error]) {
                break;
            }
            objectsAvailableToSave = 0;
        }
    }
    
    return (CRShouldSaveContext(moc) && batchSize != 0) ? [moc save:error] ? [NSArray arrayWithArray:returnObjects] : nil : [NSArray arrayWithArray:returnObjects];
}

#pragma mark - Public Interface

+ (NSArray*)importData:(id)data
           intoContext:(NSManagedObjectContext*)moc
             withCache:(NSCache*)cache
      guaranteedInsert:(BOOL)guaranteedInsert
       saveOnBatchSize:(NSUInteger)batchSize
  pruneExistingObjects:(BOOL)pruneExistingObjects
                 error:(NSError* __autoreleasing *)error {
    
    if (!data) return nil;
    
    if ([data isKindOfClass:[NSSet class]]) {
        data = [(NSSet*)data allObjects];
    }
    
    if ([data isKindOfClass:[NSArray class]]) {
        return [self importDataCollection:data
                              intoContext:moc
                                withCache:cache
                         guaranteedInsert:guaranteedInsert
                          saveOnBatchSize:batchSize
                     pruneExistingObjects:pruneExistingObjects
                                    error:error];
    } else if ([data isKindOfClass:[NSDictionary class]]) {
        id object = [self importObject:data
                           intoContext:moc
                             withCache:cache
                      guaranteedInsert:guaranteedInsert
                      saveOnCompletion:(batchSize != 0)
                                 error:error];
        return object ? @[object] : nil;
    }
    
    if (error) {
        *error = [NSError errorWithDomain:@"com.CRLoom.import"
                                     code:0
                                 userInfo:@{@"description" : [NSString stringWithFormat:@"The data you handed importData:intoContext:guaranteedInsert:saveOnBatchSize:error: was of type %@, only NSArray, NSSet and NSDictionary data is accepted", NSStringFromClass([data class])]}];
        
    }
    return nil;
}

+ (instancetype)existingObjectWithIdentifierValue:(id)value
                                        inContext:(NSManagedObjectContext*)moc
                                        withCache:(NSCache*)cache
                                            error:(NSError* __autoreleasing *)error {
    if (!value) {
        *error = [NSError errorWithDomain:@"com.CRLoom.query"
                                     code:0
                                 userInfo:@{@"description" : @"Called existingObjectWithIdentifierValue:inContext:withCache:error: with a nil value."}];
        return nil;
    }
    return [self findObjectWithData:@{[self uniqueDataIdentifierKey] : value}
                          inContext:moc
                          withCache:cache
                              error:error];
}

+ (NSArray*)existingObjectsWithIdentifierCollection:(NSArray*)identifierCollection
                                          inContext:(NSManagedObjectContext*)moc
                                          withCache:(NSCache*)cache
                                              error:(NSError* __autoreleasing *)error {
    return [self findObjectsInIdentifierCollection:identifierCollection
                                         inContext:moc
                                         withCache:cache
                                             error:error];
}

@end