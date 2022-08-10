//
//  SerivceProvider.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/07/05.
//

import Foundation

protocol ServiceProviderType: AnyObject {
    var realmService: RealmServiceType { get }
    var catProvideService: CatProvideServiceType { get }
    var dataTaskService: DataTaskServiceType { get }
    var calendarTaskService: CalendarTaskServiceType { get }
}

final class ServiceProvider: ServiceProviderType {
    lazy var realmService: RealmServiceType = RealmService(provider: self)
    lazy var catProvideService: CatProvideServiceType = CatProvideService(provider: self)
    lazy var dataTaskService: DataTaskServiceType = DataTaskService(provider: self)
    lazy var calendarTaskService: CalendarTaskServiceType = CalendarTaskService(provider: self)
}
