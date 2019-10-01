//
//  DayViewController.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/12.
//  Copyright © 2018年 poyu. All rights reserved.
//

import Foundation
import UIKit

enum DayStatus: Int {
    case Mood = 1
    case Water = 2
    case Exercise = 3
}

class DayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    let sqlManager = (UIApplication.shared.delegate as! AppDelegate).sqlManager
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var dateText: UITextField!
    @IBOutlet var moodList: [UIButton]!
    @IBOutlet var waterList: [UIButton]!
    @IBOutlet var exerciseList: [UIButton]!
    @IBOutlet weak var eventTableView: UITableView!
    @IBOutlet weak var noteText: UITextView!
    
    var eventList: [Event] = [Event]()
    let cellIdentifier: String = "DayEventTableViewCell"
    var refreshControl: UIRefreshControl!
    
    let datePicker = UIDatePicker()    // Date的DatePicker
    let showDateFormatter = DateFormatter()    // 要顯示出來看的日期格式
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 增加一個觸控事件
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        // 加在最基底的 self.view 上
        scrollView.addGestureRecognizer(tap)
        
        // 設置時間顯示的格式
        showDateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.dateFormat = "yyyyMMdd"
        
        // 設置 UIDatePicker 格式
        datePicker.datePickerMode = .date
        // 設置顯示的語言環境
        datePicker.locale = Locale(identifier: "zh_TW")
        dateText.inputView = datePicker
        
        // TODO for test
        datePicker.date = dateFormatter.date(from: "20181014")!
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        
        let doneButton = UIButton()
        doneButton.setTitle("Done", for: UIControlState.normal)
        doneButton.setTitleColor(UIColor.init(red: 0/255, green: 122/255, blue: 255/255, alpha: 1), for: UIControlState.normal)
        doneButton.addTarget(self, action: #selector(changeDate), for: .touchUpInside)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([spaceButton, UIBarButtonItem(customView: doneButton)], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        dateText.inputAccessoryView = toolBar
     
        for mood in moodList {
            mood.tag = DayStatus.Mood.rawValue
            mood.isSelected = false
            mood.setImage(UIImage(named: "mood_activate"), for: .selected)
            mood.addTarget(self, action: #selector(clickButtonList), for: .touchUpInside)
        }
        for water in waterList {
            water.tag = DayStatus.Water.rawValue
            water.isSelected = false
            water.setImage(UIImage(named: "water_activate"), for: .selected)
            water.addTarget(self, action: #selector(clickButtonList), for: .touchUpInside)
        }
        for exercise in exerciseList {
            exercise.tag = DayStatus.Exercise.rawValue
            exercise.isSelected = false
            exercise.setImage(UIImage(named: "exercise_activate"), for: .selected)
            exercise.addTarget(self, action: #selector(clickButtonList), for: .touchUpInside)
        }
        
        // 設置委任對象
        eventTableView.delegate = self
        eventTableView.dataSource = self
        // 註冊 cell（但有使用Storyboard的情況下不需再次註冊，已有設定）
//        eventTableView.register(EventTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        // Refresh Control
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadEventTableView), for: UIControlEvents.valueChanged)
        eventTableView.addSubview(refreshControl)
        
        noteText.delegate = self
        
        changeDate()
        
        NotificationCenter.default.addObserver(self, selector: #selector(modifyHeightWithKeyboard), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modifyHeightWithKeyboard), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func hideKeyboard(){
        // 除了使用 self.view.endEditing(true)，也可以用 resignFirstResponder()，來針對一個元件隱藏鍵盤
        self.view.endEditing(true)
    }
    
    @objc func changeDate() {
        dateText.text = showDateFormatter.string(from: datePicker.date)
        
        let dayArray = sqlManager.queryDayById(id: dateFormatter.string(from: datePicker.date))
        if dayArray.count > 0 {
            let day = dayArray[0]
            for i in 0...moodList.count - 1 {
                if day.mood > i {
                    moodList[i].isSelected = true
                } else {
                    moodList[i].isSelected = false
                }
            }
            for i in 0...waterList.count - 1 {
                if day.water > i {
                    waterList[i].isSelected = true
                } else {
                    waterList[i].isSelected = false
                }
            }
            for i in 0...exerciseList.count - 1 {
                if day.exercise > i {
                    exerciseList[i].isSelected = true
                } else {
                    exerciseList[i].isSelected = false
                }
            }
            noteText.text = day.note
        } else {
            sqlManager.insertDay(work_id: dateFormatter.string(from: datePicker.date))
            for mood in moodList {
                mood.isSelected = false
            }
            for water in waterList {
                water.isSelected = false
            }
            for exercise in exerciseList {
                exercise.isSelected = false
            }
            noteText.text = ""
        }
        
        reloadEventTableView()
        
        view.endEditing(true)
    }
    
    @objc func reloadEventTableView() {
        eventList.removeAll()
        eventList.append(contentsOf: sqlManager.queryEventByDate(date: dateFormatter.string(from: datePicker.date)))
        self.eventTableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    @objc func clickButtonList(_ sender: UIButton) {
        var changeValue: Int = 0
        if sender.isSelected {
            sender.isSelected = false
            changeValue = -1
        } else {
            sender.isSelected = true
            changeValue = 1
        }
        
        switch sender.tag {
        case DayStatus.Mood.rawValue:
            sqlManager.updateDayMoodById(id: dateFormatter.string(from: datePicker.date), val: changeValue)
        case DayStatus.Water.rawValue:
            sqlManager.updateDayWaterById(id: dateFormatter.string(from: datePicker.date), val: changeValue)
        case DayStatus.Exercise.rawValue:
            sqlManager.updateDayExerciseById(id: dateFormatter.string(from: datePicker.date), val: changeValue)
        default:
            break
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        sqlManager.updateDayNoteById(id: dateFormatter.string(from: datePicker.date), note: noteText.text)
    }
    
    // get the count of elements you are going to display in your tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.eventList.count
    }
    
    // assign the values in your array variable to a cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! EventTableViewCell
        cell.titleLabel.text = self.eventList[indexPath.row].name
        cell.id = self.eventList[indexPath.row].id
        if self.eventList[indexPath.row].finish {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    // register when user taps a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! EventTableViewCell
        if self.eventList[indexPath.row].finish {
            self.eventList[indexPath.row].finish = false
            cell.accessoryType = .none
            sqlManager.updateEventFinishById(id: cell.id, finish: false)
        } else {
            self.eventList[indexPath.row].finish = true
            cell.accessoryType = .checkmark
            sqlManager.updateEventFinishById(id: cell.id, finish: true)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, indexPath in
            self.sqlManager.deleteEventById(id: self.eventList[indexPath.row].id)
            self.eventList.remove(at: indexPath.row)
            // 將畫面上的cell移除
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
        }
        delete.backgroundColor = UIColor.red
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, indexPath in
            if let controller = self.storyboard?.instantiateViewController(withIdentifier: "EditEventViewController") as? EditEventViewController {
                controller.event_id = self.eventList[indexPath.row].id
                self.present(controller, animated: true, completion: nil)
            }
        }
        edit.backgroundColor = UIColor.lightGray
        
        return [edit, delete]
    }
    
    var isKeyboardOn: Bool = false
    @objc func modifyHeightWithKeyboard(notification: NSNotification?) {
        if isKeyboardOn || notification == nil {
            isKeyboardOn = false
            scrollView.contentInset = UIEdgeInsets.zero
        } else {
            isKeyboardOn = true
            let keyboardSize: CGRect = ((notification!.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue)!
            scrollView.contentInset.bottom = scrollView.contentInset.bottom + keyboardSize.height
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
}
