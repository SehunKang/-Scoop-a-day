//
//  ChartDateCellModel.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/07/01.
//

import Foundation

struct ChartDateCellModel: Identifiable, Equatable {
    
    var id = UUID().uuidString
    
    var date: Date
    var presentType: DataPresentType
    
}
