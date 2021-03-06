# BGPersistentStoreManager

**[Core Data](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/index.html)** for Apple’s iOS/macOS/watchOS/etc. has many great uses, but requires some initial setup, configuration, and understanding to create/save/merge persistent data stores.

In this pod, Core Data is automatically configured as a singleton, providing both access to its main context (when reading/writing on the main thread) and also conveniently on child contexts through a helper “block” function. The helper block for child contexts (primarily for use from non-main threads) automatically runs on the thread on which its called, so you can run it on any thread including the current one.

**This pod will create a database in the “Caches” folder for the app, because Core Data is subject to occasional glitches, migration errors, and corruption.** The state of `BOOL` property `dataStoreWasResetOrCreatedOnLoad` will be retained for the life of the session to suggest that any desired permanent local data should be restored from another source during that session. In many (if not most) circumstances, Core Data should be treated only as temporary local data persistence for convenience, speed/optimization, and offline functionality, due to the chance of data loss from user device corruption, low disk space, and other edge-case scenarios. This structure enforces that philosophy.

The persistent store will be saved to disk **automatically** when the app enters the background or is terminated by the user.

[![Version](https://img.shields.io/cocoapods/v/BGPersistentStoreManager.svg?style=flat)](http://cocoapods.org/pods/BGPersistentStoreManager)
[![License](https://img.shields.io/cocoapods/l/BGPersistentStoreManager.svg?style=flat)](http://cocoapods.org/pods/BGPersistentStoreManager)
[![Platform](https://img.shields.io/cocoapods/p/BGPersistentStoreManager.svg?style=flat)](http://cocoapods.org/pods/BGPersistentStoreManager)

## Usage

To initiate the managed object context, initiate the singleton:

```objc
[BGPersistentStoreManager sharedManager];
```

The `managedObjectContext` can be accessed from the main thread, like so:

```objc
[[BGPersistentStoreManager sharedManager] managedObjectContext];
```

Because Core Data is not thread-safe, use this block function to create and merge a child context when fetching or making changes from a non-main thread:

```objc
[[BGPersistentStoreManager sharedManager] performBlockOnChildContext:^(NSManagedObjectContext *context,
                                                                       NSString *loggingDescriptor) {
    // Your code goes here to fetch/insert/whatever you want. Use this "context" variable instead
	//  of the "managedObjectContext" property of the singleton.
                                                                       }
                                               withLoggingDescriptor:@"the fetching of objects"];
```

... The `loggingDescriptor` is also passed to the block for convenience, but is primarily used for describing any errors that occur during the subsequent merge of the child context using a noun-style phrase, such as "the fetching of photo objects", etc.

**Other useful tips:**
* If your database becomes corrupt or unusable, ***it will automatically be deleted from disk*** and recreated fresh and empty using the latest model version. The `dataStoreWasResetOrCreatedOnLoad` property of the singleton will be set to **`true`** in this case.
* You may subclass the singleton and take advantage of implementing its `cleanUpOldObjects:` method. This method is called (on the main thread) whenever the main context was just saved successfully (on backgrounding of the app or the app's termination by the user). The context will then again re-save just after this method finishes, but only if there were any changes made since the first save occurred.
* You may also optionally subclass its `handleSaveError:` method, which is passed any error(s) that occur during the saving of the main context. You may choose to throw an exception here, reset the context or persistent store entirely, and/or log to a remote logging service. *(for example)*


## Installation

`BGPersistentStoreManager` is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "BGPersistentStoreManager"
```


## Dependencies

This Cocoa Pod bundles and depends on `KCOrderedAccessorFix` to fix "'CoreDataGeneratedAccessors' for ordered, to-many relationships" automatically.

More information can be found here: https://github.com/CFKevinRef/KCOrderedAccessorFix


## Author

Ben Guild, hello@benguild.com

## License

`BGPersistentStoreManager` is available under the MIT license. See the LICENSE file for more info.
