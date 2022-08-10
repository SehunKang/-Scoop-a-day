//
//  CalendarTaskService.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/08/10.
//

import Foundation

import RxSwift

enum CalendarTask {
    case updateCatName(String)
    case updateCount(Int, Int)
}

protocol CalendarTaskServiceType {
    
    var event: PublishSubject<CalendarTask> { get }
    
    var currentDate: BehaviorSubject<Date> { get }
    
    func catChanged() -> Observable<CalendarTask>
    func countByDate() -> Observable<CalendarTask>
    func changeDailyData(catName: String, poopCount: Int, urineCount: Int, buttonType: ButtonType)
}

final class CalendarTaskService: Service, CalendarTaskServiceType {
    
    let event = PublishSubject<CalendarTask>()
    
    let currentDate = BehaviorSubject<Date>(value: Date())
    
    func catChanged() -> Observable<CalendarTask> {
        
        return provider.catProvideService.fetchCat()
            .flatMap { cat -> Observable<CalendarTask> in
                    .just(.updateCatName(cat.catName))
            }
            .do { task in
                self.event.onNext(task)
            }
    }
    
    func countByDate() -> Observable<CalendarTask> {
        
        let fetch = provider.catProvideService.fetchCatWhenChanged()
        
        return Observable.combineLatest(fetch, currentDate)
            .filter { !$0.0.isInvalidated }
            .flatMap { (catData, date) -> Observable<CalendarTask> in
                guard let dailyData = catData.dailyDataList.toArray().filter({ $0.date == date.removeTime() }).first else {
                    return .just(.updateCount(0, 0))
                }
                return .just(.updateCount(dailyData.poopCount, dailyData.urineCount))
            }
            .do { task in
                self.event.onNext(task)
            }
    }
    
    func changeDailyData(catName: String, poopCount: Int, urineCount: Int, buttonType: ButtonType) {
        var count = 0
        switch buttonType {
        case .poop:
            return
        case .urine:
            return
        case .poopPlus:
            count = poopCount == 999 ? 999 : poopCount + 1
        case .poopMinus:
            count = poopCount == 0 ? 0 : poopCount - 1
        case .urinePlus:
            count = urineCount == 999 ? 999 : urineCount + 1
        case .urineMinus:
            count = urineCount == 0 ? 0 : urineCount - 1
        }
        
        do {
            try provider.realmService.changeDailyData(cat: catName, date: currentDate.value().removeTime(), pooOrPee: buttonType.pooOrPee, changedValue: count)
        } catch {
            return
        }
    
    }
    
    
    
    
    
}
