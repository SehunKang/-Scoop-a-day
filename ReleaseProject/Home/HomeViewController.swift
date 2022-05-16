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
    
    @IBOutlet weak var modifyingTestButton: UIButton!
    @IBOutlet weak var newCatButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var testLabel: UILabel!
    //이게 맞는 방법일까?
    let viewModel = HomeViewModel(realmService: RealmService())
    
    let bag = DisposeBag()

    var dataSource: CustomRxCollectionViewSectionedAnimatedDataSource<TaskSection>!
    let currentIndexOfCat = BehaviorRelay<Int>(value: 0)
	
	override func viewDidLoad() {
        super.viewDidLoad()
        print(Realm.Configuration.defaultConfiguration.fileURL!)

		registerXib()
        configureDataSource()

        bindViewModel()
//        setNavBarTitleAsCatNameFromCollectionView()
        
    }
    
    
    func registerXib() {
//		self.collectionView.register(UINib(nibName: CreateNewCatCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: CreateNewCatCollectionViewCell.identifier)

        collectionView.register(UINib(nibName: MainCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: MainCollectionViewCell.identifier)
        
        collectionView.rx.setDelegate(self)
            .disposed(by: bag)
        
        
    }
    
    func bindViewModel() {
        //MARK: bind for collectionView
        
        viewModel.sectionItems.bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        //MARK: bind for Action
        
        deleteButton.rx.tap
            .subscribe {[weak self] _ in
                guard let self = self else {return}
                let index = self.currentIndexOfCat.value
                self.viewModel.deleteCat(indexOfCat: index)
                if self.collectionView.numberOfItems(inSection: 0) - 1 == index && index != 0 {
                    self.currentIndexOfCat.accept(index - 1)
                } else {
                    self.currentIndexOfCat.accept(index)
                }
            }
            .disposed(by: bag)
        
        newCatButton.rx.tap
            .subscribe { _ in
                print("index = \(self.currentIndexOfCat.value)")
            }
            .disposed(by: bag)
        
        //MARK: bind for UI
        viewModel.numberOfCats
            .bind(to: pageController.rx.numberOfPages)
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
        
        
        _ = Observable.combineLatest(viewModel.catDataList, index, resultSelector: { (catData, index) -> String? in
            if catData.isEmpty {return nil}
            if index < catData.startIndex || index >= catData.endIndex {return nil}
            return catData[index].catName
        })
        .ifEmpty(default: "")
        .bind(to: self.navigationItem.rx.title)
                
            
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
                
                cell.configure(with: dailyData, buttonAction: self.viewModel.buttonClicked(cat: item), modifyingEvent: self.modifyingTestButton.rx.tap)
                
                cell.isModifying()
                    .bind { self.testLabel.text = "\(!$0)"}
                    .disposed(by: cell.bag)
            }
            
            return cell
            })
        
            
        
        
    }
    
    @IBAction func rightBarItemAction(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let addAction = UIAlertAction(title: "추가", style: .default) { _ in
            let alert = UIAlertController(title: "추가", message: "추가하시겠습니까?", preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok", style: .default) { _ in
                guard let name = alert.textFields?.first?.text else {return}
                self.viewModel.createCat(name: name).execute()
            }
            alert.addAction(ok)
            alert.addTextField()
            
            self.present(alert, animated: true)
        }
        let adjustAction = UIAlertAction(title: "수정", style: .default) { _ in
            print("adjust")
        }
        let delete = UIAlertAction(title: "삭제", style: .default) { _ in
            print("delete")
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        [addAction, adjustAction, delete ,cancel].forEach {
            alert.addAction($0)
        }
        self.present(alert, animated: true)
    }
    
//
//	func setNavBar() {
//		if catData.count > 0 {
//            tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "list.dash"), style: .plain, target: self, action: #selector(showActionSheet(_:)))
//        } else {
//            tabBarController?.navigationItem.rightBarButtonItem = nil
//        }
//        tabBarController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(showSideMenu(_:)))
//        tabBarController?.navigationItem.backButtonTitle = "Back"
//    }
//
//	@objc func showActionSheet(_ sender: UIBarButtonItem) {
//		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//		let add = UIAlertAction(title: "add_cat_title".localized(withComment: ""), style: .default) { _ in
//			self.addCatAlert()
//		}
//		let adjust = UIAlertAction(title: "adjust_count".localized(withComment: "UIAction of UIMenu in navbar_rightBarButtonItem"), style: .default) { _ in
//			self.adjustCount()
//		}
//		let reset = UIAlertAction(title: "reset_count".localized(withComment: "UIAction of UImenu in navbar_rightBarButtonItem"), style: .default) { _ in
//			self.resetCount()
//		}
//		let delete = UIAlertAction(title: "delete_data".localized(withComment: "UIAction of UIMenu in navbar_rightBarButtonItem. delete data of a cat"), style: .destructive) { _ in
//			self.deleteAlert()
//		}
//		let cancel = UIAlertAction(title: "cancel".localized(withComment: ""), style: .cancel, handler: nil)
//		alert.addAction(add)
//		alert.addAction(adjust)
//		alert.addAction(reset)
//		alert.addAction(delete)
//		alert.addAction(cancel)
//		self.present(alert, animated: true, completion: nil)
//	}
//
//    @objc func showSideMenu(_ sender: UIBarButtonItem) {
//        let vc = InfoTableVIewController()
//        let backItem = UIBarButtonItem()
//        backItem.title = "Back"
//        navigationItem.backBarButtonItem = backItem
//        self.navigationController?.pushViewController(vc, animated: true)
//    }
//
//
//	func adjustCount() {
//		let index = getCurrentIndexPathOfCollectionView()
//		let cell = collectionView.cellForItem(at: index) as! MainCollectionViewCell
//		cell.poopMinusButton.isHidden = false
//		cell.poopMinusButton.tag = index.item
//		cell.poopPlusButton.isHidden = false
//		cell.poopPlusButton.tag = index.item
//		cell.potatoMinusButton.isHidden = false
//		cell.potatoMinusButton.tag = index.item
//		cell.potatoPlusButton.isHidden = false
//		cell.potatoPlusButton.tag = index.item
//		cell.doneButton.isHidden = false
//		cell.poopButton.isEnabled = false
//		cell.potatoButton.isEnabled = false
//		cell.eventButton.isEnabled = false
//		cell.poopPlusButton.addTarget(self, action: #selector(poopButtonClicked(_:)), for: .touchUpInside)
//		cell.poopMinusButton.addTarget(self, action: #selector(poopMinusButtonClicked(_:)), for: .touchUpInside)
//		cell.potatoPlusButton.addTarget(self, action: #selector(potatoButtonClicked(_:)), for: .touchUpInside)
//		cell.potatoMinusButton.addTarget(self, action: #selector(potatoMinusButtonClicked(_:)), for: .touchUpInside)
//		cell.doneButton.addTarget(self, action: #selector(doneButtonClicked(_:)), for: .touchUpInside)
//        //isenabled가 안됨. 바버튼아이템의 흐려지는 기능을 수동으로 추가해야하나?
//        tabBarController?.navigationController?.navigationBar.isUserInteractionEnabled = false
//		tabBarController?.tabBar.items![1].isEnabled = false
//		collectionView.isScrollEnabled = false
//		collectionView.reloadData()
//
//	}
//
//	@objc func doneButtonClicked(_ sender: UIButton) {
//		let index = getCurrentIndexPathOfCollectionView()
//		let cell = collectionView.cellForItem(at: index) as! MainCollectionViewCell
//		cell.poopMinusButton.isHidden = true
//		cell.poopPlusButton.isHidden = true
//		cell.potatoMinusButton.isHidden = true
//		cell.potatoPlusButton.isHidden = true
//		cell.doneButton.isHidden = true
//		cell.poopButton.isEnabled = true
//		cell.potatoButton.isEnabled = true
//		cell.eventButton.isEnabled = true
//        tabBarController?.navigationController?.navigationBar.isUserInteractionEnabled = true
//        tabBarController?.tabBar.items![1].isEnabled = true
//		collectionView.isScrollEnabled = true
//		collectionView.reloadData()
//	}
//
//	@objc func poopMinusButtonClicked(_ sender: UIButton) {
//		let cat = catData[sender.tag].catName
//		RealmService.shared.subtractCountValue(of: cat, at: Date().removeTime(), item: .poop)
//		let total = RealmService.shared.totalCountOfDay(of: cat, at: Date().removeTime(), item: .poop)
//		let cell = collectionView.cellForItem(at: IndexPath(item: sender.tag, section: 0)) as! MainCollectionViewCell
//		cell.poopCountLabel.text = "\(total)"
//	}
//
//	@objc func potatoMinusButtonClicked(_ sender: UIButton) {
//		let cat = catData[sender.tag].catName
//		RealmService.shared.subtractCountValue(of: cat, at: Date().removeTime(), item: .urine)
//		let total = RealmService.shared.totalCountOfDay(of: cat, at: Date().removeTime(), item: .urine)
//		let cell = collectionView.cellForItem(at: IndexPath(item: sender.tag, section: 0)) as! MainCollectionViewCell
//		cell.potatoCountLabel.text = "\(total)"
//	}
//
//	func resetCount() {
//		let indexPath = getCurrentIndexPathOfCollectionView()
//		if indexPath.item < catData.count {
//			RealmService.shared.changeCountValue(of: catData[indexPath.item].catName, at: Date().removeTime(), item: .poop, to: 0)
//			RealmService.shared.changeCountValue(of: catData[indexPath.item].catName, at: Date().removeTime(), item: .urine, to: 0)
//			collectionView.reloadItems(at: [IndexPath(item: indexPath.item, section: 0)])
//		} else {
//			return
//		}
//	}
//
//	func deleteAlert() {
//
//		let alert = UIAlertController(title: "delete_data".localized(withComment: ""), message: "confirm_deletion".localized(withComment: "ask when user delete data"), preferredStyle: .alert)
//		let ok = UIAlertAction(title: "ok".localized(withComment: ""), style: .default) { _ in
//			self.deleteData()
//		}
//		let cancel = UIAlertAction(title: "cancel".localized(withComment: ""), style: .cancel, handler: nil)
//		alert.addAction(ok)
//		alert.addAction(cancel)
//		present(alert, animated: true, completion: nil)
//	}
//
//	func deleteData() {
//		let indexPath = getCurrentIndexPathOfCollectionView()
//		RealmService.shared.delete(catData[indexPath.item].catName)
//		collectionView.reloadData()
//		pageController.numberOfPages -= 1
//		setNavBarTitleAsCatNameFromCollectionView()
//	}
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
    
    

}

//extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
//
//	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
//	}
//
//	func numberOfSections(in collectionView: UICollectionView) -> Int {
//		return 1
//	}
//
//	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//		return catData.count == 0 ? 1 : catData.count
//	}
//
//	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//		setNavBar()
//		if catData.count == 0 {
//			guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateNewCatCollectionViewCell.identifier, for: indexPath) as? CreateNewCatCollectionViewCell else { return UICollectionViewCell() }
//
//			cell.addCatButton.addTarget(self, action: #selector(addCatButtonClicked(_:)), for: .touchUpInside)
//
//			return cell
//		} else {
//			guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MainCollectionViewCell.identifier, for: indexPath) as? MainCollectionViewCell else { return UICollectionViewCell() }
//			cell.potatoButton.tag = indexPath.item
//			cell.poopButton.tag = indexPath.item
//			cell.eventButton.tag = indexPath.item
//			cell.poopButton.addTarget(self, action: #selector(poopButtonClicked(_:)), for: .touchUpInside)
//			cell.potatoButton.addTarget(self, action: #selector(potatoButtonClicked(_:)), for: .touchUpInside)
//			cell.eventButton.addTarget(self, action: #selector(eventButtoncClicked(_:)), for: .touchUpInside)
//
//			cell.catImage.image = UIImage(named: "cat\(catData[indexPath.item].numForImage)")
//
//			if catData[indexPath.item].dailyDataList.filter("date == %@", Date().removeTime()).isEmpty {
//				cell.poopCountLabel.text = "0"
//				cell.potatoCountLabel.text = "0"
//			} else {
//				cell.poopCountLabel.text = String(catData[indexPath.item].dailyDataList.filter("date == %@", Date().removeTime()).first!.poopCount)
//                cell.potatoCountLabel.text = String(catData[indexPath.item].dailyDataList.filter("date == %@", Date().removeTime()).first!.urineCount)
//			}
//			return cell
//		}
//	}
//
//	@objc func poopButtonClicked(_ sender: UIButton) {
//		let cat = catData[sender.tag].catName
//		RealmService.shared.addCountValue(of: cat, at: Date().removeTime(), item: .poop)
//		let total = RealmService.shared.totalCountOfDay(of: cat, at: Date().removeTime(), item: .poop)
//		let cell = collectionView.cellForItem(at: IndexPath(item: sender.tag, section: 0)) as! MainCollectionViewCell
//		cell.poopCountLabel.text = "\(total)"
//	}
//
//	@objc func potatoButtonClicked(_ sender: UIButton) {
//		let cat = catData[sender.tag].catName
//		RealmService.shared.addCountValue(of: cat, at: Date().removeTime(), item: .urine)
//		let total = RealmService.shared.totalCountOfDay(of: cat, at: Date().removeTime(), item: .urine)
//		let cell = collectionView.cellForItem(at: IndexPath(item: sender.tag, section: 0)) as! MainCollectionViewCell
//		cell.potatoCountLabel.text = "\(total)"
//	}
//
//	@objc func eventButtoncClicked(_ sender: UIButton) {
//
//		let alert = UIAlertController(title: "event_title".localized(withComment: "alert title of eventAlert func"), message: nil, preferredStyle: .alert)
//		let ok = UIAlertAction(title: "ok".localized(withComment: ""), style: .default) { action in
//			if alert.textFields?.first?.text != "" {
//				let event = alert.textFields?.first?.text!
//				RealmService.shared.addRecord(of: self.catData[sender.tag].catName, at: Date().removeTime(), event: event!)
//			}
//		}
//		let cancel = UIAlertAction(title: "cancel".localized(withComment: ""), style: .cancel, handler: nil)
//		alert.addAction(ok)
//		alert.addAction(cancel)
//		alert.addTextField()
//		self.present(alert, animated: true, completion: nil)
//
//	}
//
//	@objc func addCatButtonClicked(_ sender: UIButton) {
//		addCatAlert()
//	}
//
//	func addCatAlert() {
//		let alert = UIAlertController(title: "add_cat_title".localized(withComment: "alert title in func_addCatButtonClicked"), message: "add_cat_message".localized(withComment: "alert message in func_addCatButtonClicked"), preferredStyle: .alert)
//		let ok = UIAlertAction(title: "ok".localized(withComment: "ok button in alert"), style: .default) { [self] action in
//			let catNameChecker = catData.where {$0.catName == alert.textFields?.first?.text ?? ""}
//			if !catNameChecker.isEmpty {
//				let alert = UIAlertController(title: "cat_already_exist".localized(withComment: ""), message: nil, preferredStyle: .alert)
//				let ok = UIAlertAction(title: "ok".localized(withComment: ""), style: .default) { _ in self.addCatAlert()}
//				alert.addAction(ok)
//				self.present(alert, animated: true, completion: nil)
//			} else if alert.textFields?.first?.text != ""  {
//				let newCat = alert.textFields!.first!.text!
//				RealmService.shared.createNewCat(newCat)
//				self.collectionView.reloadData()
//				self.collectionView.scrollToItem(at: IndexPath(item: self.catData.count - 1, section: 0), at: .centeredHorizontally, animated: true)
//                self.tabBarController?.navigationItem.title = newCat
//				self.pageController.numberOfPages += 1
////				self.test()
//			} else {
//				return
//			}
//		}
//		let cancel = UIAlertAction(title: "cancel".localized(withComment: "cancel button in alert"), style: .cancel, handler: nil)
//		alert.addAction(ok)
//		alert.addAction(cancel)
//		alert.addTextField()
//		self.present(alert, animated: true, completion: nil)
//
//	}
//
//	//visibleCells를 사용하면 두개 이상의 인덱스를 보여주거나 1인데 0을 보여주는 경우도 있지만 이렇게 큰 화면의 컬렉션뷰를 이용하는 경우 특정포인트를 이용하면 깔끔하게 해결된다.
//	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//		setNavBarTitleAsCatNameFromCollectionView()
//	}
//
//	func scrollViewDidScroll(_ scrollView: UIScrollView) {
//		let offSet = scrollView.contentOffset.x
//		let width = scrollView.frame.width
//		let horizontalCenter = width / 2
//
//		pageController.currentPage = Int(offSet + horizontalCenter) / Int(width)
//
//	}
//
//	func setNavBarTitleAsCatNameFromCollectionView() {
//		let visibleIndexPath = getCurrentIndexPathOfCollectionView()
//		if catData.count == 0 {
//            tabBarController?.navigationItem.title = "add_cat_title".localized(withComment: "")
//		} else {
//            tabBarController?.navigationItem.title = catData[visibleIndexPath.item].catName
//		}
//	}
//
//	func getCurrentIndexPathOfCollectionView() -> IndexPath {
//		let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
//		let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
//		return collectionView.indexPathForItem(at: visiblePoint) ?? IndexPath(item: catData.count - 1, section: 0)
//	}
//
//}
//
