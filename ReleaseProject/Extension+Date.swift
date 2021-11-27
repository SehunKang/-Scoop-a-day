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
}
