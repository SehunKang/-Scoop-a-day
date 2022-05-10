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

enum PooOrPee {
    case poo
    case pee
}

enum RealmServiceError: Error {
    case creationFailed
    case updateFailed(CatData)
    case deletionFailed
}

protocol RealmServiceType {
    
    func createNewCat(catName: String) -> Observable<Int>
    func appendNewDailyData(of cat: CatData)
    func changeCount(cat: CatData, date: Date, type: PooOrPee, value: Int) -> Observable<CatData>
    func changeName(cat: CatData, newName: String) -> Observable<CatData>
    func delete(cat: CatData) -> Observable<Void>
    func deleteIndex(index: Int) -> Observable<Void>
    func taskOn() -> Observable<Results<CatData>>
    
}

struct RealmService: RealmServiceType {
    
    private func withRealm<T>(_ operation: String, action: (Realm) throws -> T) -> T? {
        do {
            let realm = try Realm()
            return try action(realm)
        } catch let err {
            print("Failed \(operation) function in RealmService with error: \(err)")
            return nil
        }
    }
    
    func createNewCat(catName: String) -> Observable<Int> {
        let result = withRealm(#function) { realm -> Observable<Int> in
            let catData = CatData(catName: catName)
            catData.dailyDataList.append(DailyData())
            try realm.write {
                realm.add(catData)
            }
            let resultOfTask = realm.objects(CatData.self).count
            
            return .just(resultOfTask)
        }
        return result ?? .error(RealmServiceError.creationFailed)
    }
    
    func appendNewDailyData(of cat: CatData) {
        withRealm(#function) { realm in
            try realm.write {
                cat.dailyDataList.append(DailyData())
            }
        }
    }
    
    //value가 음수, 99이상으로 오는 경우 이곳에서 막아준다.
    func changeCount(cat: CatData, date: Date, type: PooOrPee, value: Int) -> Observable<CatData> {
        var value = value
        value = value < 0 ? 0 : value
        value = value > 99 ? 99 : value
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
    
    func delete(cat: CatData) -> Observable<Void> {
        let result = withRealm(#function) { realm -> Observable<Void> in
            try realm.write {
                realm.delete(cat)
            }
            return .empty()
        }
        return result ?? .error(RealmServiceError.deletionFailed)
    }
    
    func deleteIndex(index: Int) -> Observable<Void> {
        let result = withRealm(#function) { realm -> Observable<Void> in
            let task = realm.objects(CatData.self)
            let cat = task.toArray()
            if cat.count <= index { return .empty()}
            try realm.write {
                realm.delete(cat[index])
            }
            return .empty()
        }
        return result ?? .error(RealmServiceError.deletionFailed)
    }
    
    
    func taskOn() -> Observable<Results<CatData>> {
        let result = withRealm(#function) { realm -> Observable<Results<CatData>> in
            let task = realm.objects(CatData.self)
            return Observable.collection(from: task)
        }
        return result ?? .empty()
    }

    
}

//struct RealmService{
//
//
//	var realm = try! Realm()
//
//	/// 새로운 고양이를 생성할 떄 사용하는 함수
//	func createNewCat(_ catName: String) {
//		let object = CatData(catName: catName)
//		object.dailyDataList.append(DailyData())
//		do {
//			try realm.write {
//				realm.add(object)
//			}
//		} catch {
//			print("createNewCat failed") //에러처리에 대한 고민 필요해보임
//		}
//	}
//
//    ///DB의 Observable을 반환
//    func taskOn() -> Observable<Results<CatData>> {
//        let object = realm.objects(CatData.self)
//        return Observable.collection(from: object)
//    }
//
//
//	/// 고양이 이름을 바꿀때 사용하는 함수
//	func changeCatName(from previousName: String, to newName: String) {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", previousName).first else {return}
//
//		do {
//			try realm.write {
//				object.catName = newName
//			}
//		} catch {
//			print("changeCatName failed")
//		}
//	}
//
//	/// catName에 해당하는 고양이에 DailyData를 추가해주는 함수
//	func appendNewDailyData(to catName: String) {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
//		let data = DailyData()
//		do {
//			try realm.write {
//				object.dailyDataList.append(data)
//			}
//		} catch {
//			print("appendNewDailyData failed")
//		}
//	}
//
//	/// 맛동산, 감자버튼이 클릭되었을 때를 위한 함수, catName, DailyData.date를 통해 해당하는 데이터를 찾는다.
//	func addCountValue(of catName: String, at date: Date, item: CountItem) {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
//		if object.dailyDataList.filter("date == %@", date).isEmpty {
//			self.appendNewDailyData(to: catName)
//			print("empty!")
//		}
//		do {
//			try realm.write {
//				switch item {
//				case .poop:
//					object.dailyDataList.filter("date == %@", date).first?.poopCount += 1
//				case .urine:
//					object.dailyDataList.filter("date == %@", date).first?.urineCount += 1
//				}
//			}
//		} catch {
//			print("addCountValue failed")
//		}
//	}
//
//	/// 맛동산 혹은 감자 값에 1을 뺀다. 값이 0일경우 리턴
//	func subtractCountValue(of catName: String, at date: Date, item: CountItem) {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
//		if object.dailyDataList.filter("date == %@", date).isEmpty {
//			self.appendNewDailyData(to: catName)
//		}
//		var count: Int!
//		switch item {
//		case .poop:
//			count = object.dailyDataList.filter("date == %@", date).first?.poopCount
//		case .urine:
//			count = object.dailyDataList.filter("date == %@", date).first?.urineCount
//		}
//		if count == 0 { return }
//		do {
//			try realm.write {
//				switch item {
//				case .poop:
//					object.dailyDataList.filter("date == %@", date).first?.poopCount -= 1
//				case .urine:
//					object.dailyDataList.filter("date == %@", date).first?.urineCount -= 1
//				}
//			}
//		} catch {
//			print("addCountValue failed")
//		}
//
//	}
//
//	/// 맛동산, 감자 카운팅을 수정할 때 사용하는 함수, catName, DailyData.date를 통해 해당하는 데이터를 찾는다.
//	func changeCountValue(of catName: String, at date: Date, item: CountItem, to newValue: Int) {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
//
//		do {
//			try realm.write {
//				switch item {
//				case .poop:
//					object.dailyDataList.filter("date == %@", date).first?.poopCount = newValue
//				case .urine:
//					object.dailyDataList.filter("date == %@", date).first?.urineCount = newValue
//				}
//			}
//		} catch {
//			print("changeCountValue failed")
//		}
//	}
//
//	///item에 따라 date에 해당하는 날의 맛동산 혹은 감자 수를 리턴한다. 오류시 -1 리턴
//	func totalCountOfDay(of catName: String, at date: Date, item: CountItem ) -> Int {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return -1}
//		let dailyData = object.dailyDataList.filter("date == %@", date)
//		if item == .poop {
//			return dailyData.first?.poopCount ?? -1
//		} else {
//			return dailyData.first?.urineCount ?? -1
//		}
//	}
//
//	/// 특이사항(String)을 저장한다.
//	func addRecord(of catName: String, at date: Date, event: String) {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
//		do {
//			try realm.write {
//				object.dailyDataList.filter("date == %@", date).first?.records.append(event)
//			}
//		} catch {
//			print("addRecord failed")
//		}
//	}
//
//	/// FromNow만큼 떨어진 주/월/연 의 데이터를 반환한다. 반환값은 순서대로 맛동산, 감자, 날짜이다. 날짜순 정렬되어있다.
//	func getDailyData(of catName: String, unit: DateUnit, fromNow by: Int = 0) -> ([Int], [Int], [Date]) {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return ([Int](), [Int](), [Date]())}
//		let dailyDatas: Results<DailyData>
//		switch unit {
//		case .week:
//			dailyDatas = object.dailyDataList.filter("date BETWEEN {%@, %@}", Date().startDayOfWeek(by: by), Date().endDayOfWeek(by: by)).sorted(byKeyPath: "date", ascending: true)
//		case .month:
//			dailyDatas = object.dailyDataList.filter("date BETWEEN {%@, %@}", Date().startDayOfMonth(by: by), Date().endDayOfMonth(by: by)).sorted(byKeyPath: "date", ascending: true)
//		case .year:
//			dailyDatas = object.dailyDataList.filter("date BETWEEN {%@, %@}", Date().startDayOfYear(by: by), Date().endDayOfYear(by: by)).sorted(byKeyPath: "date", ascending: true)
//		}
//		var poops: [Int] = [Int]()
//		var urine: [Int] = [Int]()
//		var dates: [Date] = [Date]()
//		for data in dailyDatas {
//			poops.append(data.poopCount)
//			urine.append(data.urineCount)
//			dates.append(data.date)
//		}
//		return (poops, urine, dates)
//	}
//	/// date에 해당하는 월의 데이터를 반환한다. 반환값은 순서대로 맛동산, 감자, 날짜이다. 날짜순 정렬되어있다.
//	func getMonthlyData(of catName: String, at date: Date) -> ([Int], [Int], [Date]) {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else { return ([Int](), [Int](), [Date]()) }
//		let dailyDatas: Results<DailyData> = object.dailyDataList.filter("date BETWEEN {%@, %@}", date.startDayOfMonth(), date.endDayOfMonth()).sorted(byKeyPath: "date", ascending: true)
//		var poops: [Int] = [Int]()
//		var urine: [Int] = [Int]()
//		var dates: [Date] = [Date]()
//		for data in dailyDatas {
//			poops.append(data.poopCount)
//			urine.append(data.urineCount)
//			dates.append(data.date)
//		}
//		return (poops, urine, dates)
//	}
//
//	/// FromNow만큼 떨어진 주/월/연 의 데이터를 반환한다. 반환값은 정렬된 날짜이다.
//	func getDailyDates(of catName: String, unit: DateUnit, fromNow by: Int = 0) -> [Date] {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else { return [Date]() }
//		let dailyDatas: Results<DailyData>
//		switch unit {
//		case .week:
//			dailyDatas = object.dailyDataList.filter("date BETWEEN {%@, %@}", Date().startDayOfWeek(by: by), Date().endDayOfWeek(by: by)).sorted(byKeyPath: "date", ascending: true)
//		case .month:
//			dailyDatas = object.dailyDataList.filter("date BETWEEN {%@, %@}", Date().startDayOfMonth(by: by), Date().endDayOfMonth(by: by)).sorted(byKeyPath: "date", ascending: true)
//		case .year:
//			dailyDatas = object.dailyDataList.filter("date BETWEEN {%@, %@}", Date().startDayOfYear(by: by), Date().endDayOfYear(by: by)).sorted(byKeyPath: "date", ascending: true)
//		}
//		var dates: [Date] = [Date]()
//		for data in dailyDatas {
//			dates.append(data.date)
//		}
//		return (dates)
//	}
//
//
//
//	/// 입력 된 CatData를 삭제한다.
//	func delete(_ catName: String) {
//		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
//		do {
//			try realm.write {
//				realm.delete(object.dailyDataList)
//				realm.delete(object)
//			}
//		} catch {
//			print("delete failed")
//		}
//	}
//
//}
