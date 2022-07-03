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
            let week = Calendar.current.dateComponents([.weekOfMonth], from: date).weekOfMonth!
            formatter.dateFormat = "MMM"
            text = "\(formatter.string(from: date)) Week \(week)"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            text = formatter.string(from: date)
        case .year:
            formatter.dateFormat = "yyyy"
            text = formatter.string(from: date)
        }
        dateLabel.text = text
    }
}
