//
//  Event.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/13.
//  Copyright © 2018年 poyu. All rights reserved.
//

import Foundation

struct Event {
    var id: Int64
    var day: String
    var name: String
    var time: String?
    var category: Int
    var reminder: Bool
    var place: String?
    var lat: Double?
    var lng: Double?
    var note: String?
    var finish: Bool
}
