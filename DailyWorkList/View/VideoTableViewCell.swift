//
//  VideoTableViewCell.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/21.
//  Copyright © 2018年 poyu. All rights reserved.
//

import Foundation
import UIKit

class VideoTableViewCell: UITableViewCell {
    @IBOutlet weak var videoImage: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var title: UITextField!
    @IBOutlet weak var detail: UITextView!
    var id: Int64!
}
