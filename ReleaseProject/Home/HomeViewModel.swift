//
//  HomeViewModel.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/04/05.
//

import Foundation

import Action
import RxSwift
import RxCocoa
import RxDataSources

enum ButtonType {
    case poop
    case urine
    case poopPlus
    case poopMinus
    case urinePlus
    case urineMinus
    
    var pooOrPee: PooOrPee {
        switch self {
        case .poop:
            return .poo
        case .urine:
            return .pee
        case .poopPlus:
            return .poo
        case .poopMinus:
            return .poo
        case .urinePlus:
            return .pee
        case .urineMinus:
            return .pee
        }
    }
}

typealias TaskSection = AnimatableSectionModel<String, CatData>

protocol HomeViewModelType {
    var sectionItems: Observable<[TaskSection]> { get }
    
    var numberOfCats: Observable<Int> { get }
    var currentTitle: Observable<String> { get }
    
    var currentIndexOfCat: BehaviorRelay<Int> { get }
    var isModifying: BehaviorRelay<Bool> { get }
    
    func getDailyData(item: CatData) -> Observable<DailyData>
    
    func createCat(name: String) -> Single<Void>
    func deleteCat()
    
    //Action을 다이어트 한 결과 이 함수 하나 남았음, 바꿀것인지 고민 필요
    func buttonClicked(cat: CatData) -> Action<ButtonType, Void>
    
}

final class HomeViewModel: HomeViewModelType {
    
    private let realmService: RealmServiceType = RealmService()
    
    var isModifying = BehaviorRelay<Bool>(value: false)
    
    var currentIndexOfCat: BehaviorRelay<Int>
    
    init(index: Int) {
        currentIndexOfCat = BehaviorRelay<Int>(value: index)
    }

    //RxDataSource에 CatData Object를 전달한다.
    var sectionItems: Observable<[TaskSection]> {
        return self.realmService.taskOn()
            .map { results in
                let catTasks = results
                    .sorted(byKeyPath: "createDate", ascending: true)
                
                return [TaskSection(model: "catData", items: catTasks.toArray())]
            }
    }
    
    private var catDataList: Observable<[CatData]> {
        return self.realmService.taskOn()
            .map { results in
                results.toArray()
            }
            .distinctUntilChanged()
    }
    
    func getDailyData(item: CatData) -> Observable<DailyData> {
        self.realmService.getDailyData(of: item)
    }
    
    //현재 관리하는 고양이는 몇마리인지
    var numberOfCats: Observable<Int> {
        return self.realmService.taskOn()
            .map { results in
                return results.count
            }
            .distinctUntilChanged()
    }
    
    var currentTitle: Observable<String> {
        return Observable.combineLatest(currentIndexOfCat.distinctUntilChanged(), catDataList) {
            (index, catData) -> String in
                if catData.isEmpty { return "" }
                if index < catData.startIndex || index >= catData.endIndex { return "" }
                return catData[index].catName
        }
    }
        
    //고양이 생성
    func createCat(name: String) -> Single<Void> {
        self.realmService.createNewCat(catName: name)
        
    }
    
    //고양이 삭제, 인덱스로 처리
    func deleteCat() {
        self.realmService.deleteCatByIndex(index: currentIndexOfCat.value)
    }
    
    //컬렉션뷰 셀 안의 감자, 맛동산, 혹은 수정 버튼들에 대한 액션
    func buttonClicked(cat: CatData) -> Action<ButtonType, Void> {
        
        return Action<ButtonType, Void> { buttonType in
            let at = Date().removeTime()
            var count: Int?
            
            if cat.dailyDataList.filter("date == %@", at).isEmpty {
                self.realmService.appendNewDailyData(of: cat)
            }
            
            switch buttonType.pooOrPee {
            case .pee:
                count = cat.dailyDataList.filter("date == %@", at).first?.urineCount
            case .poo:
                count = cat.dailyDataList.filter("date == %@", at).first?.poopCount
            }
            
            guard var count = count else {
                print("nil count value")
                return .empty()
            }

            //value가 0 미만, 99 초과일때는 RealmService에서 막아준다.
            switch buttonType {
            case .poop:
                count += 1
            case .urine:
                count += 1
            case .poopPlus:
                count += 1
            case .poopMinus:
                count -= 1
            case .urinePlus:
                count += 1
            case .urineMinus:
                count -= 1
            }
    
            return self.realmService.changeCount(cat: cat, date: at, type: buttonType.pooOrPee, value: count).map {_ in}
        }
    }
    
}

