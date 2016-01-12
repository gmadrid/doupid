//
//  FileWatcher.swift
//  doupid
//
//  Created by George Madrid on 1/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

protocol FileWatcherCallback {

}

protocol FileWatcherPersister {

}

protocol HasPath {
  var path: String { get }
}

extension String : HasPath {
  var path: String { return self }
}

class FileWatcher {
  private var streamRef: FSEventStreamRef = nil
  private lazy var watchedDirectories = Set<String>()
  private lazy var callbacks = [FileWatcherCallback]()

  deinit {
    stopWatching()
  }

  func watchPaths(paths: [HasPath]) {
    for path in paths {
      watchedDirectories.insert(path.path);
    }
    stopWatching()
    startWatching()
  }

  func stopWatchingPaths(paths: [HasPath]) {
    for path in paths {
      if let index = watchedDirectories.indexOf(path.path) {
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

  private func startWatching() {
    guard watchedDirectories.count > 0 else {
      return
    }

    var fsContext = FSEventStreamContext()

    let cb : FSEventStreamCallback = {
      (streamRef : ConstFSEventStreamRef, clientCallbackInfo: UnsafeMutablePointer<Void>, numEvents: Int,
      eventPaths: UnsafeMutablePointer<Void>, eventFlags: UnsafePointer<FSEventStreamEventFlags>, eventIds: UnsafePointer<FSEventStreamEventId>) in
      for var i = 0; i < numEvents; ++i {
        debugPrint(eventIds[i])
      }
      debugPrint(unsafeBitCast(eventPaths, NSArray.self) as! [String])
    }

    let streamRef = FSEventStreamCreate(nil, cb, &fsContext, Array<String>(watchedDirectories), FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 10,
      FSEventStreamCreateFlags(kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagUseCFTypes))
    FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode)
    if !FSEventStreamStart(streamRef) {
      // Wow, we need to fail hard, here, I guess, for now.
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