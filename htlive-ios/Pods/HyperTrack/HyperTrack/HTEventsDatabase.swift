//
//  HTEventsDatabase.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 21/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import SQLite


class EventsDatabaseManager {
  let path:String
  let dbName:String
  let events:Table
  let db:Connection?
  let id:Expression<Int64>
  let userId:Expression<String?>
  let recordedAt:Expression<Date>
  let eventJSON:Expression<String>
  let eventType:Expression<String>

  init() {
    self.path = NSSearchPathForDirectoriesInDomains(
      .applicationSupportDirectory, .userDomainMask, true
      ).first! + "/" + Bundle.main.bundleIdentifier!
    self.dbName = "hypertrackDB.sqlite3"
    self.events = Table("events")
    self.id = Expression<Int64>("id")
    self.userId = Expression<String?>("user_id")
    self.eventJSON = Expression<String>("event_json")
    self.recordedAt = Expression<Date>("recorded_at")
    self.eventType = Expression<String>("event_type")
    do {
      try FileManager.default.createDirectory(
        atPath: path, withIntermediateDirectories: true, attributes: nil
      )
      self.db = try Connection("\(path)/\(dbName)")
    } catch {
      debugPrint("Error connecting to db: %@", error.localizedDescription)
      self.db = nil
    }
  }

  func createEventsTable() {
    do {
      debugPrint("Creating events table")
      try db?.run(events.create(ifNotExists: true) { t in
        t.column(id, primaryKey: true)
        t.column(userId)
        t.column(eventType)
        t.column(eventJSON)
        t.column(recordedAt)
      })
    } catch {
      debugPrint("Error creating events table: %@", error.localizedDescription)
    }
  }

  func insert(event:HyperTrackEvent) -> Int64? {
    do {
      guard let eventJSONString = event.toJson() else { return nil }
      let rowId = try db?.run(events.insert(userId <- event.userId, eventType <- event.eventType.description, eventJSON <- eventJSONString, recordedAt <- event.recordedAt))
      return rowId
    } catch {
      debugPrint("Error inserting event to db: %@", error.localizedDescription)
      return nil
    }
  }

  func update(id:Int, event:HyperTrackEvent) {
    //TODO
  }

  func get(id:Int) {
    // TODO
  }

  func filter(userId:String) {
    // TODO
  }

  func getEvents(limit:Int = 50, userId:String) -> [Int64:HyperTrackEvent]? {
    let query = events.filter(self.userId == userId).order(recordedAt.asc).limit(limit)
    var eventDict:[Int64:HyperTrackEvent] = [:]

    do {
      for event in try db!.prepare(query) {
        let jsonString = event[self.eventJSON]
        let id = event[self.id]
        if let event = HyperTrackEvent.fromJson(text: jsonString) {
          eventDict[id] = event
        }
      }
      return eventDict
    } catch {
      debugPrint("Error getting events from db: %@", error.localizedDescription)
      return nil
    }
  }

  func deleteAll() {
    do {
      try db?.run(events.delete())
    } catch {
      debugPrint("Error deleting all events from db: %@", error.localizedDescription)
    }
  }

  func bulkDelete(ids:[Int64]) {
    let toDeleteEvents = events.filter(ids.contains(id))
    do {
      try db?.run(toDeleteEvents.delete())
    } catch {
      debugPrint("Error deleting events from db: %@", error.localizedDescription)
    }
  }
}
