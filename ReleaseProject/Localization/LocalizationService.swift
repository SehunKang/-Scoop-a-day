//
//  LocalizationService.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/04/25.
//

import Foundation

protocol Localized {
    associatedtype Strings
}

struct Localization {
    struct HomeView {
        
        //MainCollectionVIewCell
        static let done = "done".localized(withComment: "고양이 감자, 맛동산 카운트 수정 완료 버튼")
    }
    
    struct HomeView_VoiceOver {
        
    }
    
    struct DataView {
        
    }
    
    struct DataView_VoiceOver {
        
    }
}
