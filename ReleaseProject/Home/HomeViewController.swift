//
//  HomeViewController.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/19.
//

import UIKit

import RealmSwift

import RxSwift
import RxCocoa
import Action
import RxDataSources



class HomeViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageController: UIPageControl!
    
    //이게 맞는 방법일까?
    let viewModel = HomeViewModel(realmService: RealmService())
    
    let bag = DisposeBag()
    
    var dataSource: CustomRxCollectionViewSectionedAnimatedDataSource<TaskSection>!
    let currentIndexOfCat = BehaviorRelay<Int>(value: 0)
    let isModifying = BehaviorRelay<Bool>(value: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        configureCollectionView()
        configureDataSource()
        bind()
    }
    
    
    func configureCollectionView() {
        
        collectionView.rx.setDelegate(self)
            .disposed(by: bag)
        
        let background = CreateNewCatView()
        background.newCatButton.rx.tap
            .subscribe {[weak self] _ in
                self?.addCatAlert()
            }
            .disposed(by: background.bag)
        collectionView.backgroundView = background
    }
    
    func bind() {
        viewModel.sectionItems.bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        viewModel.numberOfCats
            .bind(to: pageController.rx.numberOfPages)
            .disposed(by: bag)
        
        viewModel.numberOfCats
            .subscribe {[weak self] count in
                guard let count = count.element else {return}
                if count == 0 {
                    self?.collectionView.backgroundView?.isHidden = false
                    self?.navigationController?.setNavigationBarHidden(true, animated: true)
                } else {
                    self?.collectionView.backgroundView?.isHidden = true
                    self?.navigationController?.setNavigationBarHidden(false, animated: true)
                }
            }
            .disposed(by: bag)
        
        collectionView.rx.didScroll
            .map {[weak self] Void -> Int in
                guard let self = self else {return 0}
                let offSet = self.collectionView.contentOffset.x
                let width = self.collectionView.frame.width
                let horizontalCenter = width / 2
                let count = Int(offSet + horizontalCenter) / Int(width)
                return count
            }
            .bind(to: currentIndexOfCat)
            .disposed(by: bag)
        
        let index = currentIndexOfCat.distinctUntilChanged()
        
        index.bind(to: pageController.rx.currentPage)
            .disposed(by: bag)
        
        //title에 현재 index의 고양이 이름을 보여줌
        _ = Observable
            .combineLatest(viewModel.catDataList, index) { (catData, index) -> String? in
                if catData.isEmpty {return nil}
                if index < catData.startIndex || index >= catData.endIndex {return nil}
                return catData[index].catName
            }
            .ifEmpty(default: "")
            .bind(to: self.navigationItem.rx.title)
            .disposed(by: bag)
        
        isModifying
            .map {!$0}
            .bind(to: collectionView.rx.isScrollEnabled,
                  tabBarController!.tabBar.rx.isUserInteractionEnabled,
                  navigationController!.navigationBar.rx.isUserInteractionEnabled)
            .disposed(by: bag)
        
    }
    
    func configureDataSource() {
        
        dataSource = CustomRxCollectionViewSectionedAnimatedDataSource<TaskSection>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MainCollectionViewCell.identifier, for: indexPath) as! MainCollectionViewCell
                
                if let self = self {
                    if item.dailyDataList.filter("date == %@", Date().removeTime()).first == nil {
                        self.viewModel.newDailyData(of: item)
                    }
                    let dailyData = item.dailyDataList.filter("date == %@", Date().removeTime()).first!
                    
                    cell.configure(with: dailyData, buttonAction: self.viewModel.buttonClicked(cat: item), modifyingEvent: self.isModifying)
                    
                    cell.doneButton.rx.tap
                        .subscribe {[weak self] _ in
                            self?.isModifying.accept(false)
                        }
                        .disposed(by: cell.bag)
                }
                return cell
            })
    }
    
    @IBAction func rightBarItemAction(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let addAction = UIAlertAction(title: "추가", style: .default) {[weak self] _ in
            self?.addCatAlert()
        }
        let adjustAction = UIAlertAction(title: "수정", style: .default) {[weak self] _ in
            if let self = self {
                self.isModifying.accept(!self.isModifying.value)
            }
        }
        let delete = UIAlertAction(title: "삭제", style: .destructive) {[weak self] _ in
            self?.deleteCatAlert()
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        [addAction, adjustAction, delete ,cancel].forEach {
            alert.addAction($0)
        }
        self.present(alert, animated: true)
    }
    
    private func addCatAlert() {
        let alert = UIAlertController(title: "추가", message: "추가하시겠습니까?", preferredStyle: .alert)
        let ok = UIAlertAction(title: "ok", style: .default) {[weak self] _ in
            guard let name = alert.textFields?.first?.text else {return}
            self?.viewModel.createCat(name: name).execute()
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        alert.addTextField()
        
        present(alert, animated: true)
    }
    
    private func deleteCatAlert() {
        let alert = UIAlertController(title: "정말 삭제하시겠습니까?", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "네", style: .default) {[weak self]_ in
            guard let self = self else {return}
            let index = self.currentIndexOfCat.value
            self.viewModel.deleteCat(indexOfCat: index)
            if self.collectionView.numberOfItems(inSection: 0) - 1 == index && index != 0 {
                self.currentIndexOfCat.accept(index - 1)
            } else {
                self.currentIndexOfCat.accept(index)
            }
        }
        let no = UIAlertAction(title: "아니오", style: .cancel, handler: nil)
        
        alert.addAction(no)
        alert.addAction(ok)
        
        present(alert, animated: true)

    }
    
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
    
}
