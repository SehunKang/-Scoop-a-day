//
//  MainCollectionViewCell.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/11/23.
//

import UIKit

class MainCollectionViewCell: UICollectionViewCell {
	
	static let identifier = "MainCollectionViewCell"

	@IBOutlet weak var poopButton: UIButton!
	@IBOutlet weak var potatoButton: UIButton!
	@IBOutlet weak var eventButton: UIButton!
	
	@IBOutlet weak var poopMinusButton: UIButton!
	@IBOutlet weak var poopPlusButton: UIButton!
	@IBOutlet weak var potatoMinusButton: UIButton!
	@IBOutlet weak var potatoPlusButton: UIButton!
	@IBOutlet weak var doneButton: UIButton!
	
	
	override func awakeFromNib() {
        super.awakeFromNib()
		
		poopMinusButton.setTitle("", for: .normal)
		poopPlusButton.setTitle("", for: .normal)
		potatoMinusButton.setTitle("", for: .normal)
		potatoPlusButton.setTitle("", for: .normal)
		doneButton.setTitle("done".localized(withComment: "done button"), for: .normal)
		
		poopPlusButton.isHidden = true
		poopMinusButton.isHidden = true
		potatoMinusButton.isHidden = true
		potatoPlusButton.isHidden = true
		doneButton.isHidden = true
		
    }
	
}
