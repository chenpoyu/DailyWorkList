//
//  MonthViewController.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/3.
//  Copyright © 2018年 poyu. All rights reserved.
//

import UIKit

class MonthViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextViewDelegate {
    let sqlManager = (UIApplication.shared.delegate as! AppDelegate).sqlManager
    
    @IBOutlet weak var calendarTitle: UILabel!
    @IBOutlet weak var calendarView: UICollectionView!
    @IBOutlet weak var noteText: UITextView!
    
    let monthTitle = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    var currentYear = Calendar.current.component(.year, from: Date())
    var currentMonth = Calendar.current.component(.month, from: Date())
    var weekday: Int {
        // 設定目前月份
        let dateComponents = DateComponents(year: currentYear, month: currentMonth)
        let date = Calendar.current.date(from: dateComponents)!
        // 取得該月1號的星期，如果是星期日就是1，但我預設星期一為第一天，故減一
        var weekday = Calendar.current.component(.weekday, from: date) - 1
        if weekday == 0 {
            weekday = 7
        }
        return weekday
    }
    var currentId: String {
        if currentMonth < 10 {
            return "\(currentYear)0\(currentMonth)"
        } else {
            return "\(currentYear)\(currentMonth)"
        }
    }
    var monthData: Month!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 增加一個觸控事件
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        // 加在最基底的 self.view 上
        self.view.addGestureRecognizer(tap)
        
        changeMonth(value: 0)
    }
    
    func changeMonth(value: Int) {
        currentMonth = currentMonth + value
        if currentMonth > 12 {
            currentMonth = 1
            currentYear = currentYear + 1
        } else if currentMonth < 1 {
            currentMonth = 12
            currentYear = currentYear - 1
        }
        
        calendarTitle.text = "\(currentYear) " + monthTitle[currentMonth - 1]
        
        var monthArray = sqlManager.queryMonthById(id: currentId)
        if monthArray.count < 1 {
            sqlManager.insertMonth(work_id: currentId)
            monthArray = sqlManager.queryMonthById(id: currentId)
        }
        monthData = monthArray[0]
        noteText.text = monthData.note
        calendarView.reloadData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        calendarView.collectionViewLayout.invalidateLayout()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / 7
        return CGSize(width: width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 設定目前月份
        let dateComponents = DateComponents(year: currentYear, month: currentMonth)
        let date = Calendar.current.date(from: dateComponents)!
        // 取得該月份天數
        let days = Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
        return days + weekday - 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dateCell", for: indexPath)
        if let textLabel = cell.contentView.subviews[0] as? UILabel {
            if indexPath.row < weekday - 1 {
                // 如果不是這個月份的日期要填空白
                textLabel.text = ""
            } else {
                textLabel.text = "\(indexPath.row - weekday + 2)"
            }
        }
        
        if let detailLabel = cell.contentView.subviews[1] as? UILabel {
            if let eventCount = monthData.days[indexPath.row - weekday + 2] {
                detailLabel.text = "\(eventCount.finishCount) / \(eventCount.eventCount)"
            } else {
                detailLabel.text = ""
            }
        }
        return cell
    }
    // 點選 cell 後執行的動作
//    func collectionView(collectionView: UICollectionView,
//                        didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        print("你選擇了第 \(indexPath.section + 1) 組的")
//        print("第 \(indexPath.item + 1) 張圖片")
//    }
    
    @IBAction func previousMonth(_ sender: UIButton) {
        changeMonth(value: -1)
    }
    
    @IBAction func nextMonth(_ sender: UIButton) {
        changeMonth(value: 1)
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        sqlManager.updateMonthById(id: currentId, note: noteText.text)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

