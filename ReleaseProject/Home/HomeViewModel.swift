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
    
    var changingValue: Int {
        switch self {
        case .poop:
            return 0
        case .urine:
            return 0
        case .poopPlus:
            return 1
        case .poopMinus:
            return -1
        case .urinePlus:
            return 1
        case .urineMinus:
            return -1
        }
    }
}

typealias TaskSection = AnimatableSectionModel<String, CatData>

protocol HomeViewModelType {
    var sectionItems: Observable<[TaskSection]> { get }
    
    var numberOfCats: Observable<Int> { get }
    var currentTitle: Observable<String> { get }
    
    var currentIndexOfCat: BehaviorSubject<Int> { get }
    var isModifying: BehaviorRelay<Bool> { get }
    
    func getDailyData(item: CatData) -> Observable<DailyData>
    
    func createCat(name: String) -> Single<Void>
    func createCatFromZero(name: String) -> Single<Void>
    func deleteCat()
    
    //Action을 다이어트 한 결과 이 함수 하나 남았음, 바꿀것인지 고민 필요
    func buttonClicked(cat: CatData) -> Action<ButtonType, Void>
    
    func catChange(index: Int)
}

final class HomeViewModel: HomeViewModelType {
    
    private let realmService: RealmServiceType
    private let catProvideService: CatProvideServiceType
    
    var isModifying = BehaviorRelay<Bool>(value: false)
    
    var currentIndexOfCat: BehaviorSubject<Int>
    
    init(provider: ServiceProviderType) {
        self.currentIndexOfCat = provider.catProvideService.currentCatIndex
        self.realmService = provider.realmService
        self.catProvideService = provider.catProvideService
    }

    //RxDataSource에 binding
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
    
    func catChange(index: Int) {
        catProvideService.currentCatIndex.onNext(index)
    }
    
    func getDailyData(item: CatData) -> Observable<DailyData> {
        self.realmService.getDailyData(of: item)
    }
    
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
        
    func createCat(name: String) -> Single<Void> {
        return self.realmService.createNewCat(catName: name)
    }
    
    func createCatFromZero(name: String) -> Single<Void> {
        return self.realmService.createNewCat(catName: name)
            .do { [weak self] _ in
                self?.currentIndexOfCat.onNext(0)
            }
    }
        
    
    //고양이 삭제, 현재 인덱스로 처리
    func deleteCat() {
        let index = try! currentIndexOfCat.value()
        self.realmService.deleteCatByIndex(index: index)
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

            //value가 0 미만, 999 초과일때는 RealmService에서 막아준다.
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
                                                       
