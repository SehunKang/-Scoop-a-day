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
    
    var disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    
    init(provider: ServiceProviderType) {
        super.init(nibName: nil, bundle: nil)
        reactor = CalendarViewReactor(provider: provider)
    }
    
    init?(coder: NSCoder, provider: ServiceProviderType) {
        super.init(coder: coder)
        reactor = CalendarViewReactor(provider: provider)
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
    


}

