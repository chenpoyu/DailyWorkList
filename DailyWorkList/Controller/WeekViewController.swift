//
//  WeekViewController.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/3.
//  Copyright © 2018年 poyu. All rights reserved.
//

import UIKit

struct EventGroup {
    var open: Bool = true
    var title: String = ""
    var eventArray: [Event] = [Event]()
}

class WeekViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    let sqlManager = (UIApplication.shared.delegate as! AppDelegate).sqlManager

    @IBOutlet weak var dateText: UITextField!
    @IBOutlet weak var noteText: UITextView!
    @IBOutlet weak var eventTableView: UITableView!
    
    var eventGroupArray: [EventGroup] = [EventGroup]()
    let cellIdentifier: String = "WeekEventTableViewCell"
    var refreshControl: UIRefreshControl!
    
    let datePicker = UIDatePicker()    // Date的DatePicker
    let showDateFormatter = DateFormatter()    // 要顯示出來看的日期格式
    let dateFormatter = DateFormatter()
    let weekFormatter = DateFormatter()
    var calendar = Calendar.current
    
    var id: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 增加一個觸控事件
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        // 加在最基底的 self.view 上
        self.view.addGestureRecognizer(tap)
        
        calendar.locale = Locale(identifier: "zh_TW")
        // 設置時間顯示的格式
        showDateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.dateFormat = "yyyyMMdd"
        weekFormatter.dateFormat = "yyyyMM"
        
        // 設置 UIDatePicker 格式
        datePicker.datePickerMode = .date
        // 設置顯示的語言環境
        datePicker.locale = Locale(identifier: "zh_TW")
        dateText.inputView = datePicker
        
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
        
        // 設置委任對象
        eventTableView.delegate = self
        eventTableView.dataSource = self
        
        // Refresh Control
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(changeDate), for: UIControlEvents.valueChanged)
        eventTableView.addSubview(refreshControl)
        
        noteText.delegate = self
        
        changeDate()
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc func changeDate() {
        dateText.text = showDateFormatter.string(from: datePicker.date)
        
        // 撈取資料庫資料
        var firstDate: Date!
        let weekArray = sqlManager.queryWeekByDate(date: dateFormatter.string(from: datePicker.date))
        if weekArray.count < 1 {
            // 新增該週資料
            let weekDay = calendar.component(.weekday, from: datePicker.date)
            var weekNum = calendar.component(.weekOfMonth, from: datePicker.date)
            var startDate: String!
            var endDate: String!
            if weekDay == 2 {
                startDate = dateFormatter.string(from: datePicker.date)
                endDate = dateFormatter.string(from: calendar.date(byAdding: .day, value: 6, to: datePicker.date)!)
            } else if weekDay > 2 {
                startDate = dateFormatter.string(from: calendar.date(byAdding: .day, value: 2 - weekDay, to: datePicker.date)!)
                endDate = dateFormatter.string(from: calendar.date(byAdding: .day, value: 8 - weekDay, to: datePicker.date)!)
            } else if weekDay < 2 {
                startDate = dateFormatter.string(from: calendar.date(byAdding: .day, value: -6, to: datePicker.date)!)
                endDate = dateFormatter.string(from: datePicker.date)
                weekNum = weekNum - 1
            }
            
            id = "\(weekFormatter.string(from: datePicker.date))_\(weekNum)"
            sqlManager.insertWeek(work_id: id, start_date: startDate, end_date: endDate)
            firstDate = dateFormatter.date(from: startDate)
            noteText.text = ""
        } else {
            id = weekArray[0].work_id
            firstDate = dateFormatter.date(from: weekArray[0].start_date)!
            noteText.text = weekArray[0].note
        }
        
        eventGroupArray.removeAll()
        for i in 0...6 {
            let date = calendar.date(byAdding: .day, value: i, to: firstDate)!
            let title = "\(showDateFormatter.string(from: date)) （\(getString(week: calendar.component(.weekday, from: date)))）"
            let eventArray = sqlManager.queryEventByDate(date: dateFormatter.string(from: date))
            let eventGroup = EventGroup(open: true, title: title, eventArray: eventArray)
            eventGroupArray.append(eventGroup)
        }
        
        self.eventTableView.reloadData()
        self.refreshControl.endRefreshing()
        
        view.endEditing(true)
    }
    
    func getString(week: Int) -> String {
        switch week {
        case 2:
            return "星期一"
        case 3:
            return "星期二"
        case 4:
            return "星期三"
        case 5:
            return "星期四"
        case 6:
            return "星期五"
        case 7:
            return "星期六"
        case 1:
            return "星期日"
        default:
            return ""
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        sqlManager.updateWeekById(id: id, note: noteText.text)
    }
    
    // get the count of sections you are going to display in your tableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return eventGroupArray.count
    }
    
    // get the count of elements of section you are going to display in your tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if eventGroupArray[section].open {
            // need include section title
            return eventGroupArray[section].eventArray.count + 1
        } else {
            // title
            return 1
        }
    }
    
    // assign the values in your array variable to a cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! EventTableViewCell
        if indexPath.row == 0 {
            // set the section title
            cell.titleLabel.text = eventGroupArray[indexPath.section].title
            cell.backgroundColor = UIColor.lightGray
            cell.accessoryType = .none
        } else {
            // set the cells
            let dataIndex = indexPath.row - 1
            cell.backgroundColor = UIColor.white
            cell.titleLabel.text = eventGroupArray[indexPath.section].eventArray[dataIndex].name
            cell.id = eventGroupArray[indexPath.section].eventArray[dataIndex].id
            if eventGroupArray[indexPath.section].eventArray[dataIndex].finish {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    // register when user taps a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! EventTableViewCell
        if indexPath.row == 0 {
            // section title be selected
            if eventGroupArray[indexPath.section].open {
                eventGroupArray[indexPath.section].open = false
            } else {
                eventGroupArray[indexPath.section].open = true
            }
            cell.accessoryType = .none
            let section = IndexSet.init(integer: indexPath.section)
            eventTableView.reloadSections(section, with: .none)
        } else {
            // cells be selected
            if eventGroupArray[indexPath.section].eventArray[indexPath.row - 1].finish {
                eventGroupArray[indexPath.section].eventArray[indexPath.row - 1].finish = false
                cell.accessoryType = .none
                sqlManager.updateEventFinishById(id: cell.id, finish: false)
            } else {
                eventGroupArray[indexPath.section].eventArray[indexPath.row - 1].finish = true
                cell.accessoryType = .checkmark
                sqlManager.updateEventFinishById(id: cell.id, finish: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.row > 0 {
            let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, indexPath in
                self.sqlManager.deleteEventById(id: self.eventGroupArray[indexPath.section].eventArray[indexPath.row - 1].id)
                self.eventGroupArray[indexPath.section].eventArray.remove(at: indexPath.row - 1)
                // 將畫面上的cell移除
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
            delete.backgroundColor = UIColor.red
            
            let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, indexPath in
                if let controller = self.storyboard?.instantiateViewController(withIdentifier: "EditEventViewController") as? EditEventViewController {
                    controller.event_id = self.eventGroupArray[indexPath.section].eventArray[indexPath.row - 1].id
                    self.present(controller, animated: true, completion: nil)
                }
            }
            edit.backgroundColor = UIColor.lightGray
            
            return [edit, delete]
        } else {
            return nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

