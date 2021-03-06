//
//  RealmModel.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/21.
//

import Foundation
import RealmSwift
import Differentiator

class CatData: Object {
	
	@Persisted var catName: String
	@Persisted var createDate = Date().removeTime()
	@Persisted var dailyDataList: List<DailyData>
	@Persisted var numForImage = Int.random(in: 2...6)
	
	@Persisted(primaryKey: true) var _id: ObjectId
    	
	convenience init(catName: String) {
		self.init()
		
		self.catName = catName
	}
}

extension CatData: IdentifiableType {
    var identity: String {
        return self.isInvalidated ? "deleted-object" : _id.stringValue
    }
}

class DailyData: Object {
	
	@Persisted var date = Date().removeTime()
	@Persisted var poopCount: Int = 0
	@Persisted var urineCount: Int = 0
	@Persisted var records: List<String>
    
    convenience init(date: Date, poopCount: Int, urineCount: Int) {
        self.init()
        self.date = date
        self.poopCount = poopCount
        self.urineCount = urineCount
    }
}

enum CountItem {
	case poop
	case urine
}

enum DateUnit {
	case week
	case month
	case year
}
