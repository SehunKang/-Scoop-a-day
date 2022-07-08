//
//  ChartDateCollectionViewCell.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/07/01.
//

import UIKit

import RxSwift
import RxCocoa

import ReactorKit

import SnapKit

class ChartDateCollectionViewCell: UICollectionViewCell, View {
    
    var disposeBag = DisposeBag()
    
    static let identifier = "ChartDateCollectionViewCell"
        
    typealias Reactor = ChartDateCellReactor
        
    let dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layout()
        self.insetsLayoutMarginsFromSafeArea = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func layout() {
        self.contentView.addSubview(dateLabel)
        
        dateLabel.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
    }
    
    func bind(reactor: Reactor) {
        let date = reactor.currentState.date
        let presentType = reactor.currentState.presentType
        let formatter = DateFormatter()
        let text: String
        switch presentType {
        case .week:
            text = getWeekOfMonth(date: date)
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            text = formatter.string(from: date)
        case .year:
            formatter.dateFormat = "yyyy"
            text = formatter.string(from: date)
        }
        dateLabel.text = text
    }
    
    private func getWeekOfMonth(date: Date) -> String {
        var date = date
        let calendar = Calendar.current
        let start = calendar.dateComponents([.yearForWeekOfYear, .month, .day, .weekOfMonth], from: date.startDayOfWeek())
        let end = calendar.dateComponents([.yearForWeekOfYear, .month, .day, .weekOfMonth], from: date.endDayOfWeek())
        let week: Int
        if start.weekOfMonth! != end.weekOfMonth! {
            if start.weekOfMonth! !=
                calendar.dateComponents([.weekOfMonth], from: calendar.date(byAdding: .day, value: 3, to: date.startDayOfWeek())!).weekOfMonth! {
                week = end.weekOfMonth!
                date = date.endDayOfWeek()
            } else if end.weekOfMonth! != calendar.dateComponents([.weekOfMonth], from: calendar.date(byAdding: .day, value: -3, to: date.endDayOfWeek())!).weekOfMonth! {
                week = start.weekOfMonth!
                date = date.startDayOfWeek()
            } else {
                week = start.weekOfMonth!
            }
        } else {
            let base = calendar.date(byAdding: .day, value: 3, to: date.startDayOfMonth())!
            let weekOfMonth = calendar.dateComponents([.weekOfMonth], from: base).weekOfMonth!
            if weekOfMonth == 2 {
                week = calendar.dateComponents([.weekOfMonth], from: date).weekOfMonth! - 1
            } else {
                week = calendar.dateComponents([.weekOfMonth], from: date).weekOfMonth!
            }
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return "\(formatter.string(from: date)) Week \(week)"
        
    }
}
