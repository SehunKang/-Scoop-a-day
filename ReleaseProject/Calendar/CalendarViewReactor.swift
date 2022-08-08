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
    }
    
    enum Mutation {
        case setCatName(String)
        case count(Int, Int)
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
        switch action {
        case .refresh:
            return provider.catProvideService.fetchCat()
                .map { catData -> Mutation in
                    let name = catData.catName
                    return .setCatName(name)
                }
        case let .dateSelected(date):
            return provider.catProvideService.fetchCatWhenChanged()
                .map { catData -> Mutation in
                    let dataArray = catData.dailyDataList.toArray()
                    guard let data = dataArray.filter({ $0.date == date.removeTime() }).first else {
                        return .count(0, 0)
                    }
                    return .count(data.poopCount, data.urineCount)
                }
        }
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        return Observable.merge(mutation, provider.catProvideService.fetchCat()
            .map({Mutation.setCatName($0.catName)}))
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
       var newState = state
        
        switch mutation {
        case let .setCatName(name):
            newState.catName = name
        case let .count(poopCount, urineCount):
            newState.poopCount = poopCount
            newState.urineCount = urineCount
        }
        
        return newState
    }
}
