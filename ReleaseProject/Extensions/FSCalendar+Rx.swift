//
//  FSCalendar+Rx.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/08/08.
//

import Foundation

import RxSwift
import RxCocoa
import FSCalendar

class RxFSCalendarDelegateProxy: DelegateProxy<FSCalendar, FSCalendarDelegate>, DelegateProxyType, FSCalendarDelegate {
    
    static func registerKnownImplementations() {
        self.register { calendar -> RxFSCalendarDelegateProxy in
            RxFSCalendarDelegateProxy(parentObject: calendar, delegateProxy: self)
        }
    }
    
    static func currentDelegate(for object: FSCalendar) -> FSCalendarDelegate? {
        object.delegate
    }
    
    static func setCurrentDelegate(_ delegate: FSCalendarDelegate?, to object: FSCalendar) {
        object.delegate = delegate
    }
}

extension Reactive where Base: FSCalendar {
    var delegate: DelegateProxy<FSCalendar, FSCalendarDelegate> {
        RxFSCalendarDelegateProxy.proxy(for: self.base)
    }
    
    var customDidSelect: Observable<Date> {
        delegate.methodInvoked(#selector(FSCalendarDelegate.calendar(_:didSelect:at:))).map { arr in
            arr[1] as! Date
        }
    }
}

