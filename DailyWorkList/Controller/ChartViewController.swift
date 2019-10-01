//
//  ChartViewController.swift
//  DailyWorkList
//
//  Created by poyuchen on 2018/10/24.
//  Copyright © 2018年 poyu. All rights reserved.
//

import Foundation
import UIKit
import Charts

class ChartViewController: UIViewController {
    let sqlManager = (UIApplication.shared.delegate as! AppDelegate).sqlManager
    
    @IBOutlet weak var showView: UIView!
    var chartsHeight: Int = 500
    let spacesHeight: Int = 200
    let x: Int = 0
    var viewWidth: Int = 0
    
    @IBOutlet weak var calendarTitle: UILabel!
    @IBOutlet weak var chartsType: UISegmentedControl!
    
    let monthTitle = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    var currentYear = Calendar.current.component(.year, from: Date())
    var currentMonth = Calendar.current.component(.month, from: Date())
    var currentYM: String {
        if currentMonth < 10 {
            return "\(currentYear)0\(currentMonth)"
        } else {
            return "\(currentYear)\(currentMonth)"
        }
    }
    var daysCount: Int {
        // 設定目前月份
        let dateComponents = DateComponents(year: currentYear, month: currentMonth)
        let date = Calendar.current.date(from: dateComponents)!
        // 取得該月份天數
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
    }
    
    var moodEntries: [BarChartDataEntry] = []
    var waterEntries: [BarChartDataEntry] = []
    var exerciseEntries: [ChartDataEntry] = []
    var categoryEntries: [PieChartDataEntry] = []
    var categoryDict: [Int : String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewWidth = Int(showView.frame.width)
        chartsHeight = Int(showView.frame.height) / 2 - 50
        
        if let path = Bundle.main.path(forResource: "Category", ofType: "plist"),
            let array = NSArray(contentsOfFile: path) {
            // Use your myDict here
            for case let category as NSDictionary in array {
                categoryDict[category.object(forKey: "code") as! Int] = category.object(forKey: "name") as? String
            }
        }
        
        changeMonth(value: 0)
    }
    
    @IBAction func changeCharts(_ sender: UISegmentedControl) {
        drawCharts()
    }
    
    @IBAction func previousMonth(_ sender: UIButton) {
        changeMonth(value: -1)
    }
    
    @IBAction func nextMonth(_ sender: UIButton) {
        changeMonth(value: 1)
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
        
        let dayChangeDict = sqlManager.queryDayByMonth(month: currentYM)
        moodEntries.removeAll()
        waterEntries.removeAll()
        exerciseEntries.removeAll()
        for i in 1...daysCount {
            var date: String!
            if i < 10 {
                date = "\(currentYM)0\(i)"
            } else {
                date = "\(currentYM)\(i)"
            }
            moodEntries.append(BarChartDataEntry(x: Double(i), y: Double(dayChangeDict[date]?.mood ?? 0)))
            waterEntries.append(BarChartDataEntry(x: Double(i), y: Double(dayChangeDict[date]?.water ?? 0)))
            exerciseEntries.append(ChartDataEntry(x: Double(i), y: Double(dayChangeDict[date]?.exercise ?? 0)))
        }
        
        let eventCategoryDict = sqlManager.queryEventCategoryByMonth(month: currentYM)
        categoryEntries.removeAll()
        for (k, v) in eventCategoryDict {
            categoryEntries.append(PieChartDataEntry(value: Double(v), label: categoryDict[k]))
        }

        drawCharts()
    }
    
    func drawCharts() {
        showView.subviews.forEach({ $0.removeFromSuperview()})
        if chartsType.selectedSegmentIndex == 0 {
            // 心情 長條圖
            let dayMoodChart = BarChartView(frame: CGRect(x: x, y: 10, width: viewWidth, height: chartsHeight))
            dayMoodChart.noDataText = "You Need to Provide Your Daily Events."
            
            let moodChartDataSet = BarChartDataSet(values: moodEntries, label: "Mood")
            moodChartDataSet.colors = [UIColor.red]
            moodChartDataSet.drawValuesEnabled = false
            
            let chartData = BarChartData(dataSet: moodChartDataSet)
            dayMoodChart.data = chartData
            dayMoodChart.chartDescription?.text = ""
            dayMoodChart.rightAxis.enabled = false
            dayMoodChart.xAxis.labelPosition = .bottom
            dayMoodChart.setVisibleYRange(minYRange: 0.0, maxYRange: 6.0, axis: YAxis.AxisDependency.right)
            dayMoodChart.leftAxis.labelCount = 6
            
            dayMoodChart.animate(xAxisDuration: 1.0)
            
            // 水、運動 複合圖（長條加折線）
            let dayWaterExerciseChart = CombinedChartView(frame: CGRect(x: x, y: chartsHeight + 50, width: viewWidth, height: chartsHeight))
            dayWaterExerciseChart.noDataText = "You Need to Provide Your Daily Events."
            
            let waterChartDataSet = BarChartDataSet(values: waterEntries, label: "Water")
            waterChartDataSet.colors = [UIColor.blue]
            waterChartDataSet.drawValuesEnabled = false
            let barChartData = BarChartData(dataSet: waterChartDataSet)
            
            let exerciseChartDataSet = LineChartDataSet(values: exerciseEntries, label: "Exercise")
            exerciseChartDataSet.colors = [UIColor.brown]
            exerciseChartDataSet.drawValuesEnabled = false
            exerciseChartDataSet.circleColors = [UIColor.brown]
            exerciseChartDataSet.circleRadius = 3
            let lineChartData = LineChartData(dataSet: exerciseChartDataSet)
            
            let combinedChartData = CombinedChartData()
            combinedChartData.barData = barChartData
            combinedChartData.lineData = lineChartData
            
            dayWaterExerciseChart.data = combinedChartData
            dayWaterExerciseChart.chartDescription?.text = ""
            dayWaterExerciseChart.rightAxis.enabled = false
            dayWaterExerciseChart.xAxis.labelPosition = .bottom
            dayWaterExerciseChart.setVisibleYRange(minYRange: 0.0, maxYRange: 6.0, axis: YAxis.AxisDependency.right)
            dayWaterExerciseChart.leftAxis.labelCount = 6
            
            dayWaterExerciseChart.animate(xAxisDuration: 1.0)
            
            showView.addSubview(dayMoodChart)
            showView.addSubview(dayWaterExerciseChart)
        } else if chartsType.selectedSegmentIndex == 1 {
            let eventCategoryChart = PieChartView(frame: CGRect(x: x, y: 10, width: viewWidth, height: chartsHeight*2))
            eventCategoryChart.noDataText = "You Need to Provide Your Daily Events."
            if categoryEntries.count > 0 {
                eventCategoryChart.chartDescription?.text = ""

                let chartDataSet = PieChartDataSet(values: categoryEntries, label: "")
                let chartData = PieChartData(dataSet: chartDataSet)
                
                var colors: [UIColor] = []
                for _ in 0..<categoryEntries.count {
                    colors.append(UIColor.init(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0))
                }
                chartDataSet.colors = colors
                
                eventCategoryChart.data = chartData
            }
            showView.addSubview(eventCategoryChart)
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
