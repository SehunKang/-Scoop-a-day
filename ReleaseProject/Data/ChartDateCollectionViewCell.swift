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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func layout() {
        self.contentView.addSubview(dateLabel)
        
        dateLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
    }
    
    func bind(reactor: ChartDateCellReactor) {
        let date = reactor.currentState.date
        let presentType = reactor.currentState.presentType
        
        let formatter = DateFormatter()
        switch presentType {
        case .week:
            let week = Calendar.current.dateComponents([.weekday], from: date).weekOfMonth!
            formatter.dateFormat = "MMM, Week \(week)"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        
        dateLabel.text = formatter.string(from: date)
    }

    
}
