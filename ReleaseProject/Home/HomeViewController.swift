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



final class HomeViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageController: UIPageControl!
    
    //이게 맞는 방법일까?
    let viewModel: HomeViewModelType
    
    let bag = DisposeBag()
    
    var dataSource: CustomRxCollectionViewSectionedAnimatedDataSource<TaskSection>!
    
    init(catIndex: Int) {
        viewModel = HomeViewModel(index: catIndex)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        viewModel = HomeViewModel(index: 0)
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        configureCollectionView()
        configureDataSource()
        bind()
        setVisibleCellAsCurrentIndex()
    }
    
    func configureCollectionView() {
        
        collectionView.register(UINib(nibName: MainCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: MainCollectionViewCell.identifier)
        
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
        
        //페이지컨트롤러와 스크롤을 동기화
        collectionView.rx.didScroll
            .map {[weak self] Void -> Int in
                guard let self = self else {return 0}
                let offSet = self.collectionView.contentOffset.x
                let width = self.collectionView.frame.width
                let horizontalCenter = width / 2
                let count = Int(offSet + horizontalCenter) / Int(width)
                return count
            }
            .bind(to: viewModel.currentIndexOfCat)
            .disposed(by: bag)

        //고양이 수와 페이지컨트롤러 동기화
        viewModel.numberOfCats
            .bind(to: pageController.rx.numberOfPages)
            .disposed(by: bag)
        
        //고양이 수 0인지에 따라 고양이 추가 뷰(컬렉션뷰 백그라운드 뷰), 네비게이션 아이템 hidden 여부 동기화
        viewModel.numberOfCats
            .map { count in
                count == 0
            }
            .subscribe(onNext: { [weak self] bool in
                self?.collectionView.backgroundView?.isHidden = !bool
                self?.navigationController?.setNavigationBarHidden(bool, animated: true)
//                self?.tabBarController?.tabBar.isUserInteractionEnabled = !bool
            })
            .disposed(by: bag)
        
        //페이지컨트롤러와 현재 보고있는 인덱스 동기화
        viewModel.currentIndexOfCat
            .distinctUntilChanged()
            .bind(to: pageController.rx.currentPage)
            .disposed(by: bag)
        
        //title에 현재 index의 고양이 이름을 보여줌
        viewModel.currentTitle
            .bind(to: self.navigationItem.rx.title)
            .disposed(by: bag)
        
        
        //수정중인 경우 동작을 제한함
        viewModel.isModifying
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
                    
                    let dailyData = self.viewModel.getDailyData(item: item)
                    
                    cell.catButton.setImage(UIImage(named: "cat\(item.numForImage)"), for: .normal)
                    cell.configure(with: dailyData, buttonAction: self.viewModel.buttonClicked(cat: item), modifyingEvent: self.viewModel.isModifying)
                    
                    cell.doneButton.rx.tap
                        .subscribe {[weak self] _ in
                            self?.viewModel.isModifying.accept(false)
                        }
                        .disposed(by: cell.bag)
                }
                return cell
            })
    }
    
    private func setVisibleCellAsCurrentIndex() {
        
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        if collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.scrollToItem(at: IndexPath(item: viewModel.currentIndexOfCat.value, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    
    @IBAction func rightBarItemAction(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let addAction = UIAlertAction(title: "추가", style: .default) {[weak self] _ in
            self?.addCatAlert()
        }
        let adjustAction = UIAlertAction(title: "수정", style: .default) {[weak self] _ in
            if let self = self {
                self.viewModel.isModifying.accept(!self.viewModel.isModifying.value)
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
    
    
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
    
}

//MARK: - Alerts
extension HomeViewController {
    
    private func addCatAlert() {
        let alert = UIAlertController(title: "추가", message: "추가하시겠습니까?", preferredStyle: .alert)
        let ok = UIAlertAction(title: "ok", style: .default) {[weak self] _ in
            guard let name = alert.textFields?.first?.text, let self = self else {return}
            self.viewModel.createCat(name: name)
                .subscribe(onFailure: { _ in
                    self.duplicateCatNameAlert()
                })
                .disposed(by: self.bag)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(ok)
        alert.addAction(cancel)
        alert.addTextField()
        
        present(alert, animated: true)
    }
    
    private func deleteCatAlert() {
        let alert = UIAlertController(title: "정말 삭제하시겠습니까?", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "네", style: .default) {[weak self] _ in
            guard let self = self else {return}
            let index = self.viewModel.currentIndexOfCat.value
            self.viewModel.deleteCat()
            if self.collectionView.numberOfItems(inSection: 0) - 1 == index && index != 0 {
                self.viewModel.currentIndexOfCat.accept(index - 1)
            } else {
                self.viewModel.currentIndexOfCat.accept(index)
            }
        }
        let no = UIAlertAction(title: "아니오", style: .cancel, handler: nil)
        
        alert.addAction(no)
        alert.addAction(ok)
        
        present(alert, animated: true)

    }
    
    private func duplicateCatNameAlert() {
        let alert = UIAlertController(title: "이미 존재하는 이름입니다.", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "네", style: .default) { [weak self] _ in
            self?.addCatAlert()
        }
        alert.addAction(ok)
        present(alert, animated: true)
    }

}
