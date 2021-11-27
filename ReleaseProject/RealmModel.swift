//
//  RealmModel.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/21.
//

import Foundation
import RealmSwift

class CatData: Object {
	
	@Persisted var catName: String
	@Persisted var createDate = Date().removeTime()
	@Persisted var dailyDataList: List<DailyData>
	
	@Persisted(primaryKey: true) var _id: ObjectId
	
	convenience init(catName: String) {
		self.init()
		
		self.catName = catName
	}
}

class DailyData: Object {
	
	@Persisted var date = Date().removeTime()
	@Persisted var poopCount: Int = 0
	@Persisted var urineCount: Int = 0
	@Persisted var records: List<String>
}

enum CountItem {
	case poop
	case urine
}
