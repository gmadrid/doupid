//
//  DataManager.swift
//  doupid
//
//  Created by George Madrid on 1/7/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Cocoa

// A protocol for background operations.
private protocol DataOperation {
  func performDataOperation(context: NSManagedObjectContext)
}

class DataManager : NSObject {

  // MARK: Background context

  // All background operations will take place in this context.
  private lazy var backgroundContext : NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    context.parentContext = self.managedObjectContext
    return context
  }()


  // MARK: Background operations

  // Path scan will add an entry for every image file under path to the data store.
  // It will also clear the so-called "dynamic" data for any file whose size or mod date has changed.
  private class PathScan : DataOperation {
    let path: String

    init(path: String) {
      self.path = path
    }

    func performDataOperation(context: NSManagedObjectContext) {
      print("PathScan: \(path)")
      var i = 0
      var j = 0
      do {
        try GetFilesUnderPath(path) { filePath, attrs in
          i++
          guard PathRefersToImageFile(filePath) else {
            // Ignore non-image files
            return
          }
          j++
          if (i % 100 == 0) {
            print("Scanning \(i)/\(j) files")
          }

          let image = DataManager.FindImageWithPath(filePath, context: context) ??
            DataManager.MakeImage(filePath, attributes: attrs, context:context)

          if image.isObviouslyDifferentFromAttrs(attrs) {
            image.clearDynamicFields()
            image.size = NSNumber(unsignedLongLong: (attrs as NSDictionary).fileSize())
            image.modDate = (attrs as NSDictionary).fileModificationDate()
          }
        }
        try context.save()
      } catch {
        print("Exception while walking path: \(path), \(error)")
      }
      print("Done scanning")
    }
  }

  // MARK: -

  private class func FindImageWithPath(path: String, context: NSManagedObjectContext) -> Image? {
    let fetch = NSFetchRequest(entityName: "Image")
    fetch.predicate = NSPredicate(format: "path == %@", path)

    let results = try? context.executeFetchRequest(fetch)
    if results == nil || results?.count == 0 {
      return nil
    }

    return results?.first as! Image?
  }

  private class func MakeImage(path: String, attributes: [String:AnyObject], context: NSManagedObjectContext) -> Image {
    let image = NSEntityDescription.insertNewObjectForEntityForName("Image", inManagedObjectContext: context) as! Image
    image.setRequiredPathFields(path);
    return image
  }

  // MARK: -

  private func performOp(op: DataOperation) {
    backgroundContext.performBlock {
      op.performDataOperation(self.backgroundContext)
    }
  }

  func processPath(path: String) {
    performOp(PathScan(path: path));
  }

  // MARK: - Core Data stack

  lazy var managedObjectContext: NSManagedObjectContext = {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
    let coordinator = self.persistentStoreCoordinator
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
  }()

  private lazy var applicationDocumentsDirectory: NSURL = {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.me.doupid" in the user's Application Support directory.
    let dir = NSSearchPathDirectory.ApplicationSupportDirectory

    let urls = NSFileManager.defaultManager().URLsForDirectory(dir, inDomains: .UserDomainMask)
    let appSupportURL = urls[urls.count - 1]
    return appSupportURL.URLByAppendingPathComponent("com.me.doupid")
  }()

  private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
    let fileManager = NSFileManager.defaultManager()
    var failError: NSError? = nil
    var shouldFail = false
    var failureReason = "There was an error creating or loading the application's saved data."

    // Make sure the application files directory is there
    do {
      let properties = try self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey])
      if !properties[NSURLIsDirectoryKey]!.boolValue {
        failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
        shouldFail = true
      }
    } catch  {
      let nserror = error as NSError
      if nserror.code == NSFileReadNoSuchFileError {
        do {
          try fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil)
        } catch {
          failError = nserror
        }
      } else {
        failError = nserror
      }
    }

    // Create the coordinator and store
    var coordinator: NSPersistentStoreCoordinator? = nil
    if failError == nil {
      coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
      let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CocoaAppCD.storedata")
      do {
        try coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil)
      } catch {
        failError = error as NSError
      }
    }

    if shouldFail || (failError != nil) {
      // Report any error we got.
      var dict = [String: AnyObject]()
      dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
      dict[NSLocalizedFailureReasonErrorKey] = failureReason
      if failError != nil {
        dict[NSUnderlyingErrorKey] = failError
      }
      let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
      NSApplication.sharedApplication().presentError(error)
      abort()
    } else {
      return coordinator!
    }
  }()

  private lazy var managedObjectModel: NSManagedObjectModel = {
    // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
    let modelURL = NSBundle.mainBundle().URLForResource("doupid", withExtension: "momd")!
    return NSManagedObjectModel(contentsOfURL: modelURL)!
  }()

  // MARK - Core data saving / undo
  func save() {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    if !managedObjectContext.commitEditing() {
      NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
    }
    if managedObjectContext.hasChanges {
      do {
        try managedObjectContext.save()
      } catch {
        let nserror = error as NSError
        NSApplication.sharedApplication().presentError(nserror)
      }
    }
  }


}
