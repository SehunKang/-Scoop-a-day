//
//  ChartDateCellReactor.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/07/01.
//

import ReactorKit


class ChartDateCellReactor: Reactor {
    typealias Action = NoAction
    
    let initialState: ChartDateCellModel
    
    init(task: ChartDateCellModel) {
        self.initialState = task
    }
}
