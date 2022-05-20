//
//  CreateNewCatView.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2022/05/20.
//

import UIKit
import RxSwift

class CreateNewCatView: UIView {

    @IBOutlet weak var newCatButton: UIButton!
    
    let bag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadView()
    }
    
    private func loadView() {
        let view = Bundle.main.loadNibNamed("CreateNewCatView", owner: self, options: nil)?.first as! UIView
        view.frame = bounds
        addSubview(view)
        
        newCatButton.setTitle("", for: .normal)
    }

    
}
