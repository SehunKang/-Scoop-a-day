//
//  DataViewController.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/21.
//

import UIKit
import Charts
import RealmSwift

class DataViewController: UIViewController {

	@IBOutlet weak var chartView: BarChartView!
	
	@IBOutlet weak var testLabel: UILabel!
	var catData: Results<CatData>!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let realm = RealmService.shared.realm
		catData = realm.objects(CatData.self).sorted(byKeyPath: "createDate", ascending: true)
		let ad = Calendar.curr
		print(ad)
    }
    
	func getWeeklyData(before: Int) {
		
	}
	
	func getMonthlyData(before: Int) {
		
	}
	
	func getYearlyData(before: Int) {
		
	}


}
