//
//  DataViewController.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/21.
//

import UIKit

import Charts
import RealmSwift
import ReactorKit
import RxDataSources
import RxCocoa

class DataViewController: UIViewController, StoryboardView {

    @IBOutlet weak var datesCollectionView: UICollectionView!
    @IBOutlet weak var dateDecreaseButton: UIButton!
    @IBOutlet weak var dateIncreaseButton: UIButton!
    @IBOutlet weak var dateTypeControl: UISegmentedControl!
    @IBOutlet weak var ChartView: CombinedChartView!
    
    var disposeBag: DisposeBag = DisposeBag()
    
    var dataSource = RxCollectionViewSectionedReloadDataSource<ChartDateSection> { dataSource, collectionView, indexPath, reactor in
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChartDateCollectionViewCell.identifier, for: indexPath) as! ChartDateCollectionViewCell
        
        cell.reactor = reactor
        return cell
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        reactor = DataViewReactor(provider: ServiceProvider())
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        reactor = DataViewReactor(provider: ServiceProvider())
    }
    
	
	override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        
    }
    
    private func configure() {
        datesCollectionView.delegate = self
        
        datesCollectionView.register(ChartDateCollectionViewCell.self, forCellWithReuseIdentifier: ChartDateCollectionViewCell.identifier)
        
        
        dataSource = RxCollectionViewSectionedReloadDataSource<ChartDateSection> { dataSource, collectionView, indexPath, reactor in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChartDateCollectionViewCell.identifier, for: indexPath) as! ChartDateCollectionViewCell
            
            cell.reactor = reactor
            return cell
        }
        
        dateTypeControl.setTitle("week", forSegmentAt: 0)
        dateTypeControl.setTitle("month", forSegmentAt: 1)
        dateTypeControl.setTitle("year", forSegmentAt: 2)
        
        //처음 진입할때 최근 데이터부터 보여주기 위해
        datesCollectionView.layoutIfNeeded()
        reactor?.action.onNext(.scrollToEnd)
        
    }
    
    func bind(reactor: DataViewReactor) {
        
        //StoryboardView일때 view가 load 된 후 bind가 call 되기 때문에
        Observable.just(Void())
            .map { _ in
                return Reactor.Action.refresh
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
//        datesCollectionView.rx.didScroll
//            .map {[weak self] Void -> Int in
//                guard let self = self else {return 0}
//                let offSet = self.datesCollectionView.contentOffset.x
//                let width = self.datesCollectionView.frame.width
//                let horizontalCenter = width / 2
//                let count = Int(offSet + horizontalCenter) / Int(width)
//                return count
//            }
//            .distinctUntilChanged()
//            .map { .dateSelected($0)}
//            .bind(to: reactor.action)
//            .disposed(by: disposeBag)
        
        //동작이 아닌 상태를 emit함(시작하면 refresh 없어도 emit)
        dateTypeControl.rx.selectedSegmentIndex
            .map { index -> Reactor.Action in
                let type: DataPresentType
                if index == 0 {
                    type = .week
                } else if index == 1 {
                    type = .month
                } else {
                    type = .year
                }
                return Reactor.Action.dataPresentTypeSelected(type)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        dateIncreaseButton.rx.tap
            .withUnretained(self)
            .map { owner, _ in
                let index = owner.datesCollectionView.inscreasingScroll()
                return Reactor.Action.dateChanged(index)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        dateDecreaseButton.rx.tap
            .withUnretained(self)
            .map { owner, _ in
                let index = owner.datesCollectionView.decreasingScroll()
                return Reactor.Action.dateChanged(index)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        
//        dateIncreaseButton.rx.tap
//            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
//            .map {Reactor.Action.dateIncrease}
//            .bind(to: reactor.action)
//            .disposed(by: disposeBag)
//
//        dateDecreaseButton.rx.tap
//            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
//            .map {Reactor.Action.dateDecrease}
//            .bind(to: reactor.action)
//            .disposed(by: disposeBag)
        
        reactor.state.asObservable().map { $0.sections }
            .bind(to: datesCollectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: disposeBag)
        
        reactor.state.asObservable().map { $0.catName }
            .bind(to: self.navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$scroll)
            .compactMap {$0}
            .subscribe {[weak self] _ in
                self?.datesCollectionView.scrollToEnd(animated: false)
            }
            .disposed(by: disposeBag)

        
//        reactor.state.asObservable().map { $0.currentDateIndex}
//            .distinctUntilChanged()
//            .subscribe(onNext: {[weak self] index in
//                let index = IndexPath(item: index - 1, section: 0)
//                self?.datesCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
//            })
//            .disposed(by: disposeBag)
        
//        reactor.state.asObservable().map { state -> Bool in
//            return state.totalDateCountInSections != state.currentDateIndex
//        }
//        .distinctUntilChanged()
//        .bind(to: dateIncreaseButton.rx.isEnabled)
//        .disposed(by: disposeBag)
        
//        reactor.state.asObservable().map { state -> Bool in
//            return state.currentDateIndex != 1
//        }
//        .distinctUntilChanged()
//        .bind(to: dateDecreaseButton.rx.isEnabled)
//        .disposed(by: disposeBag)
                
//        reactor.state.asObservable().map { $0.dataModel }
//            .distinctUntilChanged()
//            .subscribe { dataModel in
//                print(dataModel)
//            }
//            .disposed(by: disposeBag)
        

        
    }
    
}

extension DataViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        collectionView.bounds.size

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
}

//
//
//
//	@objc private func notificationMethod(notification: Notification) {
//		if notification.object != nil {
//			let newCat = notification.object as! String
//			mainCat = newCat
//		}
//	}
//
//	override func viewDidAppear(_ animated: Bool) {
//		super.viewDidAppear(animated)
//		if catData.count > 0 {
//			if chartView.data == nil {
//				monthPickerView.isHidden = false
//				setNavBar()
//			}
//            navigationController?.navigationBar.isHidden = false
//		} else {
//			chartView.data = nil
//			monthPickerView.isHidden = true
//        }
//	}
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        if !catData.isEmpty {
//            NotificationCenter.default.post(name: Notification.Name("CurrentIndex"), object: catData.index(of: catData.filter("catName == %@", mainCat!).first!))
//        }
//    }
//
//	func selectPickerView() {
//		if monthPickerView.numberOfComponents > 0 && monthPickerView.numberOfRows(inComponent: 0) > 0 {
//			monthPickerView.selectRow(listOfYearAndMonth.count - 1, inComponent: 0, animated: true)
//			pickerView(monthPickerView, didSelectRow: listOfYearAndMonth.count - 1, inComponent: 0)
//			monthPickerView.selectRow((listOfYearAndMonth.last?.months.count)! - 1, inComponent: 1, animated: true)
//			pickerView(monthPickerView, didSelectRow: (listOfYearAndMonth.last?.months.count)! - 1, inComponent: 1)
//			monthPickerView.reloadAllComponents()
//		}
//	}
//
//	func setNavBar() {
//        self.tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "list.dash"), style: .plain, target: self, action: #selector(showAlertForData))
//        self.tabBarController?.navigationItem.leftBarButtonItem = nil
//	}
//
//	func setListOfYearAndMonth(from catName: String) {
//		var list = [ListForMonthAndYear]()
//		guard let dataList = catData.filter("catName == %@", catName).first?.dailyDataList.sorted(byKeyPath: "date", ascending: true) else {return}
//		let listOfYear = getYearBetween(from: dataList.first!.date, to: dataList.last!.date)
//		for i in 0..<listOfYear.count {
//			let months: [Date]
//			let datesInYear = RealmService.shared.getDailyDates(of: catName, unit: .year, fromNow: i - (listOfYear.count - 1))
//			months = getMonthAndYearBetween(from: datesInYear.first!, to: datesInYear.last!)
//
//			list.append(ListForMonthAndYear(year: listOfYear[i], months: months))
//		}
//		listOfYearAndMonth = list
//		monthPickerView.reloadAllComponents()
//	}
//
//
//	func setChartConfigure() {
//		chartView.noDataText = "no_data_for_chart".localized(withComment: "")
//		chartView.noDataFont = .systemFont(ofSize: 24)
//		chartView.animate(yAxisDuration: 0.6, easingOption: .easeInSine)
//		chartView.xAxis.labelPosition = .bottom
//		chartView.xAxis.drawGridLinesEnabled = false
//		chartView.rightAxis.enabled = false
//		chartView.notifyDataSetChanged()
//
//	}
//
//
//	@objc func showAlertForData() {
//		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//		for i in 0..<catData.count {
//			let cat = catData[i].catName
//			alert.addAction(UIAlertAction(title: cat, style: .default, handler: { _ in
//				self.mainCat = cat
//			}))
//		}
//		let cancel = UIAlertAction(title: "cancel".localized(withComment: ""), style: .cancel, handler: nil)
//		alert.addAction(cancel)
//		self.present(alert, animated: true, completion: nil)
//	}
//
//}
//
//extension DataViewController: UIPickerViewDelegate, UIPickerViewDataSource {
//
//	func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
//		return 44
//	}
//
//	func numberOfComponents(in pickerView: UIPickerView) -> Int {
//		return 2
//	}
//
//	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//		switch component {
//		case 0:
//			return listOfYearAndMonth.count
//		case 1:
//			let selectedYear = pickerView.selectedRow(inComponent: 0)
//			if listOfYearAndMonth.indices.contains(selectedYear) {
//				return listOfYearAndMonth[selectedYear].months.count
//			} else {
//				return 0
//			}
//		default:
//			return 0
//		}
//	}
//
//	//사용자의 지역 및 언어에 따라 연월 순서 및 MM or MMMM설정할 필요가 있어보임
//	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//		switch component {
//		case 0:
//			let format = DateFormatter()
//			format.dateFormat = "yyyy"
//			return format.string(from: listOfYearAndMonth[row].year)
//		case 1:
//			let selectedYear = pickerView.selectedRow(inComponent: 0)
//			let format = DateFormatter()
//			format.dateFormat = "MM"
//			if listOfYearAndMonth[selectedYear].months.indices.contains(row) {
//				return format.string(from: listOfYearAndMonth[selectedYear].months[row])
//			} else {
//				return nil
//			}
//		default:
//			return nil
//		}
//	}
//
//
//	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//
//		switch component {
//		case 0:
//			pickerView.reloadComponent(1)
//		case 1:
//			let selectedYear = pickerView.selectedRow(inComponent: 0)
//			let year: Date
//			let month: Date
//			if listOfYearAndMonth.indices.contains(selectedYear) {
//				year = listOfYearAndMonth[selectedYear].year
//				if listOfYearAndMonth[selectedYear].months.indices.contains(row) {
//					month = listOfYearAndMonth[selectedYear].months[row]
//				} else {
//					return
//				}
//			} else {
//				return
//			}
//			let formatYear = DateFormatter()
//			let formatMonth = DateFormatter()
//			formatYear.dateFormat = "yyyy"
//			formatMonth.dateFormat = "MM"
//			let yearString = formatYear.string(from: year)
//			let monthString = formatMonth.string(from: month)
//			let dateString = "\(yearString)-\(monthString)"
//			let format = DateFormatter()
//			format.dateFormat = "yyyy-MM"
//			let date = format.date(from: dateString)
//			getDailyDataValue(of: mainCat!, at: date!)
//		default:
//			return
//		}
//	}
//
//	func getDailyDataValue(of catName: String, at date: Date) {
//		let dailyData = RealmService.shared.getMonthlyData(of: catName, at: date)
//		let poopCounts = dailyData.0
//		let urineCounts = dailyData.1
//		let dates = dailyData.2
//		setChart(poopCounts: poopCounts, urineCounts: urineCounts, dates: dates)
//	}
//
//	func setChart(poopCounts: [Int], urineCounts: [Int], dates: [Date] ) {
//
//		var poopChartEntry: [ChartDataEntry] = []
//		var urineChartEntry: [ChartDataEntry] = []
//
//		let format = DateFormatter()
//		format.dateFormat = "MM-dd"
//		var dateValues = [String]()
//
//		for i in 0..<dates.count {
//			let poopValue = ChartDataEntry(x: Double(i), y: Double(poopCounts[i]))
//			let urineValue = ChartDataEntry(x: Double(i), y: Double(urineCounts[i]))
//
//			poopChartEntry.append(poopValue)
//			urineChartEntry.append(urineValue)
//			dateValues.append(format.string(from: dates[i]))
//		}
//
//		chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: dateValues)
//		chartView.xAxis.granularity = 1
//		chartView.leftAxis.granularityEnabled = true
//		chartView.leftAxis.granularity = 1
//
//		let poopLine = LineChartDataSet(entries: poopChartEntry, label: "poop".localized(withComment: ""))
//		poopLine.colors = [NSUIColor.systemBrown]
//		poopLine.drawCirclesEnabled = true
//		poopLine.circleHoleRadius = 4.0
//		poopLine.circleRadius = 4.0
//		poopLine.circleColors = [NSUIColor.systemBrown]
//		poopLine.mode = .cubicBezier
//		poopLine.lineWidth = 4.0
//
//		let urineLine = LineChartDataSet(entries: urineChartEntry, label: "urine".localized(withComment: ""))
//		urineLine.colors = [NSUIColor.systemYellow]
//		urineLine.drawCirclesEnabled = true
//		urineLine.circleHoleRadius = 4.0
//		urineLine.circleRadius = 4.0
//		urineLine.circleColors = [NSUIColor.systemYellow]
//		urineLine.mode = .cubicBezier
//		urineLine.lineWidth = 4.0
//
//
//		let data = LineChartData()
//		data.addDataSet(poopLine)
//		data.addDataSet(urineLine)
//
//
//		chartView.data = data
//
//		let numFormat = NumberFormatter()
//		numFormat.minimumFractionDigits = 0
//		data.setValueFormatter(DefaultValueFormatter(formatter: numFormat))
//		data.setValueFont(.boldSystemFont(ofSize: 10))
//	}
//
//
//	func getMonthAndYearBetween(from start: Date, to end: Date) -> [Date] {
//		var allDates: [Date] = []
//		guard start <= end else { return allDates }
//
//		let calendar = Calendar.current
//		let month = calendar.dateComponents([.month], from: start.startDayOfMonth(), to: end.endDayOfMonth()).month ?? 1
//
//		for i in 0...month {
//			if let date = calendar.date(byAdding: .month, value: i, to: start) {
//				allDates.append(date)
//			}
//		}
//		return allDates
//	}
//
//	func getYearBetween(from start: Date, to end: Date) -> [Date] {
//		var allDates: [Date] = []
//		guard start <= end else { return allDates }
//
//		let calendar = Calendar.current
//		let year = calendar.dateComponents([.year], from: start.startDayOfYear(), to: end.endDayOfYear()).year ?? 1
//
//		for i in 0...year {
//			if let date = calendar.date(byAdding: .year, value: i, to: start) {
//				allDates.append(date)
//			}
//		}
//		return allDates
//	}
//
//}
//
//class ListForMonthAndYear {
//
//	var year: Date
//	var months: [Date]
//
//	init(year: Date, months: [Date]) {
//		self.year = year
//		self.months = months
//	}
//}
