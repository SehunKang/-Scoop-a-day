//
//  DataViewModel.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/06/22.
//

import Foundation

import ReactorKit
import RxSwift
import RxCocoa
import RxDataSources


enum DataPresentType {
    case year
    case month
    case week
}

typealias ChartDateSection = SectionModel<Void, ChartDateCellReactor>

class DataViewReactor: Reactor {
    
    enum Action {
        case refresh
        case dateSelected(Int)
        case dataPresentTypeSelected(DataPresentType)
        //        case dateIncrease
        //        case dateDecrease
        //        case catSelected(Int)
    }
    
    enum Mutation {
        case setCat(String)
        case setSection([ChartDateSection])
        case setData([DataModel])
        case dataPresentTypeSelected(DataPresentType)
        //        case setDatesForChartHeader([ChartDateSection])
        //        case setDataForChart([DataModel])
        //        case datePickerSelected
        //        case dateIncrease
        //        case dateDecrease
        //        case catSelected(CatData)
    }
    
    struct State {
        var currentIndexOfCat: Int
        var currentCat: String
        var dataPresentType: DataPresentType
        var datesCollection: [Date]
        var dataModel: [DataModel]
        var sections: [ChartDateSection]
        
    }
    
    let initialState: State
    
    let realmService: RealmServiceTypeForDataView
    
    init(realmService: RealmServiceTypeForDataView, currentIndexOfCat: Int = 0) {
        self.realmService = realmService
        
        self.initialState = State(currentIndexOfCat: currentIndexOfCat,
                                  currentCat: "",
                                  dataPresentType: .week,
                                  datesCollection: [],
                                  dataModel: [],
                                  sections: [])
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        let state = currentState
        switch action {
        case .refresh:
            return self.realmService.taskOn()
                .filter {!$0.isEmpty}
                .withUnretained(self)
                .map {owner, result -> (String, [ChartDateSection]) in
                    let catData = result.toArray()[state.currentIndexOfCat]
                    let name = catData.catName
                    let dates = owner.getDatesForPresentation(data: catData.dailyDataList.toArray() , dataPresentType: state.dataPresentType)
                    let sectionItem = dates.map { ChartDateCellReactor(task: ChartDateCellModel(date: $0, presentType: state.dataPresentType)) }
                    let section = ChartDateSection(model: Void(), items: sectionItem)
                    return (name, [section])
                }
                .flatMap { (name, section) -> Observable<Mutation> in
                    Observable.concat([
                        Observable.just(.setCat(name)),
                        Observable.just(.setSection(section))
                    ])
                }
        case let .dateSelected(index):
            return self.realmService.taskOn()
                .filter {!$0.isEmpty}
                .map { result -> CatData in
                    result.toArray()[state.currentIndexOfCat]
                }
                .withUnretained(self)
                .flatMap { owner, catData -> Observable<Mutation> in
                    let date = state.sections.first!.items[index].initialState.date
                    let data = owner.setDataByDataPresentType(dataPresentType: state.dataPresentType, cat: catData, dateBase: date)
                    print(data)
                    return Observable.just(.setData(data))
                }
        case let .dataPresentTypeSelected(type):
            return self.realmService.taskOn()
                .filter {!$0.isEmpty}
                .withUnretained(self)
                .map { owner, result -> [ChartDateSection] in
                    let catData = result.toArray()[state.currentIndexOfCat]
                    let dates = owner.getDatesForPresentation(data: catData.dailyDataList.toArray() , dataPresentType: type)
                    let sectionItem = dates.map { ChartDateCellReactor(task: ChartDateCellModel(date: $0, presentType: type)) }
                    let section = ChartDateSection(model: Void(), items: sectionItem)
                    return [section]
                }
                .flatMap { section -> Observable<Mutation> in
                        .concat([
                            Observable.just(.setSection(section)),
                            Observable.just(.dataPresentTypeSelected(type))
                        ])
                }
            
        }
        
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .setCat(catName):
            state.currentCat = catName
        case let .setSection(section):
            state.sections = section
        case let .setData(data):
            state.dataModel = data
        case let .dataPresentTypeSelected(type):
            state.dataPresentType = type
            //        case .setDatesForChartHeader(let array):
            //            <#code#>
            //        case .setDataForChart(let array):
            //            <#code#>
        }
        return state
    }
    
}

//날짜에 따른 데이터 정제를 위한 메서드들
extension DataViewReactor {
    
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
                result.append(DataModel(poopCount: poopAverage[i - 1], urineCount: urineAverage[i - 1], date: Calendar.current.date(byAdding: .month, value: i - 1, to: Date().startDayOfYear())! ))
            }
            return result
            
            
        case .month:
            let dates = getDatesBetween(from: dateBase.startDayOfMonth(), to: dateBase.endDayOfMonth())
            return dates.map { date -> DataModel in
                guard let data = cat.dailyDataList.filter({ $0.date == date }).first else {
                    return DataModel(poopCount: 0, urineCount: 0, date: date)
                }
                return DataModel(poopCount: data.poopCount, urineCount: data.urineCount, date: date)
            }
        case .week:
            let dates = getDatesBetween(from: dateBase.startDayOfWeek(), to: dateBase.endDayOfWeek())
            return dates.map { date in
                guard let data = cat.dailyDataList.filter({ $0.date == date }).first else {
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
