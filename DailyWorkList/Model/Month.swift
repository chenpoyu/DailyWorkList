//
//  Month.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/20.
//  Copyright © 2018年 poyu. All rights reserved.
//

import Foundation

struct Month {
    var work_id: String
    var note: String?
    var days: [Int: EventCount] = [Int: EventCount]()
}

struct EventCount {
    var day: String
    var eventCount: Int = 0
    var finishCount: Int = 0
}
