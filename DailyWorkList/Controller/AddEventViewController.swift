//
//  AddEventViewController.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/7.
//  Copyright © 2018年 poyu. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

enum RepeatType: Int {
    case Once = 0
    case Daily = 1
    case Weekly = 2
    case Monthly = 3
}

class AddEventViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    let sqlManager = (UIApplication.shared.delegate as! AppDelegate).sqlManager
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var repeatButton: UISegmentedControl!
    @IBOutlet weak var startDate: UITextField!
    @IBOutlet weak var endDate: UITextField!
    @IBOutlet weak var execTime: UITextField!
    @IBOutlet weak var categoryPicker: UITextField!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var placeText: UITextField!
    @IBOutlet weak var noteText: UITextView!
    
    let startDatePicker = UIDatePicker()    // Start Date的DatePicker
    let endDatePicker = UIDatePicker()   // End Date的DatePicker
    let timePicker = UIDatePicker()   // Time的DatePicker
    let showDateFormatter = DateFormatter()    // 要顯示出來看的日期格式
    let showTimeFormatter = DateFormatter()    // 要顯示出來看的時間格式
    let dateFormatter = DateFormatter()    // 欲儲存進資料庫的日期格式
    let timeFormatter = DateFormatter()    // 欲儲存進資料庫的時間格式
    
    let pickerView = UIPickerView()
    var pickerData: [(code: Int, name: String)]! = []
    var categoryCode: Int = 0
    
    var lat: Double? = nil
    var lng: Double? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // 設置時間顯示的格式
        showDateFormatter.dateFormat = "yyyy-MM-dd"
        showTimeFormatter.dateFormat = "HH:mm"
        dateFormatter.dateFormat = "yyyyMMdd"
        timeFormatter.dateFormat = "HHmm"
        
        // 設置 UIDatePicker 格式
        startDatePicker.datePickerMode = .date
        // 設置顯示的語言環境
        startDatePicker.locale = Locale(identifier: "zh_TW")
        // 設置改變日期時間時會執行動作的方法
        startDatePicker.addTarget(self, action: #selector(changeStartDate), for: .valueChanged)
        startDate.inputView = startDatePicker
        changeStartDate()
        
        endDatePicker.datePickerMode = .date
        endDatePicker.locale = Locale(identifier: "zh_TW")
        endDatePicker.addTarget(self, action: #selector(changeEndDate), for: .valueChanged)
        endDate.inputView = endDatePicker
        
        timePicker.datePickerMode = .time
        timePicker.locale = Locale(identifier: "zh_TW")
        timePicker.addTarget(self, action: #selector(changeExecTime), for: .valueChanged)
        execTime.inputView = timePicker
        
        // 撈取設定檔的pickerData
        if let path = Bundle.main.path(forResource: "Category", ofType: "plist"),
            let array = NSArray(contentsOfFile: path) {
            // Use your myDict here
            for case let category as NSDictionary in array {
                pickerData.append((code:category.object(forKey: "code") as! Int, name: category.object(forKey: "name") as! String))
            }
        }
        
        nameText.delegate = self
        placeText.delegate = self
        
        // 設置顯示選取的資料
        pickerView.showsSelectionIndicator = true
        pickerView.delegate = self
        pickerView.dataSource = self
        categoryPicker.inputView = pickerView
        
        // 加入事件，當place有異動，就查詢其結果的座標
        placeText.addTarget(self, action: #selector(changePlace), for: .editingDidEnd)
        
        NotificationCenter.default.addObserver(self, selector: #selector(modifyHeightWithKeyboard), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(modifyHeightWithKeyboard), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func changeStartDate() {
        startDate.text = showDateFormatter.string(from: startDatePicker.date)
    }
    
    @objc func changeEndDate() {
        endDate.text = showDateFormatter.string(from: endDatePicker.date)
    }
    
    @objc func changeExecTime() {
        execTime.text = showTimeFormatter.string(from: timePicker.date)
    }
    
    @objc func changePlace() {
        // check address
        if placeText.text != "" {
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(placeText.text!) { (placemarks, error) in
                guard
                    let placemarks = placemarks,
                    let location = placemarks.first?.location
                    else {
                        // handle no location found
                        self.confirmAlert("Error Place. Please enter valid address.")
                        return
                }
                
                // Use your location
                self.lat = location.coordinate.latitude
                self.lng = location.coordinate.longitude
            }
        }
    }
    
    // Sets number of columns in picker view
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Sets the number of rows in the picker view
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // This function sets the text of the picker view to the content of the "salutations" array
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row].name
    }
    
    // When user selects an option, this function will set the text of the text field to reflect the selected option.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryPicker.text = pickerData[row].name
        categoryCode = pickerData[row].code
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func endText(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
        modifyHeightWithKeyboard(notification: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        modifyHeightWithKeyboard(notification: nil)
        return true
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        if nameText.text! == "" {
            confirmAlert("Name is required!")
        } else if startDate.text == "" {
            confirmAlert("Start Date is required!")
        } else if repeatButton.selectedSegmentIndex != 0 && endDate.text == "" {
            confirmAlert("If event is routine, end date is required.")
        } else if endDate.text != "" && endDatePicker.date <= startDatePicker.date {
            confirmAlert("End date cannot same with or earlier than start date.")
        } else {
            // 若有設定時間，才寫入HHMi格式，否則為nil
            var execTimeText: String? = nil
            if execTime.text != "" {
                execTimeText = timeFormatter.string(from: timePicker.date)
            }
            
            let calendar = Calendar.current
            var execDate = startDatePicker.date
            // Repeat
            repeat {
                sqlManager.insertEvent(day: dateFormatter.string(from: execDate), name: nameText.text!, time: execTimeText, category: categoryCode, reminder: reminderSwitch.isOn, place: placeText.text, lat: lat, lng: lng, note: noteText.text)
                switch repeatButton.selectedSegmentIndex {
                case RepeatType.Once.rawValue:
                    // Repeat == Once
                    break
                case RepeatType.Daily.rawValue:
                    // Repeat == Daily
                    execDate = calendar.date(byAdding: .day, value: 1, to: execDate)!
                case RepeatType.Weekly.rawValue:
                    // Repeat == Weekly
                    execDate = calendar.date(byAdding: .day, value: 7, to: execDate)!
                case RepeatType.Monthly.rawValue:
                    // Repeat == Monthly
                    execDate = calendar.date(byAdding: .month, value: 1, to: execDate)!
                default:
                    print("error repeat type")
                }
            } while endDate.text != "" && execDate <= endDatePicker.date
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func confirmAlert(_ message: String) {
        let alertViewController = UIAlertController(title: "Warn!", message: message, preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
        }))
        self.present(alertViewController, animated: true, completion: nil)
    }
}
