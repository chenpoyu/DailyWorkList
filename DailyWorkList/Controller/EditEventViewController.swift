//
//  EditEventViewController.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/14.
//  Copyright © 2018年 poyu. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class EditEventViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    let sqlManager = (UIApplication.shared.delegate as! AppDelegate).sqlManager
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var execTime: UITextField!
    @IBOutlet weak var categoryPicker: UITextField!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var finishSwitch: UISwitch!
    @IBOutlet weak var placeText: UITextField!
    @IBOutlet weak var noteText: UITextView!
    
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
    
    var event_id: Int64?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // 增加一個觸控事件
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        // 加在最基底的 self.view 上
        scrollView.addGestureRecognizer(tap)
        
        // 設置時間顯示的格式
        showDateFormatter.dateFormat = "yyyy-MM-dd"
        showTimeFormatter.dateFormat = "HH:mm"
        dateFormatter.dateFormat = "yyyyMMdd"
        timeFormatter.dateFormat = "HHmm"
        
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
        
        initData()
    }
    
    func initData() {
        if event_id != nil {
            let eventArray = sqlManager.queryEventById(id: event_id!)
            if eventArray.count == 1 {
                nameText.text = eventArray[0].name
                
                let date = dateFormatter.date(from: eventArray[0].day)!
                dateLabel.text = showDateFormatter.string(from: date)
                
                if eventArray[0].time != nil && eventArray[0].time != "" {
                    timePicker.date = timeFormatter.date(from: eventArray[0].time!)!
                    changeExecTime()
                }
                
                if let codeIndex = pickerData.index(where: {$0.code == eventArray[0].category}) {
                    categoryCode = pickerData[codeIndex].code
                    categoryPicker.text = pickerData[codeIndex].name
                    self.pickerView.selectRow(codeIndex, inComponent: 0, animated: false)
                }
                reminderSwitch.isOn = eventArray[0].reminder
                finishSwitch.isOn = eventArray[0].finish
                placeText.text = eventArray[0].place
                lat = eventArray[0].lat
                lng = eventArray[0].lng
                noteText.text = eventArray[0].note
            } else {
                confirmAlert("Error when get the event info!")
                dismiss(animated: true, completion: nil)
            }
        } else {
            confirmAlert("Cannot get the event info!")
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func changeExecTime() {
        execTime.text = showTimeFormatter.string(from: timePicker.date)
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
        modifyHeightWithKeyboard(notification: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        modifyHeightWithKeyboard(notification: nil)
        return true
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
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        if nameText.text! == "" {
            confirmAlert("Name is required!")
        } else {
            // 若有設定時間，才寫入HHMi格式，否則為nil
            var execTimeText: String? = nil
            if execTime.text != "" {
                execTimeText = timeFormatter.string(from: timePicker.date)
            }
            
            sqlManager.updateEventById(id: event_id!, name: nameText.text!, time: execTimeText, category: categoryCode, reminder: reminderSwitch.isOn, place: placeText.text, lat: lat, lng: lng, note: noteText.text, finish: finishSwitch.isOn)
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func confirmAlert(_ message: String) {
        let alertViewController = UIAlertController(title: "Warn!", message: message, preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
        }))
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // popover segue
        if segue.identifier == "photoSegue" {
            let popoverViewController = segue.destination as! PhotoViewController
            popoverViewController.event_id = event_id
        } else if segue.identifier == "videoSegue" {
            let popoverViewController = segue.destination as! VideoViewController
            popoverViewController.event_id = event_id
        } else if segue.identifier == "musicSegue" {
            let popoverViewController = segue.destination as! MusicViewController
            popoverViewController.event_id = event_id
        }
    }
}
