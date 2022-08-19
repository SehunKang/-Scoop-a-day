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
    @IBOutlet weak var chartView: CombinedChartView!
    
    var disposeBag: DisposeBag = DisposeBag()
    
    var dataSource = RxCollectionViewSectionedReloadDataSource<ChartDateSection> { dataSource, collectionView, indexPath, reactor in
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChartDateCollectionViewCell.identifier, for: indexPath) as! ChartDateCollectionViewCell
        
        cell.reactor = reactor
        return cell
    }
    
    
    init?(coder: NSCoder, reactor: DataViewReactor) {
        super.init(coder: coder)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        chartConfigure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if datesCollectionView.currentIndex == datesCollectionView.numberOfItems(inSection: 0) - 1{
            
        }
    }
    
    private func configure() {
        datesCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        datesCollectionView.register(ChartDateCollectionViewCell.self, forCellWithReuseIdentifier: ChartDateCollectionViewCell.identifier)
        
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
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .withUnretained(self)
            .map { owner, _ in
                let index = owner.datesCollectionView.increaseScroll()
                return Reactor.Action.dateChanged(index)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        dateDecreaseButton.rx.tap
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .withUnretained(self)
            .map { owner, _ in
                let index = owner.datesCollectionView.decreaseScroll()
                return Reactor.Action.dateChanged(index)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.asObservable().map { $0.sections }
            .bind(to: datesCollectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: disposeBag)
        
        reactor.state.asObservable().map { $0.catName }
            .bind(to: self.navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$scroll)
            .compactMap {$0}
            .withUnretained(self)
            .subscribe { owner, _ in
                owner.datesCollectionView.scrollToEnd(animated: false)
            }
            .disposed(by: disposeBag)
        
        reactor.state.asObservable().map { $0.dataModel }
            .withUnretained(self)
            .subscribe { owner, model in
                owner.setChart(dataPresentType: reactor.currentState.dataPresentType, data: model)
            }
            .disposed(by: disposeBag)
        
        let buttonDisabler = datesCollectionView.rx.didScroll
            .withUnretained(self)
            .map { owner, _ in
                owner.datesCollectionView.currentIndex
            }
            .distinctUntilChanged()
            .share()
        
        buttonDisabler
            .withUnretained(self)
            .map { owner, count -> Bool in
                let max = owner.datesCollectionView.numberOfItems(inSection: 0) - 1
                return max != count
            }
            .bind(to: dateIncreaseButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        buttonDisabler
            .withUnretained(self)
            .map { owner, count -> Bool in
                return count != 0
            }
            .bind(to: dateDecreaseButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
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

extension DataViewController {
    
    private func chartConfigure() {
        
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.leftAxis.labelFont = .preferredFont(forTextStyle: .caption1)
        chartView.rightAxis.enabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.pinchZoomEnabled = false
        
    }
    
    private func setChart(dataPresentType: DataPresentType, data: [DataModel]) {
        
        let format = DateFormatter()
        let chartData = CombinedChartData()

        switch dataPresentType {
            
        case .year:
            var poopChartEntry: [BarChartDataEntry] = []
            var urineChartEntry: [BarChartDataEntry] = []
            format.dateFormat = "MMM"
            var dateValues = [String]()
            
            for i in 0..<data.count {
                poopChartEntry.append(
                    BarChartDataEntry(
                        x: Double(i),
                        y: Double(data[i].poopCount))
                )
                urineChartEntry.append(
                    BarChartDataEntry(
                        x: Double(i), y: Double(data[i].urineCount))
                )
                dateValues.append(
                    format.string(from: data[i].date)
                )
            }
            chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: dateValues)
            chartView.xAxis.granularity = 1
//            chartView.xAxis.setLabelCount(data.count, force: true)
            chartView.leftAxis.granularity = 1
            chartView.xAxis.centerAxisLabelsEnabled = true
            chartView.xAxis.axisMaximum = 12
            
            let poopChart = BarChartDataSet(entries: poopChartEntry, label: Strings.local.poop)
            poopChart.colors = [NSUIColor.systemBrown]
            poopChart.drawValuesEnabled = false
            
            let urineChart = BarChartDataSet(entries: urineChartEntry, label: Strings.local.pee)
            urineChart.colors = [NSUIColor.systemYellow]
            urineChart.drawValuesEnabled = false
            
            chartData.barData = BarChartData(arrayLiteral: poopChart, urineChart)
            
            let groupSpace = 0.3
            let barSpace = 0.05
            let barWidth = 0.3
            
            chartData.barData.barWidth = barWidth
            chartData.barData.groupBars(fromX: 0, groupSpace: groupSpace, barSpace: barSpace)
            chartView.data = chartData
            
        case .month:
            var poopChartEntry: [ChartDataEntry] = []
            var urineChartEntry: [ChartDataEntry] = []
            format.dateFormat = "dd"
            var dateValues = [String]()
            
            for i in 0..<data.count {
                poopChartEntry.append(
                    ChartDataEntry(
                        x: Double(i),
                        y: Double(data[i].poopCount))
                )
                urineChartEntry.append(
                    ChartDataEntry(
                        x: Double(i), y: Double(data[i].urineCount))
                )
                dateValues.append(
                    format.string(from: data[i].date)
                )
            }
            chartView.xAxis.resetCustomAxisMax()
            chartView.xAxis.centerAxisLabelsEnabled = false
            chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: dateValues)
            chartView.xAxis.setLabelCount(15, force: false)
            
            let poopChart = LineChartDataSet(entries: poopChartEntry, label: Strings.local.poop)
            poopChart.colors = [NSUIColor.systemBrown]
            poopChart.drawCirclesEnabled = false
            poopChart.mode = .horizontalBezier
            poopChart.lineWidth = 4.0
            poopChart.drawValuesEnabled = false
            
            let urineChart = LineChartDataSet(entries: urineChartEntry, label: Strings.local.pee)
            urineChart.colors = [NSUIColor.systemYellow]
            urineChart.drawCirclesEnabled = false
            urineChart.mode = .horizontalBezier
            urineChart.lineWidth = 4.0
            urineChart.drawValuesEnabled = false

            chartData.lineData = LineChartData(arrayLiteral: poopChart, urineChart)
            chartView.data = chartData
            
        case .week:
            var poopChartEntry: [BarChartDataEntry] = []
            var urineChartEntry: [BarChartDataEntry] = []
            format.dateFormat = "E"
            var dateValues = [String]()
            
            for i in 0..<data.count {
                poopChartEntry.append(
                    BarChartDataEntry(
                        x: Double(i),
                        y: Double(data[i].poopCount))
                )
                urineChartEntry.append(
                    BarChartDataEntry(
                        x: Double(i), y: Double(data[i].urineCount))
                )
                dateValues.append(
                    format.string(from: data[i].date)
                )
            }
            chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: dateValues)
//            chartView.xAxis.granularity = 1
//            chartView.xAxis.setLabelCount(7, force: true)
            chartView.leftAxis.granularity = 1
            chartView.xAxis.centerAxisLabelsEnabled = true
            chartView.xAxis.axisMaximum = 7
            
            let poopChart = BarChartDataSet(entries: poopChartEntry, label: Strings.local.poop)
            poopChart.colors = [NSUIColor.systemBrown]
            poopChart.drawValuesEnabled = false
            
            let urineChart = BarChartDataSet(entries: urineChartEntry, label: Strings.local.pee)
            urineChart.colors = [NSUIColor.systemYellow]
            urineChart.drawValuesEnabled = false
            
            chartData.barData = BarChartData(arrayLiteral: poopChart, urineChart)
            
            let groupSpace = 0.3
            let barSpace = 0.05
            let barWidth = 0.3
            
            chartData.barData.barWidth = barWidth
            chartData.barData.groupBars(fromX: 0, groupSpace: groupSpace, barSpace: barSpace)
            chartView.data = chartData

        }
        let numFormat = NumberFormatter()
        numFormat.minimumFractionDigits = 0
        chartData.setValueFormatter(DefaultValueFormatter(formatter: numFormat))
        chartData.setValueFont(.boldSystemFont(ofSize: 10))
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        
    }
}

extension DataViewController: Localized {
    struct Strings {
        static let local = Localization.DataView.self
    }
}
