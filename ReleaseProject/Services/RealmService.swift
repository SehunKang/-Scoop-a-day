//
//  RealmService.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/22.
//

import Foundation

import RealmSwift

import RxRealm
import RxSwift



protocol RealmServiceType {
    //C
    func createNewCat(catName: String) -> Single<Void>
    //R
    func taskOn() -> Observable<Results<CatData>>
    func fetch() -> Results<CatData>
    func getDailyData(of cat: CatData) -> Observable<DailyData>
    //U
    func changeCount(cat: CatData, date: Date, type: PooOrPee, value: Int) -> Observable<CatData>
    func changeName(cat: CatData, newName: String) -> Observable<CatData>
    func appendNewDailyData(of cat: CatData)
    //D
    func deleteCatByIndex(index: Int)
    
}

enum PooOrPee {
    case poo
    case pee
}

enum RealmServiceError: Error {
    case creationFailed
    case updateFailed(CatData)
    case deletionFailed
    case todayDailyDataQueryError(CatData)
    case catNameDuplication
}

final class RealmService: Service, RealmServiceType {
    
    private func withRealm<T>(_ operation: String, action: (Realm) throws -> T) -> T? {
        do {
            let realm = try Realm()
            return try action(realm)
        } catch let err {
            print("Failed \(operation) function in RealmService with error: \(err)")
            return nil
        }
    }
    
    func fetch() -> Results<CatData> {
        let cats = withRealm(#function) { realm in
            return realm.objects(CatData.self)
        }
        return cats!
    }
    
    func taskOn() -> Observable<Results<CatData>> {
        let result = withRealm(#function) { realm -> Observable<Results<CatData>> in
            let task = realm.objects(CatData.self)
                .sorted(byKeyPath: "createDate", ascending: true)
            return Observable.collection(from: task)
        }
        return result ?? .empty()
    }
    
    func appendNewDailyData(of cat: CatData) {
        withRealm(#function) { realm in
            try realm.write {
                cat.dailyDataList.append(DailyData())
            }
        }
    }
   
    func getDailyData(of cat: CatData) -> Observable<DailyData> {
        let result = withRealm(#function) { realm -> Observable<DailyData> in
            guard let dailyData = cat.dailyDataList.filter("date == %@", Date().removeTime()).first else {
                let data = DailyData()
                try realm.write {
                    cat.dailyDataList.append(data)
                }
                return .just(data)
            }
            return .just(dailyData)
        }
        return result ?? .error(RealmServiceError.todayDailyDataQueryError(cat))
    }
    
    func createNewCat(catName: String) -> Single<Void> {
        let result = withRealm(#function) { realm -> Single<Void> in
            if realm.objects(CatData.self)
                .contains(where: { $0.catName == catName}) {
                return Single.error(RealmServiceError.catNameDuplication)
            } else {
                let catData = CatData(catName: catName)
                if catName == "test" {
                    for i in stride(from: 730, through: 0, by: -1) {
                        let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                        let data = DailyData(date: date.removeTime(), poopCount: Int.random(in: 0...3), urineCount: Int.random(in: 2...6))
                        catData.dailyDataList.append(data)
                    }
                } else {
                    catData.dailyDataList.append(DailyData())
                }
                try realm.write {
                    realm.add(catData)
                }
                return Single.just(Void())
            }
        }
        return result ?? .error(RealmServiceError.creationFailed)
    }
    
    
    func changeCount(cat: CatData, date: Date, type: PooOrPee, value: Int) -> Observable<CatData> {
        var value = value
        value = value < 0 ? 0 : value
        value = value > 999 ? 999 : value
        let result = withRealm(#function) { realm -> Observable<CatData> in
            try realm.write {
                switch type {
                case .poo:
                    cat.dailyDataList.filter("date == %@", date).first?.poopCount = value
                case .pee:
                    cat.dailyDataList.filter("date == %@", date).first?.urineCount = value
                }
            }
            return .just(cat)
        }
        return result ?? .error(RealmServiceError.updateFailed(cat))
    }
    
    func changeName(cat: CatData, newName: String) -> Observable<CatData> {
        let result = withRealm(#function) { realm -> Observable<CatData> in
            try realm.write {
                cat.catName = newName
            }
            return .just(cat)
        }
        return result ?? .error(RealmServiceError.updateFailed(cat))
    }
    
    func deleteCatByIndex(index: Int) {
        withRealm(#function) { realm in
            let task = realm.objects(CatData.self)
            let cat = task.toArray()
            if cat.count <= index || cat.count == 0 { return }
            try realm.write {
                realm.delete(cat[index].dailyDataList)
                realm.delete(cat[index])
            }
        }
    }
    
}

