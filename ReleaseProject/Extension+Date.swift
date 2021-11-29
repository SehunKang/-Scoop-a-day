//
//  Extension+Date.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/22.
//

import Foundation

extension Date {
	
	func removeTime() -> Date {
		let calendar = Calendar(identifier: .gregorian)
		let components = calendar.dateComponents([.year, .month, .day], from: self)
		let date = calendar.date(from: components)
		return date!
	}
	
	///해당달의 시작일을 알려줌
	func startDayOfMonth() -> Date {
		return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
	}
	
	///Date로부터 by만큼 떨어진 개월수의 시작일을 알려줌
	func startDayOfMonth(by: Int) -> Date {
		return Calendar.current.date(byAdding: DateComponents(month: by), to: self.startDayOfMonth())!
	}

	///Date로부터 by만큼 떨어진 개월수의 말일을 알려줌
	func endDayOfMonth(by: Int = 0) -> Date {
		return Calendar.current.date(byAdding: DateComponents(month: 1 + by, second: -1), to: self.startDayOfMonth())!
	}
	
	/// 해당주의 시작일을 알려줌
	func startDayOfWeek() -> Date {
		return Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
	}
	
	/// Date로부터 by만큼 떨어진 주의 시작일을 알려줌
	func startDayOfWeek(by: Int) -> Date {
		return Calendar.current.date(byAdding: DateComponents(weekOfYear: by), to: self.startDayOfWeek())!
	}
	
	/// Date로부터 by만큼 떨어진 주의 말일을 알려줌
	func endDayOfWeek(by: Int) -> Date {
		return Calendar.current.date(byAdding: DateComponents(second: -1, weekOfYear: 1 + by), to: self.startDayOfWeek())!
	}
	
	/// 해당년도의 시작일을 알려줌
	func startDayOfYear() -> Date {
		return Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Calendar.current.startOfDay(for: self)))!
	}

	/// 해당년도로부터 by만큼 떨어진 해의 시작일을 알려줌
	func startDayOfYear(by: Int) -> Date {
		return Calendar.current.date(byAdding: DateComponents(year: by), to: self.startDayOfYear())!
	}
	/// 해당년도로부터 by만큼 떨어진 해의 말일을 알려줌
	func endDayOfYear(by: Int = 0) -> Date {
		return Calendar.current.date(byAdding: DateComponents(year: 1 + by, second: -1), to: self.startDayOfYear())!
	}
	

	
}
