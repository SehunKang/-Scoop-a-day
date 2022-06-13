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

import RealmSwift


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

protocol ViewModel {
    
}

class HomeViewModel: ViewModel {
    
    private let realmService: RealmServiceType = RealmService()
    
    //RxDataSource에 CatData Object를 전달한다.
    var sectionItems: Observable<[TaskSection]> {
        return self.realmService.taskOn()
            .map { results in
                let catTasks = results
                    .sorted(byKeyPath: "createDate", ascending: true)
                
                return [TaskSection(model: "catData", items: catTasks.toArray())]
            }
    }
    
    var catDataList: Observable<[CatData]> {
        print("catDataListChanged")
        return self.realmService.taskOn()
            .map { results in
                results.toArray()
            }
            .distinctUntilChanged()
    }
    
    //현재 관리하는 고양이는 몇마리인지
    var numberOfCats: Observable<Int> {
        return self.realmService.taskOn()
            .map { results in
                return results.count
            }
            .distinctUntilChanged()
    }
        
    //고양이 생성
    func createCat(name: String) -> CocoaAction {
        return CocoaAction {
            return self.realmService.createNewCat(catName: name)
        }
    }
    
    func getDailyData(item: CatData) -> DailyData {
        if item.dailyDataList.filter("date == %@", Date().removeTime()).first == nil {
            newDailyData(of: item)
        }
        let dailyData = item.dailyDataList.filter("date == %@", Date().removeTime()).first!

        return dailyData
    }
    
    //dailyData를 추가
    private func newDailyData(of cat: CatData) {
        self.realmService.appendNewDailyData(of: cat)
    }
    
    //고양이 삭제, 인덱스로 처리
    func deleteCat(indexOfCat: Int) {
        self.realmService.deleteIndex(index: indexOfCat)
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

