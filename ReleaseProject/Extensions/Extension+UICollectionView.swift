//
//  Extension+UICollectionView.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/07/05.
//

import UIKit
import RxSwift


extension UICollectionView {
    
    var currentIndex: Int {
        let offSet = self.contentOffset.x
        let width = self.frame.width
        let horizontalCenter = width / 2
        let count = Int(offSet + horizontalCenter) / Int(width)
        return count
    }
    
    
    func scrollPage(by: Int, animated: Bool) {
        let max = self.numberOfItems(inSection: 0) - 1
        if (self.currentIndex == 0 && by < 0) || (self.currentIndex == max && by > 0) {
            return
        }
        let index = IndexPath(item: self.currentIndex + by, section: 0)
        self.scrollToItem(at: index, at: .centeredHorizontally, animated: animated)
    }
    
    func scrollToEnd(animated: Bool) {
        let max = self.numberOfItems(inSection: 0) - 1
        self.scrollToItem(at: IndexPath(item: max, section: 0), at: .centeredHorizontally, animated: animated)
    }
    
    func increaseScroll() -> Int {
        self.scrollPage(by: 1, animated: true)
        return currentIndex + 1
    }
    
    func decreaseScroll() -> Int {
        self.scrollPage(by: -1, animated: true)
        return currentIndex - 1
    }
}
