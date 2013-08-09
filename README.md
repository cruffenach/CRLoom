## CRLoom

CRLoom is a framework for helping with the import, update and querying of `NSManagedObject`'s

## Overview

### `NSManagedObjectImportOperation`
This is an `NSOperation` subclass that created via
```Objective-C
+ (id)operationWithData:(id)data
      managedModelClass:(Class)class
       guaranteedInsert:(BOOL)guaranteedInsert
       saveOnCompletion:(BOOL)saveOnCompletion
               useCache:(BOOL)useCache
                  error:(NSError**)error;
```
This operation can be added to an `NSOperationQueue` and will thread the work of importing the data. Setting `useCache` to `YES` will have the operation provide an `NSCache` to the thread doing the import work that will be used as a first layer to check to find existing objects before entire fetch requests are used.

### `NSManagedObject+CRLoom`
This is a category that provides a generic implementation for importing and finding `NSManagedObject`'s. The import and search methods take an `NSManagedObjectContext` as a parameter so they can work on different threads.

#### Importing Data

```Objective-C
+ (NSArray*)importData:(id)data
           intoContext:(NSManagedObjectContext*)moc
             withCache:(NSCache*)cache
      guaranteedInsert:(BOOL)guaranteedInsert
      saveOnCompletion:(BOOL)saveOnCompletion
                 error:(NSError**)error;
```

A cache can be provided to be used as a first check place for existing objects when processing this data into `NSManagedObject`'s. Providing a cache here will ensure that those shared objects when created or retrieved for the first time will be held in a cache to reduce the total amount of fetch requests made.

#### Finding Objects

```Objective-C
+ (instancetype)existingObjectWithIdentifierValue:(id)value
                                        inContext:(NSManagedObjectContext*)moc
                                        withCache:(NSCache*)cache
                                            error:(NSError**)error;
```     
### `<CRLoomImport>`
                                                        
For these methods to work for a given `NSManagedObject` subclass must implement a few methods. The methods that need to be implemented provided by the `<CRLoomImport>` protocol.

#### Identifiers

A method that returns the model (Core Data) key that represents the object's unique identifier
```Objective-C
+ (NSString*)uniqueModelIdentifierKey;
```
A method that returns the data (Simple API) key that represents the object's unique identifier
```Objective-C
+ (NSString*)uniqueDataIdentifierKey;
```
#### Object Updating
A method to update the object with data from the api. This allows work to be done on any given context should ensure error delivery, the cache will be used as a first layer for getting existing relationship objects before a full fetch request to core data is done.
```Objective-C
- (BOOL)updateWithData:(NSDictionary*)data
           intoContext:(NSManagedObjectContext*)moc
             withCache:(NSCache*)cache
                 error:(NSError**)error;
````

A method to indicate whether a model's data is identical to an `NSDictionary` representation of that object.
```Objective-C
- (BOOL)isIdenticalToData:(NSDictionary*)data;
```
#### Optional individual and collection predicates
An `NSManagedObject` subclass can also optionally implement methods to return the `NSPredicate` that should be used to "match" objects.
```Objective-C
+ (NSPredicate*)predicateWithIdentiferValue:(id)identifierValue;
+ (NSPredicate*)predicateWithIdentiferCollection:(NSArray*)identifierCollection;
```
