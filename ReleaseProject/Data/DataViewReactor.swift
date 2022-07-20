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
        case scrollToEnd
        case dateChanged(Int)
    }
    
    enum Mutation {
        case setCatName(String)
        case setSection([ChartDateSection], DataPresentType)
        case setData([DataModel])
        case scrollToEnd
    }
    
    struct State {
        var catName: String
        var dataPresentType: DataPresentType
        var dataModel: [DataModel]
        var sections: [ChartDateSection]
        @Pulse var scroll: Int?
        
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
        let state = currentState
        let service = provider.dataTaskService
        
        switch action {
        case .refresh:
            return Observable.merge([
                service.catChanged().flatMap {_ in Observable<Mutation>.empty()},
                service.updateChartDateSection().flatMap {_ in Observable<Mutation>.empty()},
                service.updateData().flatMap {_ in Observable<Mutation>.empty()}
            ])
        case let .dataPresentTypeSelected(dataPresentType):
            service.currentDataPresentType.onNext(dataPresentType)
            return .empty()
        case .scrollToEnd:
            return .just(.scrollToEnd)
        case let .dateChanged(index):
            guard let date = state.sections.first?.items[index].initialState.date else { return .empty() }
            service.currentDate.onNext(date)
            return .empty()
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
        case let .updateChartDateSection(section, dataPresentType):
            return Observable.concat([
                .just(.setSection(section, dataPresentType)),
                .just(.scrollToEnd)
            ])
        case let .updateData(data):
            return .just(.setData(data))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case let .setCatName(name):
            newState.catName = name
        case let .setSection(section, dataPresentType):
            newState.dataPresentType = dataPresentType
            newState.sections = section
        case let .setData(data):
            newState.dataModel = data
        case .scrollToEnd:
            newState.scroll = 1
        }
        return newState
    }
    
}
