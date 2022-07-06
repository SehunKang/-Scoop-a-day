//
//  Service.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/07/05.
//

class Service {
  unowned let provider: ServiceProviderType

  init(provider: ServiceProviderType) {
    self.provider = provider
  }
}
