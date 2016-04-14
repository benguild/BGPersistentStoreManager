//
//  BGPersistentStoreManager.m
//  BGPersistentStoreManager
//
//  Created by Ben Guild on 7/16/15.
//  Copyright (c) 2015 Ben Guild. All rights reserved.
//

#import "BGPersistentStoreManager.h"

#import "NSManagedObjectModel+KCOrderedAccessorFix.h"


@interface BGPersistentStoreManager ()

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContextInternal;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;


@end


@implementation BGPersistentStoreManager

+ (BGPersistentStoreManager *)sharedManager
{
    static BGPersistentStoreManager *sharedManager=nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedManager=[[self alloc] init];
        
    } );
    ////
    
    return sharedManager;
    
}

- (id)init
{
    if (self=[super init])
    {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note)
        {
            [self saveContextAndCleanUpOldObjects:YES];
            
        } ];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:nil usingBlock:^(NSNotification *note)
        {
            // NOTE: This is not guaranteed to be called, but is here in case the app does not support backgrounding... etc.
            
            [self saveContextAndCleanUpOldObjects:YES];
            
        } ];
        ////
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:nil queue:nil usingBlock:^(NSNotification *note)
        {
            if (![[note object] isKindOfClass:[NSManagedObjectContext class]])
            {
                return;
                
            }
            
            NSManagedObjectContext *context=[note object];
            
            if ([[context parentContext] persistentStoreCoordinator] && [[context parentContext] persistentStoreCoordinator]!=_persistentStoreCoordinator) // NOTE: This will perform merges multiple times through the application if there are multiple cases. Not sure if this matters, as they'll only merge into the final context if the `persistentStoreCoordinator` is a match?
            {
                return;
                
            }
            ////
            
            [[context parentContext] performBlock:^
            {
                [[context parentContext] mergeChangesFromContextDidSaveNotification:note];
                ////
                
                #if TARGET_IPHONE_SIMULATOR // For easier debugging, save more often.
                NSError *error;
                
                if ([[context parentContext] hasChanges] && ![[context parentContext] save:&error])
                {
                    NSLog(@"Error saving main context during merge operation: %@, %@", [error localizedDescription], [error userInfo]);
                    
                }
                #endif
                
            } ];
            
        } ];
        
    }
    
    return self;
    
}

- (NSManagedObjectContext *)managedObjectContext
{
	if (_managedObjectContextInternal)
    {
        return _managedObjectContextInternal;
        
    }
	
    if (![[NSThread currentThread] isMainThread])
    {
        dispatch_sync(dispatch_get_main_queue(), ^
        {
            (void)[self managedObjectContext];
            
        } );
        
        return _managedObjectContextInternal;
        
    }
    ////
    
    NSPersistentStoreCoordinator *coordinator=[self persistentStoreCoordinator];
    
    if (coordinator)
    {
        _managedObjectContextInternal=[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContextInternal setPersistentStoreCoordinator:coordinator];
        // [_managedObjectContextInternal setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        // [_managedObjectContextInternal setStalenessInterval:0];
        
    }
    
    return _managedObjectContextInternal;
    
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel)
    {
        return _managedObjectModel;
        
    }
    ////
    
    _managedObjectModel=[NSManagedObjectModel mergedModelFromBundles:nil];
    [_managedObjectModel kc_generateOrderedSetAccessors];
    
    return _managedObjectModel;
    
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator)
    {
        return _persistentStoreCoordinator;
        
    }
    
    if (![[NSThread currentThread] isMainThread])
    {
        dispatch_sync(dispatch_get_main_queue(), ^
        {
            (void)[self persistentStoreCoordinator];
            
        } );
        
        return _persistentStoreCoordinator;
        
    }
    ////
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
    NSString *dataStoreFilename=@"LocalData.sqlite";
    
    NSURL *dataStoreURL=[[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:dataStoreFilename];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[dataStoreURL path]])
    {
        _dataStoreWasResetOrCreatedOnLoad=YES;
        
    }
    
    NSArray *dataStoreAuxiliaryFiles=@[[[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@-shm", dataStoreFilename]], [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@-wal", dataStoreFilename]]];
    
    for (NSUInteger i=0; i<2; i++)
    {
        NSError *error;
        
        persistentStoreCoordinator=[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        ////
        
        if ([persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:dataStoreURL options:@{ NSMigratePersistentStoresAutomaticallyOption:@(YES), NSInferMappingModelAutomaticallyOption:@(YES) } error:&error] && !error)
        {
            break;
            
        }
        else
        {
            NSLog(@"Unresolved Core Data error on launch, resetting local database: %@, %@", error, [error userInfo]);
            
            if ([[persistentStoreCoordinator persistentStores] count])
            {
                [persistentStoreCoordinator removePersistentStore:[[persistentStoreCoordinator persistentStores] objectAtIndex:0] error:nil];
                
            }
            
            if ([persistentStoreCoordinator respondsToSelector:@selector(destroyPersistentStoreAtURL:withType:options:error:)])
            {
                [persistentStoreCoordinator destroyPersistentStoreAtURL:dataStoreURL withType:NSSQLiteStoreType options:nil error:nil];
            
            }
            
            persistentStoreCoordinator=nil;
            _dataStoreWasResetOrCreatedOnLoad=YES;
            
        }
        
    }
    ////
    
    [dataStoreURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
    
    for (NSURL *dataStoreAuxiliaryFileURL in dataStoreAuxiliaryFiles)
    {
        [dataStoreAuxiliaryFileURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        
    }
    ////
    
    _persistentStoreCoordinator=persistentStoreCoordinator;
    
    return _persistentStoreCoordinator;
    
}

- (void)saveContextAndCleanUpOldObjects:(BOOL)cleanUpOldObjects
{
    NSError *error;
    
    for (NSUInteger i=0; i<=1; i++)
    {
        if ([self managedObjectContext] && [[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error])
        {
            NSLog(@"Unresolved Core Data error on save: %@, %@", error, [error userInfo]);
            
            [self handleSaveError:error];
            
            return;
            
        }
        ////
        
        if (!i && cleanUpOldObjects) // Even if there's an error above, try again anyway post cleanup. Could have been diskspace related? Maybe?
        {
            [self cleanUpOldObjects];
            
        }
        
    }
    
}

- (void)handleSaveError:(NSError *)error
{
    // Do nothing. Subclassable!
    
}

- (void)cleanUpOldObjects
{
    // Do nothing. Subclassable!
    
}

- (NSError *)performBlockOnChildContext:(void (^)(NSManagedObjectContext *context, NSString *loggingDescriptor))block withLoggingDescriptor:(NSString *)loggingDescriptor
{
    NSManagedObjectContext *context=[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setUndoManager:nil];
    [context setParentContext:[self managedObjectContext]];
    
    [[context parentContext] performBlockAndWait:^ // This is one of those quirky fixes for Core Data.
    {
        [[context parentContext] setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        
    } ];
    ////
    
    block(context, loggingDescriptor);
    ////
    
    NSError *error;
    
    if ([context hasChanges] && ![context save:&error])
    {
        NSLog(@"Error saving context during %@: %@, %@", loggingDescriptor, [error localizedDescription], [error userInfo]);
        
        return error;
        
    }
    ////
    
    return nil;
    
}

@end
