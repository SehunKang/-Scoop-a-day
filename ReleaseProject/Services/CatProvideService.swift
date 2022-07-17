//
//  CatProvideService.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/07/04.
//

import Foundation

import RxSwift
import RealmSwift
import RxRelay

//추후 이녀석만 RealmService를 의존하는 식으로 변경
protocol CatProvideServiceType {
    
    var currentCatIndex: BehaviorSubject<Int> { get }
    
    func fetchCat() -> Observable<CatData>
    func fetchCatWhenChanged() -> Observable<CatData>

}

final class CatProvideService: Service, CatProvideServiceType {
    
    
    var currentCatIndex = BehaviorSubject<Int>(value: 0)
    
    func fetchCat() -> Observable<CatData> {
        let task = provider.realmService.taskOn().distinctUntilChanged { one, two in
            one.count == two.count
        }
        return Observable.combineLatest(task, currentCatIndex)
            .filter({ results, index in
                !results.isEmpty
            })
            .flatMap { results, index in
                Observable.just(results.toArray()[index])
            }
    }
    
    func fetchCatWhenChanged() -> Observable<CatData> {
        let task = provider.realmService.taskOn()
        
        return Observable.zip(task, currentCatIndex.distinctUntilChanged())
            .flatMap { result, index -> Observable<CatData> in
                print("zipzipzip")
                return Observable.just(result.toArray()[index])
            }
            
    }
    
}
