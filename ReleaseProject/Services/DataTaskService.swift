//
//  DataTaskService.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/07/05.
//

import RxSwift

enum DataTask {
    case updateCatName(String)
    case updateChartDateSection([ChartDateSection], DataPresentType)
    case updateData([DataModel])
    
}

protocol DataTaskServiceType {
    var event: PublishSubject<DataTask> { get }
    
    var currentDataPresentType: BehaviorSubject<DataPresentType> { get}
    var currentDate: BehaviorSubject<Date> { get}

    func catChanged() -> Observable<DataTask>
    func updateChartDateSection() -> Observable<DataTask>
    func updateData() -> Observable<DataTask>
}

final class DataTaskService: Service, DataTaskServiceType {
    
    let event = PublishSubject<DataTask>()
    
    let currentDataPresentType = BehaviorSubject<DataPresentType>(value: .week)
    let currentDate = BehaviorSubject<Date>(value: Date())
    
    func catChanged() -> Observable<DataTask> {
        return provider.catProvideService.fetchCat()
            .withUnretained(self)
            .flatMap { owner, cat -> Observable<DataTask> in
                return .just(.updateCatName(cat.catName))
            }
            .do { task in
                self.event.onNext(task)
            }
        
    }

    
    func updateChartDateSection() -> Observable<DataTask> {
        let fetch = provider.catProvideService.fetchCat()
        let type = currentDataPresentType.asObservable()
        
        return Observable.combineLatest(fetch, type)
            .withUnretained(self)
            .flatMap { owner, datas -> Observable<DataTask> in
                print(#function)
                print(datas.0.catName)
                let dates = owner.getDatesForPresentation(data: datas.0.dailyDataList.toArray(), dataPresentType: datas.1)
                let sectionItem = dates.map {ChartDateCellReactor(task: ChartDateCellModel(date: $0, presentType: datas.1))}
                let section = ChartDateSection(model: Void(), items: sectionItem)
                return .just(.updateChartDateSection([section], datas.1))
            }
            .do { task in
                self.event.onNext(task)
            }

    }
    
    func updateData() -> Observable<DataTask> {
        let fetch = provider.catProvideService.fetchCatWhenChanged()
        let date = currentDate.asObservable()
        let type = currentDataPresentType.asObservable()
        
        return Observable.combineLatest(fetch, date, type)
            .withUnretained(self)
            .flatMap { owner, datas -> Observable<DataTask> in
                print(#function)
                print(datas.0.catName)
                let data = owner.setDataByDataPresentType(dataPresentType: datas.2, cat: datas.0, dateBase: datas.1)
                return .just(.updateData(data))
            }
            .do { task in
                self.event.onNext(task)
            }
        
    }

    
}


//DataModel과 ChartDateSection을 정제하기 위한 지저분한 메서드들
extension DataTaskService {
    
    private func setDataByDataPresentType(dataPresentType: DataPresentType, cat: CatData, dateBase: Date) -> [DataModel] {
        switch dataPresentType {
        case .year:
            let data = cat.dailyDataList.filter("%@ <= date AND date <= %@ ", dateBase.startDayOfYear(), dateBase.endDayOfYear()).toArray()
            var result = [DataModel]()
            var poopAverage = Array(repeating: 0, count: 12)
            var urineAverage = Array(repeating: 0, count: 12)
            var monthTableForPoop: [Int: [Int]] = [:]
            var monthTableForUrine: [Int: [Int]] = [:]
            for i in data.indices {
                let poopCount = data[i].poopCount
                let urineCount = data[i].urineCount
                let month = Calendar.current.dateComponents([.month], from: data[i].date).month!
                if monthTableForPoop[month] == nil {
                    monthTableForPoop[month] = [poopCount]
                    monthTableForUrine[month] = [urineCount]
                } else {
                    monthTableForPoop[month]?.append(poopCount)
                    monthTableForUrine[month]?.append(urineCount)
                }
            }
            for i in 1...12 {
                if monthTableForPoop[i] == nil {
                    poopAverage[i - 1] = 0
                    urineAverage[i - 1] = 0
                } else {
                    let poop = monthTableForPoop[i]!.reduce(0) { $0 + $1 } / monthTableForPoop[i]!.count
                    let urine = monthTableForUrine[i]!.reduce(0) { $0 + $1 } / monthTableForUrine[i]!.count
                    poopAverage[i - 1] = poop
                    urineAverage[i - 1] = urine
                }
                result.append(DataModel(poopCount: poopAverage[i - 1], urineCount: urineAverage[i - 1], date: Calendar.current.date(byAdding: .month, value: i - 1, to: dateBase.startDayOfYear())! ))
            }
            return result
            
            
        case .month:
            let dates = getDatesBetween(from: dateBase.startDayOfMonth(), to: dateBase.endDayOfMonth())
            let dailyDataList = cat.dailyDataList.toArray()
            return dates.map { date -> DataModel in
                guard let data = dailyDataList.filter({ $0.date == date }).first else {
                    return DataModel(poopCount: 0, urineCount: 0, date: date)
                }
                return DataModel(poopCount: data.poopCount, urineCount: data.urineCount, date: date)
            }
        case .week:
            let dates = getDatesBetween(from: dateBase.startDayOfWeek(), to: dateBase.endDayOfWeek())
            let dailyDataList = cat.dailyDataList.toArray()
            return dates.map { date in
                guard let data = dailyDataList.filter({ $0.date == date}).first else {
                    return DataModel(poopCount: 0, urineCount: 0, date: date)
                }
                return DataModel(poopCount: data.poopCount, urineCount: data.urineCount, date: date)
            }
            
        }
        
    }
    
    private func getDatesForPresentation(data: [DailyData], dataPresentType: DataPresentType) -> [Date] {
        if data.isEmpty {
            return []
        }
        return getDatesBetween(by: dataPresentType, from: data.first!.date, to: data.last!.date)
    }
    
    private func getDatesBetween(from startDate: Date, to endDate: Date) -> [Date] {
        
        var result = [Date]()
        var tmp = startDate
        
        while tmp <= endDate {
            result.append(tmp)
            guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: tmp) else { break }
            tmp = newDate
        }
        return result
    }
    
    private func getDatesBetween(by dataPresentType: DataPresentType, from start: Date, to end: Date) -> [Date] {
        var allDates: [Date] = []
        guard start <= end else { return allDates }
        
        let calendar = Calendar.current
        switch dataPresentType {
        case .year:
            let year = calendar.dateComponents([.year], from: start.startDayOfYear(), to: end.endDayOfYear()).year ?? 1
            
            for i in 0...year {
                if let date = calendar.date(byAdding: .year, value: i, to: start) {
                    allDates.append(date)
                }
            }
        case .month:
            let month = calendar.dateComponents([.month], from: start.startDayOfMonth(), to: end.endDayOfMonth()).month ?? 1
            
            for i in 0...month {
                if let date = calendar.date(byAdding: .month, value: i, to: start) {
                    allDates.append(date)
                }
            }
        case .week:
            let week = calendar.dateComponents([.weekOfMonth], from: start.startDayOfWeek(), to: end.endDayOfWeek()).weekOfMonth ?? 1
            
            for i in 0...week {
                if let date = calendar.date(byAdding: .weekOfMonth, value: i, to: start) {
                    allDates.append(date)
                }
            }
        }
        return allDates
        
    }
}
