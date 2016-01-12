//
//  AppDelegate.swift
//  doupid
//
//  Created by George Madrid on 1/5/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, FileWatcherEventIdProvider {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var dataManager: DataManager!
  @IBOutlet weak var aryCtrl: NSArrayController!
  var fileWatcher: FileWatcher!

  func applicationWillFinishLaunching(notification: NSNotification) {
    fileWatcher = FileWatcher(eventIdProvider: self)
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    fileWatcher.clearWatchedPaths()
  }

  // MARK: - Path list manipulation

  @IBAction func clickAddPath(sender: NSResponder) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = false
    panel.allowsMultipleSelection = true

    panel.beginWithCompletionHandler(){ [unowned self, weak panel] i in
      if let urls = panel?.URLs {
        for url in urls {
          let newRoot = self.aryCtrl.newObject() as! Root
          newRoot.path = url.path!
          self.dataManager.processPath(newRoot.path!)
        }
      }
    }
  }

  @IBAction func clickRemovePath(sender: NSResponder) {
    aryCtrl.removeObjects(aryCtrl.selectedObjects)
  }

  @IBAction func saveAction(_: AnyObject?) {
    dataManager.save()
  }

  func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
      // Save changes in the application's managed object context before the application terminates.
    let managedObjectContext = dataManager.managedObjectContext
      
      if !managedObjectContext.commitEditing() {
          NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
          return .TerminateCancel
      }
      
      if !managedObjectContext.hasChanges {
          return .TerminateNow
      }
      
      do {
          try managedObjectContext.save()
      } catch {
          let nserror = error as NSError
          // Customize this code block to include application-specific recovery steps.
          let result = sender.presentError(nserror)
          if (result) {
              return .TerminateCancel
          }
          
          let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
          let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
          let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
          let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
          let alert = NSAlert()
          alert.messageText = question
          alert.informativeText = info
          alert.addButtonWithTitle(quitButton)
          alert.addButtonWithTitle(cancelButton)
          
          let answer = alert.runModal()
          if answer == NSAlertFirstButtonReturn {
              return .TerminateCancel
          }
      }
      // If we got here, it is time to quit.
      return .TerminateNow
  }

}

