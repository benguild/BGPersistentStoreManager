//
//  BGPersistentStoreManager.h
//  BGPersistentStoreManager
//
//  Created by Ben Guild on 7/16/15.
//  Copyright (c) 2015 Ben Guild. All rights reserved.
//

#import <Foundation/Foundation.h>


@import CoreData;


@interface BGPersistentStoreManager : NSObject

@property (readonly, assign, nonatomic) BOOL dataStoreWasResetOrCreatedOnLoad;

+ (BGPersistentStoreManager *)sharedManager;

- (NSManagedObjectContext *)managedObjectContext;

- (void)handleSaveError:(NSError *)error; // This method can be subclassed.
- (void)cleanUpOldObjects; // This method can be subclassed to clean up old objects on save.

- (NSError *)performBlockOnChildContext:(void (^)(NSManagedObjectContext *context, NSString *loggingDescriptor))block withLoggingDescriptor:(NSString *)loggingDescriptor;


@end
