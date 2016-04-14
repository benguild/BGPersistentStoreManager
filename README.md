# BGPersistentStoreManager

Core Data for Apple’s iOS/macOS has many great uses, but requires some initial setup, configuration, and understanding to create/save/merge persistent data stores.

In this pod, Core Data is automatically configured as a singleton, providing both access to its main context (when reading/writing on the main thread) and also conveniently on child contexts through a helper “block” function. The helper block for child contexts automatically runs on the thread on which its called, so you can run it on any thread including the current one.

**This pod will create a database in the “Cache” folder for the app, because Core Data is subject to occasional glitches, migration errors, and corruption.** A BOOL property “didRecreateDatabase” will be retained for the life of the session to suggest that any desired permanent data be restored from another source during that session. In many (if not most) circumstances, Core Data should be treated only as temporary local data for convenience, speed, and offline functionality, due to the chance of data loss. This structure enforces that philosophy.

The persistent store will save **automatically** when the app enters the background or is terminated.

## Usage

To initiate the managed object context, initiate the singleton:

```objc
[BGPersistentStoreManager sharedManager];

```

The `managedObjectContext` can be accessed from the main thread, like so:

```objc
[[BGPersistentStoreManager sharedManager] managedObjectContext]

```

Because Core Data is not thread-safe, use this block function to create and merge a child context when fetching or making changes from a non-main thread:

```objc
[[BGPersistentStoreManager sharedManager] performBlockOnChildContext:(void (^)(NSManagedObjectContext *context, NSString *loggingDescriptor))block withLoggingDescriptor:(NSString *)loggingDescriptor];

```

... The "loggingDescriptor" is passed to the block, and used for describing errors in a noun format, such as "fetch of photo objects".

Other useful tips:
* If your database becomes corrupt, **it will automatically be deleted from disk** and recreated fresh. The `dataStoreWasResetOrCreatedOnLoad` property of the singleton will be TRUE in this case.
* You may subclass the singleton and take advantage of its `cleanUpOldObjects:` method. This method is called whenever the context has just saved, and the context will re-save again after only if any changes are made.


## Installation

`BGPersistentStoreManager` is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "BGPersistentStoreManager"
```

## Author

Ben Guild, email@benguild.com

## License

`BGPersistentStoreManager` is available under the MIT license. See the LICENSE file for more info.
