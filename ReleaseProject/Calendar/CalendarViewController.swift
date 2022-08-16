//
//  CalendarViewController.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/21.
//

import UIKit

import FSCalendar
import ReactorKit
import RxCocoa

class CalendarViewController: UIViewController, StoryboardView {
    
    
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var poopLabel: UILabel!
    @IBOutlet weak var urineLabel: UILabel!
    
    @IBOutlet weak var poopPlusButton: UIButton!
    @IBOutlet weak var poopMinusButton: UIButton!
    @IBOutlet weak var urinePlusButton: UIButton!
    @IBOutlet weak var urineMinusButton: UIButton!
    
    @IBOutlet weak var editButton: UIButton!
    
    var disposeBag: DisposeBag = DisposeBag()
    
    var isEditingCount = BehaviorRelay<Bool>(value: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        editingUIConfigure()
    
    }
    
    init(reactor: CalendarViewReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    
    init?(coder: NSCoder, reactor: CalendarViewReactor) {
        super.init(coder: coder)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(reactor: CalendarViewReactor) {
        
        Observable.just(Void())
            .map { _ in
                return Reactor.Action.refresh
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        poopPlusButton.rx.tap
            .map { _ in
                Reactor.Action.countChangeButtonClicked(.poopPlus)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        poopMinusButton.rx.tap
            .map { _ in
                Reactor.Action.countChangeButtonClicked(.poopMinus)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        urinePlusButton.rx.tap
            .map { _ in
                Reactor.Action.countChangeButtonClicked(.urinePlus)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        urineMinusButton.rx.tap
            .map { _ in
                Reactor.Action.countChangeButtonClicked(.urineMinus)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.asObservable().map { $0.catName }
            .bind(to: navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        reactor.state.asObservable().map { String($0.poopCount) }
            .bind(to: poopLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.asObservable().map { String($0.urineCount) }
            .bind(to: urineLabel.rx.text)
            .disposed(by: disposeBag)
        
        calendar.rx.customDidSelect
            .map { date in
                Reactor.Action.dateSelected(date)
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        
    }
    
    func editingUIConfigure() {
        
        editButton.rx.tap
            .subscribe {[weak self] _ in
                guard let value = self?.isEditingCount.value else {
                    return
                }
                self?.isEditingCount.accept(!value)
                
            }
            .disposed(by: disposeBag)
        
        isEditingCount
            .map({ bool in
                !bool
            })
            .bind(to: poopPlusButton.rx.isHidden,
                  poopMinusButton.rx.isHidden,
                  urinePlusButton.rx.isHidden,
                  urineMinusButton.rx.isHidden
            )
            .disposed(by: disposeBag)
        
        isEditingCount.subscribe {[weak self] event in
            guard let bool = event.element else {return}
            if bool == true {
                self?.editButton.setTitle(Localization.HomeView.done, for: .normal)
                self?.editButton.setImage(nil, for: .normal)
                self?.tabBarController?.tabBar.items?[0].isEnabled = !bool
                self?.tabBarController?.tabBar.items?[2].isEnabled = !bool
                self?.calendar.isUserInteractionEnabled = !bool
            } else {
                self?.editButton.setTitle("", for: .normal)
                self?.editButton.setImage(UIImage(systemName: "pencil.circle"), for: .normal)
                self?.tabBarController?.tabBar.items?[0].isEnabled = !bool
                self?.tabBarController?.tabBar.items?[2].isEnabled = !bool
                self?.calendar.isUserInteractionEnabled = !bool
            }
        }
        .disposed(by: disposeBag)
        
    }
    
    
}

