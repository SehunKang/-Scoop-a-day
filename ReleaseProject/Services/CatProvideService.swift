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

protocol CatProvideServiceType {
    
    var currentCatIndex: BehaviorSubject<Int> { get }
    
    func fetchCat() -> Observable<CatData>
    func fetchCatWhenChanged() -> Observable<CatData>

}

final class CatProvideService: Service, CatProvideServiceType {
    
    
    var currentCatIndex = BehaviorSubject<Int>(value: 0)
    
    //고양이가 바뀔때에만 emit
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
    
    //CatData의 데이터가 바뀔때에도 emit됨 예: 맛동산, 감자카운트가 늘 때에도
    func fetchCatWhenChanged() -> Observable<CatData> {
        
        let task = provider.realmService.taskOn()
        return Observable.combineLatest(task, currentCatIndex)
            .filter({ results, index in
                !results.isEmpty
            })
            .flatMap { results, index -> Observable<CatData> in
                let index = index < results.count ? index : index - 1
            
                return Observable.just(results.toArray()[index])
            }
                    
    }
    
}
