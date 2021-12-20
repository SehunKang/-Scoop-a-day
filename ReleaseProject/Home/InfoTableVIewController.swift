//
//  InfoTableVIewController.swift
//  ReleaseProject
//
//  Created by Sehun Kang on 2021/12/19.
//

import UIKit
import SnapKit
import WebKit

class InfoTableVIewController: UITableViewController {

    let infoTableTitle = ["\("version".localized(withComment: "")) \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)", "opensource_license".localized(withComment: "")]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "infoView_title".localized(withComment: "")
        self.tableView = UITableView(frame: self.tableView.frame, style: .insetGrouped)
        tableView.register(InfoTableViewCell.self, forCellReuseIdentifier: InfoTableViewCell.identifier)
        
    }

    @objc func goBack(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoTableTitle.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InfoTableViewCell.identifier, for: indexPath) as? InfoTableViewCell else { return UITableViewCell() }
        cell.label.text = infoTableTitle[indexPath.item]
        if indexPath.item == 1 {
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            if indexPath.item == 1 {
                let vc = LicenseNotificationViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

}

class LicenseNotificationViewController: UITableViewController {
    
    var sortedLicenseList = openSourceList.sorted(by: {$0.0 < $1.0})
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "opensource_license".localized(withComment: "")
        tableView.register(InfoTableViewCell.self, forCellReuseIdentifier: InfoTableViewCell.identifier)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        openSourceList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InfoTableViewCell.identifier, for: indexPath) as? InfoTableViewCell else { return UITableViewCell() }
        cell.label.text = sortedLicenseList[indexPath.item].key
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        55
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = WebView()
        vc.licenseUrl = sortedLicenseList[indexPath.item].value
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

class WebView: UIViewController, WKNavigationDelegate {
    
    let webView = WKWebView()
    var licenseUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        view = webView
        let url = URL(string: licenseUrl!)
        webView.load(URLRequest(url: url!))
        webView.allowsBackForwardNavigationGestures = true
        
    }
    
}


class InfoTableViewCell: UITableViewCell {
    
    static let identifier = "InfoTableViewCell"
    
    let label = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.edges.equalTo(contentView.safeAreaLayoutGuide).inset(10)
        }
        label.font = .systemFont(ofSize: 20)
        
        preservesSuperviewLayoutMargins = false
        separatorInset = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
        layoutMargins = UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

