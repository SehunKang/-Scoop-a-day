//
//  Extension+String.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/23.
//

import Foundation

extension String {
	
	func localized(withComment: String) -> String {
        
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: withComment)
	}
    
	
}
