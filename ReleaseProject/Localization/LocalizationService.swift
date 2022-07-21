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
        
        //HomeViewController
        static let addCatAction = "add_cat_title".localized(withComment: "홈뷰 고양이 추가 alert action, action 클릭 후의 title")
        static let adjustCountAction = "adjust_count".localized(withComment: "홈뷰 감자 맛동산 수 수정 alert action")
        static let deleteCatAction = "delete_data".localized(withComment: "홈뷰 고양이 삭제 alert action")
        static let cancel = "cancel".localized(withComment: "취소")
        static let addCatMessage = "add_cat_message".localized(withComment: "고양이 추가 액션 후 alert의 문구")
        static let confirm = "ok".localized(withComment: "확인")
        static let catAlreadyExist = "cat_already_exist".localized(withComment: "고양이를 추가할 때 이미 같은 이름의 고양이가 있을경우")
        static let deleteConfirm = "confirm_deletion".localized(withComment: "고양이 삭제할때 확인")
        static let yes = "ok".localized(withComment: "고양이 삭제할때 '네'일경우 ")
        static let no = "no".localized(withComment: "아니오 일 경우")
    }
    
    struct HomeView_VoiceOver {
        
    }
    
    struct DataView {
        static let poop = "poop".localized(withComment: "맛동산")
        static let pee = "urine".localized(withComment: "감자")
        
    }
    
    struct DataView_VoiceOver {
        
    }
}
