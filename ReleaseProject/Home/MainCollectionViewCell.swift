//
//  MainCollectionViewCell.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/23.
//

import UIKit

import SnapKit
import RxSwift
import RxCocoa
import Action

class MainCollectionViewCell: UICollectionViewCell {
	
	static let identifier = "MainCollectionViewCell"
    
    var bag = DisposeBag()

	@IBOutlet weak var catButton: UIButton!
    
	@IBOutlet weak var poopButton: UIButton!
	@IBOutlet weak var potatoButton: UIButton!
	@IBOutlet weak var poopMinusButton: UIButton!
	@IBOutlet weak var poopPlusButton: UIButton!
	@IBOutlet weak var potatoMinusButton: UIButton!
	@IBOutlet weak var potatoPlusButton: UIButton!
	@IBOutlet weak var doneButton: UIButton!
	@IBOutlet weak var poopCountLabel: UILabel!
	@IBOutlet weak var potatoCountLabel: UILabel!
    
	override func awakeFromNib() {
        super.awakeFromNib()
        
        
        doneButton.setTitle(Strings.done, for: .normal)
        
    }
    
    func configure(with item: Observable<DailyData>, buttonAction: Action<ButtonType, Void>, modifyingEvent: BehaviorRelay<Bool>) {
        
        modifyingEvent
            .asDriver()
            .drive { [weak self] bool in
                let bool = !bool
                self?.poopPlusButton.isHidden = bool
                self?.poopMinusButton.isHidden = bool
                self?.potatoMinusButton.isHidden = bool
                self?.potatoPlusButton.isHidden = bool
                self?.doneButton.isHidden = bool
            }
            .disposed(by: bag)
                
        
        poopButton.rx.bind(to: buttonAction, input: .poop)
        poopPlusButton.rx.bind(to: buttonAction, input: .poopPlus)
        poopMinusButton.rx.bind(to: buttonAction, input: .poopMinus)
        potatoButton.rx.bind(to: buttonAction, input: .urine)
        potatoPlusButton.rx.bind(to: buttonAction, input: .urinePlus)
        potatoMinusButton.rx.bind(to: buttonAction, input: .urineMinus)
        
        //추가해야 위의 버튼들이 작동
        buttonAction.elements.subscribe { _ in}.disposed(by: bag)
        
        item.flatMap { data -> Observable<Int?> in
            data.rx.observe(Int.self, "poopCount")
        }
        .subscribe{ [weak self] count in
            let count = (count.element ?? 0) ?? 0
            self?.poopCountLabel.text = "\(count)"
        }
        .disposed(by: bag)
        
        item.flatMap { data -> Observable<Int?> in
            data.rx.observe(Int.self, "urineCount")
        }
        .subscribe{ [weak self] count in
            let count = (count.element ?? 0) ?? 0
            self?.potatoCountLabel.text = "\(count)"
        }
        .disposed(by: bag)

    }
    
        
    override func prepareForReuse() {
        bag = DisposeBag()
        super.prepareForReuse()
    }
	
}

extension MainCollectionViewCell: Localized {
    struct Strings {
        static let done = Localization.HomeView.done
    }
}
