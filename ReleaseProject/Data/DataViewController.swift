//
//  DataViewController.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/21.
//

import UIKit
import Charts
import RealmSwift

class DataViewController: UIViewController {

	@IBOutlet weak var chartView: BarChartView!
	
	@IBOutlet weak var monthPickerView: UIPickerView!
	@IBOutlet weak var navigationBar: UINavigationBar!
	
	var listOfYearAndMonth = [ListForMonthAndYear]()
	
	var mainCat: String? {
		didSet {
			setListOfYearAndMonth(from: mainCat!)
			navigationBar.topItem?.title = mainCat!
			selectPickerView()
			setNavBar()
		}
	}
	
	var catData: Results<CatData>!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let realm = RealmService.shared.realm
		catData = realm.objects(CatData.self).sorted(byKeyPath: "createDate", ascending: true)
		monthPickerView.delegate = self
		monthPickerView.dataSource = self
		NotificationCenter.default.addObserver(self, selector: #selector(notificationMethod(notification:)), name: Notification.Name("NotificationIdentifier"), object: nil)
		setChartConfigure()
    }
	
	@objc func notificationMethod(notification: Notification) {
		if notification.object != nil {
			let newCat = notification.object as! String
			mainCat = newCat
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if catData.count > 0 {
			if chartView.data == nil {
				monthPickerView.isHidden = false
				setNavBar()
			}
			navigationBar.isHidden = false
		} else {
			chartView.data = nil
			monthPickerView.isHidden = true
			navigationBar.isHidden = true
		}
	}
	
	func selectPickerView() {
		if monthPickerView.numberOfComponents > 0 && monthPickerView.numberOfRows(inComponent: 0) > 0 {
			monthPickerView.selectRow(listOfYearAndMonth.count - 1, inComponent: 0, animated: true)
			pickerView(monthPickerView, didSelectRow: listOfYearAndMonth.count - 1, inComponent: 0)
			monthPickerView.selectRow((listOfYearAndMonth.last?.months.count)! - 1, inComponent: 1, animated: true)
			pickerView(monthPickerView, didSelectRow: (listOfYearAndMonth.last?.months.count)! - 1, inComponent: 1)
			monthPickerView.reloadAllComponents()
		}
	}
	
	func setNavBar() {
		navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "list.dash"), style: .plain, target: self, action: #selector(showAlertForData))

	}
		
	func setListOfYearAndMonth(from catName: String) {
		var list = [ListForMonthAndYear]()
		guard let dataList = catData.filter("catName == %@", catName).first?.dailyDataList.sorted(byKeyPath: "date", ascending: true) else {return}
		print("dataList: ", dataList)
		let listOfYear = getYearBetween(from: dataList.first!.date, to: dataList.last!.date)
		print("listofYear: ", listOfYear)
		for i in 0..<listOfYear.count {
			let months: [Date]
			let datesInYear = RealmService.shared.getDailyDates(of: catName, unit: .year, fromNow: i - (listOfYear.count - 1))
			print("datesInYear: ", datesInYear)
			months = getMonthAndYearBetween(from: datesInYear.first!, to: datesInYear.last!)
			
			print("months: ", months)
			list.append(ListForMonthAndYear(year: listOfYear[i], months: months))
		}
		listOfYearAndMonth = list
		monthPickerView.reloadAllComponents()
	}
	
	
	func setChartConfigure() {
		chartView.noDataText = "no_data_for_chart".localized(withComment: "")
		chartView.noDataFont = .systemFont(ofSize: 24)
		chartView.animate(yAxisDuration: 0.6, easingOption: .easeInSine)
		chartView.xAxis.labelPosition = .bottom
		chartView.xAxis.drawGridLinesEnabled = false
		chartView.rightAxis.enabled = false
		chartView.notifyDataSetChanged()
	
	}
	
	
	@objc func showAlertForData() {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		for i in 0..<catData.count {
			let cat = catData[i].catName
			alert.addAction(UIAlertAction(title: cat, style: .default, handler: { _ in
				self.mainCat = cat
			}))
		}
		let cancel = UIAlertAction(title: "cancel".localized(withComment: ""), style: .cancel, handler: nil)
		alert.addAction(cancel)
		self.present(alert, animated: true, completion: nil)
	}
	
	
}

extension DataViewController: UIPickerViewDelegate, UIPickerViewDataSource {
	
	func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
		return 44
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 2
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		switch component {
		case 0:
			return listOfYearAndMonth.count
		case 1:
			let selectedYear = pickerView.selectedRow(inComponent: 0)
			if listOfYearAndMonth.indices.contains(selectedYear) {
				return listOfYearAndMonth[selectedYear].months.count
			} else {
				return 0
			}
		default:
			return 0
		}
	}
	
	//사용자의 지역 및 언어에 따라 연월 순서 및 MM or MMMM설정할 필요가 있어보임
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		switch component {
		case 0:
			let format = DateFormatter()
			format.dateFormat = "yyyy"
			return format.string(from: listOfYearAndMonth[row].year)
		case 1:
			let selectedYear = pickerView.selectedRow(inComponent: 0)
			let format = DateFormatter()
			format.dateFormat = "MM"
			if listOfYearAndMonth[selectedYear].months.indices.contains(row) {
				return format.string(from: listOfYearAndMonth[selectedYear].months[row])
			} else {
				return nil
			}
		default:
			return nil
		}
	}
	
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		
		switch component {
		case 0:
			pickerView.reloadComponent(1)
		case 1:
			let selectedYear = pickerView.selectedRow(inComponent: 0)
			let year: Date
			let month: Date
			if listOfYearAndMonth.indices.contains(selectedYear) {
				year = listOfYearAndMonth[selectedYear].year
				if listOfYearAndMonth[selectedYear].months.indices.contains(row) {
					month = listOfYearAndMonth[selectedYear].months[row]
				} else {
					return
				}
			} else {
				return
			}
			let formatYear = DateFormatter()
			let formatMonth = DateFormatter()
			formatYear.dateFormat = "yyyy"
			formatMonth.dateFormat = "MM"
			let yearString = formatYear.string(from: year)
			let monthString = formatMonth.string(from: month)
			let dateString = "\(yearString)-\(monthString)"
			let format = DateFormatter()
			format.dateFormat = "yyyy-MM"
			let date = format.date(from: dateString)
			getDailyDataValue(of: mainCat!, at: date!)
		default:
			return
		}
	}
	
	func getDailyDataValue(of catName: String, at date: Date) {
		let dailyData = RealmService.shared.getMonthlyData(of: catName, at: date)
		let poopCounts = dailyData.0
		let urineCounts = dailyData.1
		let dates = dailyData.2
		setChart(poopCounts: poopCounts, urineCounts: urineCounts, dates: dates)
	}

	func setChart(poopCounts: [Int], urineCounts: [Int], dates: [Date] ) {

		var poopChartEntry: [ChartDataEntry] = []
		var urineChartEntry: [ChartDataEntry] = []
		
		let format = DateFormatter()
		format.dateFormat = "MM-dd"
		var dateValues = [String]()
		
		for i in 0..<dates.count {
			let poopValue = ChartDataEntry(x: Double(i), y: Double(poopCounts[i]))
			let urineValue = ChartDataEntry(x: Double(i), y: Double(urineCounts[i]))
			
			poopChartEntry.append(poopValue)
			urineChartEntry.append(urineValue)
			dateValues.append(format.string(from: dates[i]))
		}
		
		chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: dateValues)
		chartView.xAxis.granularity = 1
		chartView.leftAxis.granularityEnabled = true
		chartView.leftAxis.granularity = 1
		
		let poopLine = LineChartDataSet(entries: poopChartEntry, label: "poop".localized(withComment: ""))
		poopLine.colors = [NSUIColor.systemBrown]
		poopLine.drawCirclesEnabled = false
		poopLine.mode = .cubicBezier
		poopLine.lineWidth = 4.0
		
		let urineLine = LineChartDataSet(entries: urineChartEntry, label: "urine".localized(withComment: ""))
		urineLine.colors = [NSUIColor.systemYellow]
		urineLine.drawCirclesEnabled = false
		urineLine.mode = .cubicBezier
		urineLine.lineWidth = 4.0

		
		let data = LineChartData()
		data.addDataSet(poopLine)
		data.addDataSet(urineLine)
				
		chartView.data = data
	}
	
	
	func getMonthAndYearBetween(from start: Date, to end: Date) -> [Date] {
		var allDates: [Date] = []
		guard start <= end else { return allDates }
		
		let calendar = Calendar.current
		let month = calendar.dateComponents([.month], from: start.startDayOfMonth(), to: end.endDayOfMonth()).month ?? 1
		print("month in gMAYB: ", month)
		
		for i in 0...month {
			if let date = calendar.date(byAdding: .month, value: i, to: start) {
				allDates.append(date)
			}
		}
		return allDates
	}
	
	func getYearBetween(from start: Date, to end: Date) -> [Date] {
		var allDates: [Date] = []
		guard start <= end else { return allDates }
		
		let calendar = Calendar.current
		let year = calendar.dateComponents([.year], from: start, to: end).year ?? 1
		
		for i in 0...year {
			if let date = calendar.date(byAdding: .year, value: i, to: start) {
				allDates.append(date)
			}
		}
		return allDates
	}
	
}

class ListForMonthAndYear {
	
	var year: Date
	var months: [Date]
	
	init(year: Date, months: [Date]) {
		self.year = year
		self.months = months
	}
}
