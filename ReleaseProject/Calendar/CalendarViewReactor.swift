//
//  CalendarViewReactor.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/08/02.
//

import Foundation

import ReactorKit


class CalendarViewReactor: Reactor {
    
    enum Action {
        case refresh
        case dateSelected(Date)
        case countChangeButtonClicked(ButtonType)
    }
    
    enum Mutation {
        case setCatName(String)
        case dateChanged(Int, Int)
    }
    
    struct State {
        var catName: String
        var poopCount: Int
        var urineCount: Int
    }
    
    let initialState: State
    
    let provider: ServiceProviderType
    
    init(provider: ServiceProviderType) {
        self.provider = provider
        
        self.initialState = State(catName: "",
                                  poopCount: 0,
                                  urineCount: 0)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        let service = provider.calendarTaskService
        
        switch action {
        case .refresh:
            return Observable.merge([
                service.catChanged().flatMap { _ in Observable<Mutation>.empty() },
                service.countByDate().flatMap { _ in Observable<Mutation>.empty() }
            ])
        case .dateSelected(let date):
            service.currentDate.onNext(date)
            return .empty()
        case .countChangeButtonClicked(let buttonType):
            service.changeDailyData(catName: currentState.catName, poopCount: currentState.poopCount, urineCount: currentState.urineCount, buttonType: buttonType)
            return .empty()
        }
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        
        let taskMutation = provider.calendarTaskService.event
            .flatMap { [weak self] task -> Observable<Mutation> in
                self?.mutate(task: task) ?? .empty()
            }
        
        return Observable.merge(mutation, taskMutation)
    }
    
    private func mutate(task: CalendarTask) -> Observable<Mutation> {
        switch task {
        case let .updateCatName(name):
            return .just(.setCatName(name))
        case let .updateCount(poopCount, urineCount):
            return .just(.dateChanged(poopCount, urineCount))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        print(state)
        print(mutation)
        var newState = state
        
        switch mutation {
        case let .setCatName(name):
            newState.catName = name
        case let .dateChanged(poopCount, urineCount):
            newState.poopCount = poopCount
            newState.urineCount = urineCount
        }
        
        return newState
    }
}
