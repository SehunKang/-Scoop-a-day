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
        case dataPresentTypeSelected(DataPresentType)
//        case dateIncrease
//        case dateDecrease
//        case catChanged(
    }
    
    enum Mutation {
        case setCatName(String)
        case setSection([ChartDateSection])
        case setData([DataModel])
    }
    
    struct State {
        var catName: String
        var dataPresentType: DataPresentType
        var dataModel: [DataModel]
        var sections: [ChartDateSection]
        
    }
    
    let initialState: State
    
    let provider: ServiceProviderType
    
    init(provider: ServiceProviderType) {
        self.provider = provider
        
        self.initialState = State(catName: "",
                                  dataPresentType: .week,
                                  dataModel: [],
                                  sections: [])
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
//        let state = currentState
        switch action {
        case .refresh:
            return provider.dataTaskService.catChanged()
                .flatMap { _ in Observable<Mutation>.empty()}
        case let .dataPresentTypeSelected(dataPresentType):
            return provider.dataTaskService.updateChartDateSection(dataPresentType: dataPresentType)
                .flatMap { _ in Observable<Mutation>.empty()}
//        case .dateIncrease:
//        case .dateDecrease:
//            <#code#>
        }
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let taskMutation = provider.dataTaskService.event
            .flatMap {[weak self] task -> Observable<Mutation> in
                self?.mutate(task: task) ?? .empty()
            }
        return Observable.of(taskMutation, mutation).merge()
    }
    
    private func mutate(task: DataTask) -> Observable<Mutation> {
        switch task {
        case let .updateCatName(name):
            return .just(.setCatName(name))
        case let .updateChartDateSection(section):
            return .just(.setSection(section))
        case let .updateData(data):
            return .just(.setData(data))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .setCatName(name):
            state.catName = name
        case let .setSection(section):
            state.sections = section
        case let .setData(data):
            state.dataModel = data
        }
        return state
    }
    
}
