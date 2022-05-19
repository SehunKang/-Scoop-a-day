//
//  CustomRxCollectionViewSectionedAnimatedDataSource.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/05/10.
//

import Foundation

import RxDataSources
import RxSwift
import RxCocoa

//새 데이터가 생성될 때 자동으로 스크롤 할 수 있게 하기 위해 만든 클래스.
final class CustomRxCollectionViewSectionedAnimatedDataSource<S: AnimatableSectionModelType>: RxCollectionViewSectionedAnimatedDataSource<S> {
    
    private let itemCount = BehaviorSubject<Int>(value: 0)
    private let bag = DisposeBag()
    
    override func collectionView(_ collectionView: UICollectionView, observedEvent: Event<RxCollectionViewSectionedAnimatedDataSource<S>.Element>) {
        super.collectionView(collectionView, observedEvent: observedEvent)
        
        itemCount.on(.next(collectionView.numberOfItems(inSection: 0)))
        
        Observable.zip(itemCount, itemCount.skip(1)) { prev, new -> Int? in
            return new > prev ? new : nil
        }
        .subscribe { count in
            guard let result = count.element else {return}
            guard let count = result else {return}
            collectionView.scrollToItem(at: IndexPath(item: count - 1, section: 0), at: .centeredHorizontally, animated: true)
        }
        .disposed(by: bag)
        
    }
}
