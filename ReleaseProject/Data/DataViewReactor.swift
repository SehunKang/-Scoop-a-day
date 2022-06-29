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


enum DataPresentType {
    case year
    case month
    case week
}

struct DataModel {
    
    let poopCount: Int
    let urineCount: Int
    let date: Date
    
}

class DataViewReactor: Reactor {
    
    enum Action {
        case refresh
//        case datePickerSelected(DataPresentType)
//        case catSelected(Int)
    }
    
    enum Mutation {
        case refresh([DataModel], String)
//        case datePickerSelected
//        case catSelected(CatData)
    }
    
    struct State {
        var currentIndexOfCat: Int
        var currentCat: String
        var dataPresentType: DataPresentType
        var dataModel: [DataModel]
        
    }
    
    let initialState: State
    
    let realmService: RealmServiceTypeForDataView
    
    init(realmService: RealmServiceTypeForDataView, currentIndexOfCat: Int = 0) {
        self.realmService = realmService
        
        self.initialState = State(currentIndexOfCat: currentIndexOfCat,
                                  currentCat: "",
                                  dataPresentType: .week,
                                  dataModel: [])
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .refresh:
            let state = currentState
            return self.realmService.taskOn()
                .map { [weak self] result in
                    let cat = result.toArray()[state.currentIndexOfCat]
                    let rawData = cat.dailyDataList.filter("%@ <= date AND date <= %@", Date().startDayOfWeek(), Date().endDayOfWeek()).toArray()
                    if rawData.isEmpty {
                        return .refresh([], cat.catName)
                    }
                    let modelData = self?.setDataByDataPresentType(dataPresentType: .week, data: rawData) ?? []
                    return .refresh(modelData, cat.catName)
                }
            
//        case .datePickerSelected(let datePickerType):
//            <#code#>
//        case .catSelected(let int):
//            <#code#>
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .refresh(data, catName):
            state.currentCat = catName
            state.dataModel = data
            return state
        }
    }
    
    private func setDataByDataPresentType(dataPresentType: DataPresentType, data: [DailyData]) -> [DataModel] {
        switch dataPresentType {
        case .year:
            var result = [DataModel]()
            var poopAverage = Array(repeating: 0, count: 12)
            var urineAverage = Array(repeating: 0, count: 12)
            var monthTableForPoop: [Int: [Int]] = [:]
            var monthTableForUrine: [Int: [Int]] = [:]
            for i in data.indices {
                let poopCount = data[i].poopCount
                let urineCount = data[i].urineCount
                let month = Calendar.current.dateComponents([.month], from: data[i].date).month!
                monthTableForPoop[month]?.append(poopCount)
                monthTableForUrine[month]?.append(urineCount)
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
            let dates = getDates(from: data.first!.date.startDayOfMonth(), to: data.first!.date.endDayOfMonth())
            return dates.map { date -> DataModel in
                guard let data = data.filter({ $0.date == date }).first else {
                    return DataModel(poopCount: 0, urineCount: 0, date: date)
                }
                return DataModel(poopCount: data.poopCount, urineCount: data.urineCount, date: date)
            }
        case .week:
            let dates = getDates(from: data.first!.date.startDayOfWeek(), to: data.first!.date.endDayOfWeek())
            return dates.map { date in
                guard let data = data.filter({ $0.date == date }).first else {
                    return DataModel(poopCount: 0, urineCount: 0, date: date)
                }
                return DataModel(poopCount: data.poopCount, urineCount: data.urineCount, date: date)
            }
            
        }
        
    }
    
    private func getDates(from startDate: Date, to endDate: Date) -> [Date] {
        
        var result = [Date]()
        var tmp = startDate
        
        while tmp <= endDate {
            result.append(tmp)
            guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: tmp) else { break }
            tmp = newDate
        }
        return result
    }
    
}
