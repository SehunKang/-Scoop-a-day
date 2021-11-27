//
//  RealmService.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/22.
//

import Foundation
import RealmSwift

class RealmService{
	
	private init() {}
	
	static let shared = RealmService()
	
	var realm = try! Realm()
	
	/// 새로운 고양이를 생성할 떄 사용하는 함수
	func createNewCat(_ catName: String) {
		let object = CatData(catName: catName)
		object.dailyDataList.append(DailyData())
		do {
			try realm.write {
				realm.add(object)
			}
		} catch {
			print("createNewCat failed") //에러처리에 대한 고민 필요해보임
		}
	}
	
	/// 고양이 이름을 바꿀때 사용하는 함수
	func changeCatName(from previousName: String, to newName: String) {
		guard let object = realm.objects(CatData.self).filter("catName == %@", previousName).first else {return}
		
		do {
			try realm.write {
				object.catName = newName
			}
		} catch {
			print("changeCatName failed")
		}
	}
	
	/// catName에 해당하는 고양이에 DailyData를 추가해주는 함수
	func appendNewDailyData(to catName: String) {
		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
		let data = DailyData()
		do {
			try realm.write {
				object.dailyDataList.append(data)
			}
		} catch {
			print("appendNewDailyData failed")
		}
	}
	
	/// 맛동산, 감자버튼이 클릭되었을 때를 위한 함수, catName, DailyData.date를 통해 해당하는 데이터를 찾는다.
	func addCountValue(of catName: String, at date: Date, item: CountItem) {
		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
		if object.dailyDataList.filter("date == %@", date).isEmpty {
			self.appendNewDailyData(to: catName)
			print("empty!")
		}
		do {
			try realm.write {
				switch item {
				case .poop:
					object.dailyDataList.filter("date == %@", date).first?.poopCount += 1
				case .urine:
					object.dailyDataList.filter("date == %@", date).first?.urineCount += 1
				}
			}
		} catch {
			print("addCountValue failed")
		}
	}
	
	/// 맛동산 혹은 감자 값에 1을 뺀다. 값이 0일경우 리턴
	func subtractCountValue(of catName: String, at date: Date, item: CountItem) {
		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
		if object.dailyDataList.filter("date == %@", date).isEmpty {
			self.appendNewDailyData(to: catName)
		}
		var count: Int!
		switch item {
		case .poop:
			count = object.dailyDataList.filter("date == %@", date).first?.poopCount
		case .urine:
			count = object.dailyDataList.filter("date == %@", date).first?.urineCount
		}
		if count == 0 { return }
		do {
			try realm.write {
				switch item {
				case .poop:
					object.dailyDataList.filter("date == %@", date).first?.poopCount -= 1
				case .urine:
					object.dailyDataList.filter("date == %@", date).first?.urineCount -= 1
				}
			}
		} catch {
			print("addCountValue failed")
		}

	}
	
	/// 맛동산, 감자 카운팅을 수정할 때 사용하는 함수, catName, DailyData.date를 통해 해당하는 데이터를 찾는다.
	func changeCountValue(of catName: String, at date: Date, item: CountItem, to newValue: Int) {
		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}

		do {
			try realm.write {
				switch item {
				case .poop:
					object.dailyDataList.filter("date == %@", date).first?.poopCount = newValue
				case .urine:
					object.dailyDataList.filter("date == %@", date).first?.urineCount = newValue
				}
			}
		} catch {
			print("changeCountValue failed")
		}
	}
	
	///item에 따라 date에 해당하는 날의 맛동산 혹은 감자 수를 리턴한다. 오류시 -1 리턴
	func totalCountOfDay(of catName: String, at date: Date, item: CountItem ) -> Int {
		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return -1}
		let dailyData = object.dailyDataList.filter("date == %@", date)
		if item == .poop {
			return dailyData.first?.poopCount ?? -1
		} else {
			return dailyData.first?.urineCount ?? -1
		}
	}
	
	func addRecord(of catName: String, at date: Date, event: String) {
		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
		do {
			try realm.write {
				object.dailyDataList.filter("date == %@", date).first?.records.append(event)
			}
		} catch {
			print("addRecord failed")
		}
	}
	
	
	/// 입력 된 CatData를 삭제한다.
	func delete(_ catName: String) {
		guard let object = realm.objects(CatData.self).filter("catName == %@", catName).first else {return}
		do {
			try realm.write {
				realm.delete(object.dailyDataList)
				realm.delete(object)
			}
		} catch {
			print("delete failed")
		}
	}
	
}
