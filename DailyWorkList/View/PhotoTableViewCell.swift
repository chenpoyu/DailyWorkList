//
//  PhotoTableViewCell.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/20.
//  Copyright © 2018年 poyu. All rights reserved.
//

import Foundation
import UIKit

class PhotoTableViewCell: UITableViewCell {
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var title: UITextField!
    @IBOutlet weak var detail: UITextView!
    var id: Int64!
}
