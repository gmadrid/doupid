//
//  FileWatcher.swift
//  doupid
//
//  Created by George Madrid on 1/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

protocol FileWatcherCallback {
  func directoryChanged(path: String, recursive: Bool)
}

protocol FileWatcherEventIdProvider {
  var eventId: FSEventStreamEventId { get set }
}

class FileWatcher {
  private var streamRef: FSEventStreamRef = nil
  private lazy var watchedDirectories = Set<String>()
  private lazy var callbacks = [FileWatcherCallback]()
  private var eventIdProvider: FileWatcherEventIdProvider

  init(eventIdProvider: FileWatcherEventIdProvider) {
    self.eventIdProvider = eventIdProvider
  }

  deinit {
    stopWatching()
  }

  func watchPaths(paths: [String]) {
    for path in paths {
      watchedDirectories.insert(path);
    }
    stopWatching()
    startWatching()
  }

  func stopWatchingPaths(paths: [String]) {
    for path in paths {
      if let index = watchedDirectories.indexOf(path) {
        watchedDirectories.removeAtIndex(index)
      }
    }
    stopWatching()
    startWatching()
  }

  func clearWatchedPaths() {
    watchedDirectories.removeAll()
    stopWatching()
  }

  private let eventCallback: FSEventStreamCallback = {
    (streamRef : ConstFSEventStreamRef, clientCallbackInfo: UnsafeMutablePointer<Void>, numEvents: Int,
    unsafeEventPaths: UnsafeMutablePointer<Void>, eventFlags: UnsafePointer<FSEventStreamEventFlags>, eventIds: UnsafePointer<FSEventStreamEventId>) in

    let fileWatcher: FileWatcher = unsafeBitCast(clientCallbackInfo, FileWatcher.self)

    let eventPaths = unsafeBitCast(unsafeEventPaths, NSArray.self) as! [String]
    var highestEventId: FSEventStreamEventId = 0

    for i in 0..<numEvents {
      debugPrint(eventPaths[i], eventFlags[i], eventIds[i])
      for cb in fileWatcher.callbacks {
        cb.directoryChanged(eventPaths[i], recursive: false);
      }
      highestEventId = max(highestEventId, eventIds[i])
    }
    debugPrint(highestEventId)
    fileWatcher.eventIdProvider.eventId = highestEventId
  }

  private func startWatching() {
    guard watchedDirectories.count > 0 else {
      return
    }

    var fsContext = FSEventStreamContext()
    fsContext.info = UnsafeMutablePointer<Void>(unsafeAddressOf(self))
    let dirs = Array<String>(watchedDirectories)
    let eventId = FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
    let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagUseCFTypes)
    let streamRef = FSEventStreamCreate(nil, eventCallback, &fsContext, dirs, eventId, 10, flags)

    FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode)
    guard FSEventStreamStart(streamRef) else {
      // TODO: Wow, we need to fail hard, here, I guess, for now.
      return
    }
    self.streamRef = streamRef
  }

  private func stopWatching() {
    if streamRef != nil {
      FSEventStreamStop(streamRef)
      FSEventStreamInvalidate(streamRef)
      FSEventStreamRelease(streamRef)
      streamRef = nil
      print("closed the stream")
    }
    print("stopped watching")
  }
}