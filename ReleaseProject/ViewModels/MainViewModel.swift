//
//  HomeViewModel.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/04/05.
//

import Foundation

import Action
import RxSwift
import RxDataSources
import RealmSwift

typealias TaskSection = AnimatableSectionModel<String, CatData>

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

class MainViewModel {
    
    let realmService: RealmServiceType
    
    init(realmService: RealmServiceType) {
        self.realmService = realmService
    }
    
    //RxDataSource에 CatData Object를 전달한다.
    var sectionItems: Observable<TaskSection> {
        return self.realmService.taskOn()
            .map { results in
                let catTasks = results
                    .sorted(byKeyPath: "createDate", ascending: true)
                
                return TaskSection(model: "catData", items: catTasks.toArray())
            }
    }
    
    func createCat(name: String) -> CocoaAction {
        return CocoaAction {
            return self.realmService.createNewCat(catName: name).map { _ in }
        }
    }
    
    func deleteCat(cat: CatData) -> CocoaAction {
        return CocoaAction {
            return self.realmService.delete(cat: cat)
        }
    }
    
    func buttonClicked(cat: CatData, buttonType: ButtonType) -> CocoaAction {
        return CocoaAction {
            let at = Date().removeTime()
            var count: Int?
            
            switch buttonType.pooOrPee {
            case .pee:
                count = cat.dailyDataList.filter("date == %@", at).first?.urineCount
            case .poo:
                count = cat.dailyDataList.filter("date == %@", at).first?.poopCount
            }
            guard var count = count else {
                return .empty()
            }

            switch buttonType {
            case .poop:
                count += 1
            case .urine:
                count += 1
            case .poopPlus:
                count += 1
            case .poopMinus:
                count += 1
            case .urinePlus:
                if count > 0 {
                    count -= 1
                }
            case .urineMinus:
                if count > 0 {
                    count -= 1
                }
            }
            return self.realmService.changeCount(cat: cat, date: at, type: buttonType.pooOrPee, value: count).map {_ in}
        }
    }
    
    
    
    
}
