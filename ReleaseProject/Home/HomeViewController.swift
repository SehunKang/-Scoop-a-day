//
//  HomeViewController.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/19.
//

import UIKit
import RealmSwift

class HomeViewController: UIViewController {

	var catData: Results<CatData>!
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	@IBOutlet weak var navigationBar: UINavigationBar!
	@IBOutlet weak var pageController: UIPageControl!
	
	override func viewDidLoad() {
        super.viewDidLoad()

		collectionView.dataSource = self
		collectionView.delegate = self
		registerXib()

		let realm = RealmService.shared.realm
		catData = realm.objects(CatData.self).sorted(byKeyPath: "createDate", ascending: true)
		
		pageController.hidesForSinglePage = true
		pageController.pageIndicatorTintColor = .systemGray4
		pageController.currentPageIndicatorTintColor = .systemGray
		pageController.numberOfPages = catData.count
		navigationBar.topItem?.title = catData.first?.catName
		setNavBar()
    }


//	func isAppAlreadyLaunchedOnce()->Bool{
//			let defaults = UserDefaults.standard
//
//			if defaults.bool(forKey: "isAppAlreadyLaunchedOnce"){
//				return true
//			} else {
//				defaults.set(true, forKey: "isAppAlreadyLaunchedOnce")
//				return false
//			}
//		}
	
	override func viewWillDisappear(_ animated: Bool) {
		if !catData.isEmpty {
			NotificationCenter.default.post(name: Notification.Name("NotificationIdentifier"), object: catData[getCurrentIndexPathOfCollectionView().item].catName)
		}
	}
	
	func test() {
		
		for i in 0...700 {
			let data = DailyData()
			data.urineCount = Int.random(in: 3...6)
			data.poopCount = Int.random(in: 1...3)
			data.date = Calendar.current.date(byAdding: .day, value: -(i + 1), to: Date().removeTime())!
			try! RealmService.shared.realm.write {
				catData.last?.dailyDataList.append(data)
			}
		}
	}
	
	func registerXib() {
		self.collectionView.register(UINib(nibName: CreateNewCatCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: CreateNewCatCollectionViewCell.identifier)
		
		self.collectionView.register(UINib(nibName: MainCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: MainCollectionViewCell.identifier)
	}
	
	func setNavBar() {
		if catData.count > 0 {
			navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "list.dash"), style: .plain, target: self, action: #selector(showActionSheet(_:)))
		}
	}
	
	@objc func showActionSheet(_ sender: UIBarButtonItem) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		let add = UIAlertAction(title: "add_cat_title".localized(withComment: ""), style: .default) { _ in
			self.addCatAlert()
		}
		let adjust = UIAlertAction(title: "adjust_count".localized(withComment: "UIAction of UIMenu in navbar_rightBarButtonItem"), style: .default) { _ in
			self.adjustCount()
		}
		let reset = UIAlertAction(title: "reset_count".localized(withComment: "UIAction of UImenu in navbar_rightBarButtonItem"), style: .default) { _ in
			self.resetCount()
		}
		let delete = UIAlertAction(title: "delete_data".localized(withComment: "UIAction of UIMenu in navbar_rightBarButtonItem. delete data of a cat"), style: .destructive) { _ in
			self.deleteAlert()
		}
		let cancel = UIAlertAction(title: "cancel".localized(withComment: ""), style: .cancel, handler: nil)
		alert.addAction(add)
		alert.addAction(adjust)
		alert.addAction(reset)
		alert.addAction(delete)
		alert.addAction(cancel)
		self.present(alert, animated: true, completion: nil)
	}
	
	
	func adjustCount() {
		let index = getCurrentIndexPathOfCollectionView()
		let cell = collectionView.cellForItem(at: index) as! MainCollectionViewCell
		cell.poopMinusButton.isHidden = false
		cell.poopMinusButton.tag = index.item
		cell.poopPlusButton.isHidden = false
		cell.poopPlusButton.tag = index.item
		cell.potatoMinusButton.isHidden = false
		cell.potatoMinusButton.tag = index.item
		cell.potatoPlusButton.isHidden = false
		cell.potatoPlusButton.tag = index.item
		cell.doneButton.isHidden = false
		cell.poopButton.isEnabled = false
		cell.potatoButton.isEnabled = false
		cell.eventButton.isEnabled = false
		cell.poopPlusButton.addTarget(self, action: #selector(poopButtonClicked(_:)), for: .touchUpInside)
		cell.poopMinusButton.addTarget(self, action: #selector(poopMinusButtonClicked(_:)), for: .touchUpInside)
		cell.potatoPlusButton.addTarget(self, action: #selector(potatoButtonClicked(_:)), for: .touchUpInside)
		cell.potatoMinusButton.addTarget(self, action: #selector(potatoMinusButtonClicked(_:)), for: .touchUpInside)
		cell.doneButton.addTarget(self, action: #selector(doneButtonClicked(_:)), for: .touchUpInside)
		navigationBar.topItem?.rightBarButtonItem?.isEnabled = false
		tabBarController?.tabBar.items![1].isEnabled = false
		collectionView.isScrollEnabled = false
		collectionView.reloadData()
		
	}
	
	@objc func doneButtonClicked(_ sender: UIButton) {
		let index = getCurrentIndexPathOfCollectionView()
		let cell = collectionView.cellForItem(at: index) as! MainCollectionViewCell
		cell.poopMinusButton.isHidden = true
		cell.poopPlusButton.isHidden = true
		cell.potatoMinusButton.isHidden = true
		cell.potatoPlusButton.isHidden = true
		cell.doneButton.isHidden = true
		cell.poopButton.isEnabled = true
		cell.potatoButton.isEnabled = true
		cell.eventButton.isEnabled = true
		navigationBar.topItem?.rightBarButtonItem?.isEnabled = true
		tabBarController?.tabBar.items![1].isEnabled = true
		collectionView.isScrollEnabled = true
		collectionView.reloadData()
	}
	
	@objc func poopMinusButtonClicked(_ sender: UIButton) {
		let cat = catData[sender.tag].catName
		RealmService.shared.subtractCountValue(of: cat, at: Date().removeTime(), item: .poop)
		let total = RealmService.shared.totalCountOfDay(of: cat, at: Date().removeTime(), item: .poop)
		let cell = collectionView.cellForItem(at: IndexPath(item: sender.tag, section: 0)) as! MainCollectionViewCell
		cell.poopCountLabel.text = "\(total)"
	}
	
	@objc func potatoMinusButtonClicked(_ sender: UIButton) {
		let cat = catData[sender.tag].catName
		RealmService.shared.subtractCountValue(of: cat, at: Date().removeTime(), item: .urine)
		let total = RealmService.shared.totalCountOfDay(of: cat, at: Date().removeTime(), item: .urine)
		let cell = collectionView.cellForItem(at: IndexPath(item: sender.tag, section: 0)) as! MainCollectionViewCell
		cell.potatoCountLabel.text = "\(total)"
	}
	
	func resetCount() {
		let indexPath = getCurrentIndexPathOfCollectionView()
		if indexPath.item < catData.count {
			RealmService.shared.changeCountValue(of: catData[indexPath.item].catName, at: Date().removeTime(), item: .poop, to: 0)
			RealmService.shared.changeCountValue(of: catData[indexPath.item].catName, at: Date().removeTime(), item: .urine, to: 0)
			collectionView.reloadItems(at: [IndexPath(item: indexPath.item, section: 0)])
		} else {
			return
		}
	}
	
	func deleteAlert() {
		
		let alert = UIAlertController(title: "delete_data".localized(withComment: ""), message: "confirm_deletion".localized(withComment: "ask when user delete data"), preferredStyle: .alert)
		let ok = UIAlertAction(title: "ok".localized(withComment: ""), style: .default) { _ in
			self.deleteData()
		}
		let cancel = UIAlertAction(title: "cancel".localized(withComment: ""), style: .cancel, handler: nil)
		alert.addAction(ok)
		alert.addAction(cancel)
		present(alert, animated: true, completion: nil)
	}
	
	func deleteData() {
		let indexPath = getCurrentIndexPathOfCollectionView()
		RealmService.shared.delete(catData[indexPath.item].catName)
		collectionView.reloadData()
		pageController.numberOfPages -= 1
		setNavBarTitleAsCatNameFromCollectionView()
	}
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
	}
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return catData.count == 0 ? 1 : catData.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		if catData.count == 0 {
			guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateNewCatCollectionViewCell.identifier, for: indexPath) as? CreateNewCatCollectionViewCell else { return UICollectionViewCell() }
			
			cell.addCatButton.addTarget(self, action: #selector(addCatButtonClicked(_:)), for: .touchUpInside)
			
			return cell
		} else {
			if navigationBar.topItem?.rightBarButtonItem == nil {
				setNavBar()
			}
			guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MainCollectionViewCell.identifier, for: indexPath) as? MainCollectionViewCell else { return UICollectionViewCell() }
			cell.potatoButton.tag = indexPath.item
			cell.poopButton.tag = indexPath.item
			cell.eventButton.tag = indexPath.item
			cell.poopButton.addTarget(self, action: #selector(poopButtonClicked(_:)), for: .touchUpInside)
			cell.potatoButton.addTarget(self, action: #selector(potatoButtonClicked(_:)), for: .touchUpInside)
			cell.eventButton.addTarget(self, action: #selector(eventButtoncClicked(_:)), for: .touchUpInside)
			cell.catButton.setImage(UIImage(named: "cat\(catData[indexPath.item].numForImage)"), for: .normal)
			if !catData[indexPath.item].dailyDataList.filter("date == %@", Date().removeTime()).isEmpty {
				cell.poopCountLabel.text = String(catData[indexPath.item].dailyDataList.filter("date == %@", Date().removeTime()).first!.poopCount)
				cell.potatoCountLabel.text = String(catData[indexPath.item].dailyDataList.filter("date == %@", Date().removeTime()).first!.urineCount)
			}
			return cell
		}
	}
		
	@objc func poopButtonClicked(_ sender: UIButton) {
		let cat = catData[sender.tag].catName
		RealmService.shared.addCountValue(of: cat, at: Date().removeTime(), item: .poop)
		let total = RealmService.shared.totalCountOfDay(of: cat, at: Date().removeTime(), item: .poop)
		let cell = collectionView.cellForItem(at: IndexPath(item: sender.tag, section: 0)) as! MainCollectionViewCell
		cell.poopCountLabel.text = "\(total)"
	}
	
	@objc func potatoButtonClicked(_ sender: UIButton) {
		let cat = catData[sender.tag].catName
		RealmService.shared.addCountValue(of: cat, at: Date().removeTime(), item: .urine)
		let total = RealmService.shared.totalCountOfDay(of: cat, at: Date().removeTime(), item: .urine)
		let cell = collectionView.cellForItem(at: IndexPath(item: sender.tag, section: 0)) as! MainCollectionViewCell
		cell.potatoCountLabel.text = "\(total)"
	}
	
	@objc func eventButtoncClicked(_ sender: UIButton) {
		
		let alert = UIAlertController(title: "event_title".localized(withComment: "alert title of eventAlert func"), message: nil, preferredStyle: .alert)
		let ok = UIAlertAction(title: "ok".localized(withComment: ""), style: .default) { action in
			if alert.textFields?.first?.text != "" {
				let event = alert.textFields?.first?.text!
				RealmService.shared.addRecord(of: self.catData[sender.tag].catName, at: Date().removeTime(), event: event!)
			}
		}
		let cancel = UIAlertAction(title: "cancel".localized(withComment: ""), style: .cancel, handler: nil)
		alert.addAction(ok)
		alert.addAction(cancel)
		alert.addTextField()
		self.present(alert, animated: true, completion: nil)

	}
		
	@objc func addCatButtonClicked(_ sender: UIButton) {
		addCatAlert()
	} 
	
	func addCatAlert() {
		let alert = UIAlertController(title: "add_cat_title".localized(withComment: "alert title in func_addCatButtonClicked"), message: "add_cat_message".localized(withComment: "alert message in func_addCatButtonClicked"), preferredStyle: .alert)
		let ok = UIAlertAction(title: "ok".localized(withComment: "ok button in alert"), style: .default) { [self] action in
			if alert.textFields?.first?.text != ""  {
				let newCat = alert.textFields!.first!.text!
				RealmService.shared.createNewCat(newCat)
				self.collectionView.reloadData()
				self.collectionView.scrollToItem(at: IndexPath(item: self.catData.count - 1, section: 0), at: .centeredHorizontally, animated: true)
				self.navigationBar.topItem?.title = newCat
				self.pageController.numberOfPages += 1
//				self.test()
			} else {
				return
			}
		}
		let cancel = UIAlertAction(title: "cancel".localized(withComment: "cancel button in alert"), style: .cancel, handler: nil)
		alert.addAction(ok)
		alert.addAction(cancel)
		alert.addTextField()
		self.present(alert, animated: true, completion: nil)

	}
	
	//visibleCells를 사용하면 두개 이상의 인덱스를 보여주거나 1인데 0을 보여주는 경우도 있지만 이렇게 큰 화면의 컬렉션뷰를 이용하는 경우 특정포인트를 이용하면 깔끔하게 해결된다.
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		setNavBarTitleAsCatNameFromCollectionView()
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let offSet = scrollView.contentOffset.x
		let width = scrollView.frame.width
		let horizontalCenter = width / 2

		pageController.currentPage = Int(offSet + horizontalCenter) / Int(width)

	}
	
	func setNavBarTitleAsCatNameFromCollectionView() {
		let visibleIndexPath = getCurrentIndexPathOfCollectionView()
		if catData.count == 0 {
			navigationBar.topItem?.title = "add_cat_title".localized(withComment: "")
			navigationBar.topItem?.rightBarButtonItem = nil
		} else {
			navigationBar.topItem?.title = catData[visibleIndexPath.item].catName
		}
	}
	
	func getCurrentIndexPathOfCollectionView() -> IndexPath {
		let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
		let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
		return collectionView.indexPathForItem(at: visiblePoint) ?? IndexPath(item: catData.count - 1, section: 0)
	}
	
}

