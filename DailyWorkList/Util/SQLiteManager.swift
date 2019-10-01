//
//  SQLiteManager.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/5.
//  Copyright © 2018年 poyu. All rights reserved.
//

import SQLite

struct SQLiteManager {
    
    var database: Connection!
    
    init () {
        connect()
        setTable()
    }
    
    mutating func connect(databaseName: String = "dailyWorkList.sqlite3") {
        // 取得路徑
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + databaseName
        print("path = \(path)")
        do {
            // 若資料庫不存在的話，創立一個並建立連線
            database = try Connection(path)
        } catch {
            // TODO 連線資料庫失敗
        }
    }
    
    let TB_MONTH = Table("TB_MONTH")
    let TB_MONTH_WORK_ID = Expression<String>("work_id")
    let TB_MONTH_NOTE = Expression<String?>("note")
    
    let TB_WEEK = Table("TB_WEEK")
    let TB_WEEK_WORK_ID = Expression<String>("work_id")
    let TB_WEEK_NOTE = Expression<String?>("note")
    let TB_WEEK_START_DATE = Expression<String>("start_date")
    let TB_WEEK_END_DATE = Expression<String>("end_date")
    
    let TB_DAY = Table("TB_DAY")
    let TB_DAY_WORK_ID = Expression<String>("work_id")
    let TB_DAY_MOOD = Expression<Int>("mood")
    let TB_DAY_WATER = Expression<Int>("water")
    let TB_DAY_EXERCISE = Expression<Int>("exercise")
    let TB_DAY_NOTE = Expression<String?>("note")
    
    let TB_EVENT = Table("TB_EVENT")
    let TB_EVENT_ID = Expression<Int64>("id")
    let TB_EVENT_DAY = Expression<String>("day")
    let TB_EVENT_NAME = Expression<String>("name")
    let TB_EVENT_TIME = Expression<String?>("time")
    let TB_EVENT_CATEGORY = Expression<Int>("category")
    let TB_EVENT_REMINDER = Expression<Bool>("reminder")
    let TB_EVENT_PLACE = Expression<String?>("place")
    let TB_EVENT_LAT = Expression<Double?>("lat")
    let TB_EVENT_LNG = Expression<Double?>("lng")
    let TB_EVENT_NOTE = Expression<String?>("note")
    let TB_EVENT_FINISH = Expression<Bool>("finish")
    
    let TB_MEDIA = Table("TB_MEDIA")
    let TB_MEDIA_ID = Expression<Int64>("id")
    let TB_MEDIA_EVENT_ID = Expression<Int64>("event_id")
    let TB_MEDIA_TYPE = Expression<Int>("type")
    let TB_MEDIA_TITLE = Expression<String>("title")
    let TB_MEDIA_DETAIL = Expression<String?>("detail")
    let TB_MEDIA_PATH = Expression<String>("path")
    
    func setTable() -> Void {
        do {
            try database.run(TB_MONTH.create(ifNotExists: true) { t in
                t.column(TB_MONTH_WORK_ID, primaryKey: true, check: TB_MONTH_WORK_ID.length == 6)    //     "work_id" TEXT PRIMARY KEY NOT NULL,
                t.column(TB_MONTH_NOTE)                         //     "note" TEXT
            })
            
            try database.run(TB_WEEK.create(ifNotExists: true) { t in
                t.column(TB_WEEK_WORK_ID, primaryKey: true, check: TB_WEEK_WORK_ID.length == 8 && TB_WEEK_WORK_ID.like("%_%"))    //     "work_id" TEXT PRIMARY KEY NOT NULL,
                t.column(TB_WEEK_NOTE)                         //     "note" TEXT
                t.column(TB_WEEK_START_DATE, check: TB_WEEK_START_DATE.length == 8)                   //     "start_date" TEXT
                t.column(TB_WEEK_END_DATE, check: TB_WEEK_END_DATE.length == 8)                     //     "end_date" TEXT
            })
            
            try database.run(TB_DAY.create(ifNotExists: true) { t in
                t.column(TB_DAY_WORK_ID, primaryKey: true, check: TB_DAY_WORK_ID.length == 8)    //     "work_id" TEXT PRIMARY KEY NOT NULL,
                t.column(TB_DAY_MOOD, check: TB_DAY_MOOD >= 0 && TB_DAY_MOOD <= 5, defaultValue: 0)  //     "mood" INTEGER 0-5 DEFAULT 0
                t.column(TB_DAY_WATER, check: TB_DAY_WATER >= 0 && TB_DAY_WATER <= 5, defaultValue: 0)  //     "water" INTEGER 0-5 DEFAULT 0
                t.column(TB_DAY_EXERCISE, check: TB_DAY_EXERCISE >= 0 && TB_DAY_EXERCISE <= 5, defaultValue: 0)                     //     "exercise" INTEGER 0-5 DEFAULT 0
                t.column(TB_DAY_NOTE)                         //     "note" TEXT
            })
            
            try database.run(TB_EVENT.create(ifNotExists: true) { t in
                t.column(TB_EVENT_ID, primaryKey: true)    //     "event_id" INTEGER PRIMARY KEY NOT NULL,
                t.column(TB_EVENT_DAY, check: TB_EVENT_DAY.length == 8)  //     "day" TEXT NOT NULL
                t.column(TB_EVENT_NAME)  //     "name" TEXT NOT NULL
                t.column(TB_EVENT_TIME, check: TB_EVENT_TIME.length == 4) //     "time" TEXT NOT NULL
                t.column(TB_EVENT_CATEGORY, defaultValue: 0)  //     "category" INTEGER
                t.column(TB_EVENT_REMINDER, defaultValue: false)  //     "reminder" INTEGER 0 or 1
                t.column(TB_EVENT_PLACE)                        //  "place" TEXT
                t.column(TB_EVENT_LAT)                         //     "lat" REAL
                t.column(TB_EVENT_LNG)                         //     "lng" REAL
                t.column(TB_DAY_NOTE)                         //     "note" TEXT
                t.column(TB_EVENT_FINISH, defaultValue: false)  //     "finish" INTEGER 0 or 1
            })
            
            try database.run(TB_MEDIA.create(ifNotExists: true) { t in
                t.column(TB_MEDIA_ID, primaryKey: true)    //     "id" INTEGER PRIMARY KEY NOT NULL,
                t.column(TB_MEDIA_EVENT_ID, references: TB_EVENT, TB_EVENT_ID) //    "event_id" INTEGER PRIMARY KEY NOT NULL,
                t.column(TB_MEDIA_TYPE)  //     "type" INTEGER
                t.column(TB_MEDIA_TITLE)  //     "title" TEXT
                t.column(TB_MEDIA_DETAIL)  //     "detail" TEXT
                t.column(TB_MEDIA_PATH)  //     "path" TEXT
            })
        } catch {
            // TODO 創建資料表失敗
            print("create fail: \(error)")
        }
    }
    
    // 查詢
    func queryMonthById(id: String) -> Array<Month> {
        var monthList:[Month] = [Month]()
        do {
            for result in Array(try database.prepare(TB_MONTH.filter(TB_MONTH_WORK_ID == id))) {
                var daysDict: [Int: EventCount] = [Int: EventCount]()
                for detail in try database.prepare("SELECT day, CAST(SUBSTR(day, 7, 2) AS INT), COUNT(1), SUM(finish) FROM TB_EVENT where SUBSTR(day, 1, 6) = ? GROUP BY day", id) {
                    daysDict[Int(truncatingIfNeeded: detail[1] as! Int64)] = EventCount(day: detail[0] as! String, eventCount: Int(truncatingIfNeeded: detail[2] as! Int64), finishCount: Int(truncatingIfNeeded: detail[3] as! Int64))
                }
                monthList.append(Month(work_id: result[TB_MONTH_WORK_ID], note: result[TB_MONTH_NOTE], days: daysDict))
            }
        } catch {
            // TODO 查詢資料表失敗
        }
        return monthList
    }
    
    func queryWeekByDate(date: String) -> Array<Week> {
        var weekList:[Week] = [Week]()
        do {
            for result in Array(try database.prepare(TB_WEEK.filter(TB_WEEK_START_DATE <= date && TB_WEEK_END_DATE >= date))) {
                weekList.append(Week(work_id: result[TB_WEEK_WORK_ID], note: result[TB_WEEK_NOTE], start_date: result[TB_WEEK_START_DATE], end_date: result[TB_WEEK_END_DATE]))
            }
        } catch {
            // TODO 查詢資料表失敗
        }
        return weekList
    }
    
    func queryDayById(id: String) -> Array<Day> {
        var dayList:[Day] = [Day]()
        do {
            for result in Array(try database.prepare(TB_DAY.filter(TB_DAY_WORK_ID == id))) {
                dayList.append(Day(work_id: result[TB_DAY_WORK_ID], mood: result[TB_DAY_MOOD], water: result[TB_DAY_WATER], exercise: result[TB_DAY_EXERCISE], note: result[TB_DAY_NOTE] ?? ""))
            }
        } catch {
            // TODO 查詢資料表失敗
        }
        return dayList
    }
    
    func queryEventById(id: Int64) -> Array<Event> {
        var eventList:[Event] = [Event]()
        do {
            for result in Array(try database.prepare(TB_EVENT.filter(TB_EVENT_ID == id))) {
                eventList.append(Event(id: result[TB_EVENT_ID], day: result[TB_EVENT_DAY], name: result[TB_EVENT_NAME], time: result[TB_EVENT_TIME], category: result[TB_EVENT_CATEGORY], reminder: result[TB_EVENT_REMINDER], place: result[TB_EVENT_PLACE], lat: result[TB_EVENT_LAT], lng: result[TB_EVENT_LNG], note: result[TB_EVENT_NOTE], finish: result[TB_EVENT_FINISH]))
            }
        } catch {
            // TODO 查詢資料表失敗
        }
        return eventList
    }
    
    func queryEventByDate(date: String) -> Array<Event> {
        var eventList:[Event] = [Event]()
        do {
            for result in Array(try database.prepare(TB_EVENT.filter(TB_EVENT_DAY == date))) {
                eventList.append(Event(id: result[TB_EVENT_ID], day: result[TB_EVENT_DAY], name: result[TB_EVENT_NAME], time: result[TB_EVENT_TIME], category: result[TB_EVENT_CATEGORY], reminder: result[TB_EVENT_REMINDER], place: result[TB_EVENT_PLACE], lat: result[TB_EVENT_LAT], lng: result[TB_EVENT_LNG], note: result[TB_EVENT_NOTE], finish: result[TB_EVENT_FINISH]))
            }
        } catch {
            // TODO 查詢資料表失敗
        }
        return eventList
    }
    
    func queryMediaByEventIdAndType(event_id: Int64, type: Int) -> Array<Media> {
        var mediaList:[Media] = [Media]()
        do {
            for result in Array(try database.prepare(TB_MEDIA.filter(TB_MEDIA_EVENT_ID == event_id && TB_MEDIA_TYPE == type))) {
                mediaList.append(Media(id: result[TB_MEDIA_ID], title: result[TB_MEDIA_TITLE], detail: result[TB_MEDIA_DETAIL] ?? "", path: result[TB_MEDIA_PATH]))
            }
        } catch {
            // TODO 查詢資料表失敗
        }
        return mediaList
    }
    
    // 新增
    func insertMonth(work_id: String) {
        do {
            try database.run(TB_MONTH.insert(TB_MONTH_WORK_ID <- work_id))
        } catch {
            // TODO 新增失敗
        }
    }
    
    func insertWeek(work_id: String, start_date: String, end_date: String) {
        do {
            try database.run(TB_WEEK.insert(TB_WEEK_WORK_ID <- work_id, TB_WEEK_START_DATE <- start_date, TB_WEEK_END_DATE <- end_date))
        } catch {
            // TODO 新增失敗
        }
    }
    
    func insertDay(work_id: String) {
        do {
            try database.run(TB_DAY.insert(TB_DAY_WORK_ID <- work_id))
        } catch {
            // TODO 新增失敗
        }
    }
    
    func insertEvent(day: String, name: String, time: String?, category: Int, reminder: Bool, place: String?, lat: Double?, lng: Double?, note: String?) {
        do {
            try database.run(TB_EVENT.insert(TB_EVENT_DAY <- day, TB_EVENT_NAME <- name, TB_EVENT_TIME <- time, TB_EVENT_CATEGORY <- category, TB_EVENT_REMINDER <- reminder, TB_EVENT_PLACE <- place, TB_EVENT_LAT <- lat, TB_EVENT_LNG <- lng, TB_EVENT_NOTE <- note))
        } catch {
            // TODO 新增失敗
            print("insert fail: \(error)")
        }
    }
    
    func insertMedia(event_id: Int64, type: Int, title: String, detail: String?, path: String) {
        do {
            try database.run(TB_MEDIA.insert(TB_MEDIA_EVENT_ID <- event_id, TB_MEDIA_TYPE <- type, TB_MEDIA_TITLE <- title, TB_MEDIA_DETAIL <- detail, TB_MEDIA_PATH <- path))
        } catch {
            // TODO 新增失敗
        }
    }
    
    // 修改
    func updateMonthById(id: String, note: String) {
        do {
            let item = TB_MONTH.filter(TB_MONTH_WORK_ID == id)
            if try database.run(item.update(TB_MONTH_NOTE <- note)) > 0 {
                print("update month note")
            }
        } catch {
            // TODO 更新失敗
        }
    }
    
    func updateWeekById(id: String, note: String) {
        do {
            let item = TB_WEEK.filter(TB_WEEK_WORK_ID == id)
            if try database.run(item.update(TB_WEEK_NOTE <- note)) > 0 {
                print("update week note")
            }
        } catch {
            // TODO 更新失敗
        }
    }
    
    func updateDayMoodById(id: String, val: Int) {
        do {
            let item = TB_DAY.filter(TB_DAY_WORK_ID == id)
            if try database.run(item.update(TB_DAY_MOOD <- TB_DAY_MOOD + val)) > 0 {
                print("update day")
            }
        } catch {
            // TODO 更新失敗
        }
    }
    
    func updateDayWaterById(id: String, val: Int) {
        do {
            let item = TB_DAY.filter(TB_DAY_WORK_ID == id)
            if try database.run(item.update(TB_DAY_WATER <- TB_DAY_WATER + val)) > 0 {
                print("update day")
            }
        } catch {
            // TODO 更新失敗
        }
    }
    
    func updateDayExerciseById(id: String, val: Int) {
        do {
            let item = TB_DAY.filter(TB_DAY_WORK_ID == id)
            if try database.run(item.update(TB_DAY_EXERCISE <- TB_DAY_EXERCISE + val)) > 0 {
                print("update day")
            }
        } catch {
            // TODO 更新失敗
        }
    }
    
    func updateDayNoteById(id: String, note: String?) {
        do {
            let item = TB_DAY.filter(TB_DAY_WORK_ID == id)
            if try database.run(item.update(TB_DAY_NOTE <- note)) > 0 {
                print("update day")
            }
        } catch {
            // TODO 更新失敗
        }
    }
    
    func updateEventById(id: Int64, name: String, time: String?, category: Int, reminder: Bool, place: String?, lat: Double?, lng: Double?, note: String, finish: Bool) {
        do {
            let item = TB_EVENT.filter(TB_EVENT_ID == id)
            if try database.run(item.update(TB_EVENT_NAME <- name, TB_EVENT_TIME <- time, TB_EVENT_CATEGORY <- category, TB_EVENT_REMINDER <- reminder, TB_EVENT_PLACE <- place, TB_EVENT_LAT <- lat, TB_EVENT_LNG <- lng, TB_EVENT_NOTE <- note, TB_EVENT_FINISH <- finish)) > 0 {
                print("update event")
            }
        } catch {
            // TODO 更新失敗
        }
    }
    
    func updateEventFinishById(id: Int64, finish: Bool) {
        do {
            let item = TB_EVENT.filter(TB_EVENT_ID == id)
            if try database.run(item.update(TB_EVENT_FINISH <- finish)) > 0 {
                print("update event")
            }
        } catch {
            // TODO 更新失敗
        }
    }
    
    func updateMediaTitleById(id: Int64, title: String) {
        do {
            let item = TB_MEDIA.filter(TB_MEDIA_ID == id)
            if try database.run(item.update(TB_MEDIA_TITLE <- title)) > 0 {
                print("update media")
            }
        } catch {
            // TODO 更新失敗
        }
    }
    
    func updateMediaDetailById(id: Int64, detail: String?) {
        do {
            let item = TB_MEDIA.filter(TB_MEDIA_ID == id)
            if try database.run(item.update(TB_MEDIA_DETAIL <- detail)) > 0 {
                print("update media")
            }
        } catch {
            // TODO 更新失敗
        }
    }
    
    // 刪除
    func deleteEventById(id: Int64) {
        let item = TB_EVENT.filter(TB_EVENT_ID == id)
        do {
            if try database.run(item.delete()) > 0 {
                print("deleted event")
            }
        } catch {
            // TODO 刪除資料失敗
            print("delete failed: \(error)")
        }
    }
    
    func deleteMediaById(id: Int64) {
        let item = TB_MEDIA.filter(TB_MEDIA_ID == id)
        do {
            if try database.run(item.delete()) > 0 {
                print("deleted media")
            }
        } catch {
            // TODO 刪除資料失敗
            print("delete failed: \(error)")
        }
    }
    
    // 統計圖表使用
    func queryDayByMonth(month: String) -> [String : Day] {
        var dayList: [String : Day] = [String : Day]()
        do {
            for result in Array(try database.prepare(TB_DAY.filter(TB_DAY_WORK_ID.like("\(month)%")).order(TB_DAY_WORK_ID))) {
                dayList[result[TB_DAY_WORK_ID]] = Day(work_id: result[TB_DAY_WORK_ID], mood: result[TB_DAY_MOOD], water: result[TB_DAY_WATER], exercise: result[TB_DAY_EXERCISE], note: result[TB_DAY_NOTE] ?? "")
            }
        } catch {
            // TODO 查詢資料表失敗
        }
        return dayList
    }
    
    func queryEventCategoryByMonth(month: String) -> [Int : Int] {
        var category: [Int : Int] = [Int : Int]()
        do {
            for result in try database.prepare("SELECT category, count(1) FROM TB_EVENT where SUBSTR(day, 1, 6) = ? GROUP BY category", month) {
                category[Int(truncatingIfNeeded: result[0] as! Int64)] = Int(truncatingIfNeeded: result[1] as! Int64)
            }
        } catch {
            // TODO 查詢資料表失敗
        }
        return category
    }
}
