//
//  SettingsView.swift
//  PurePKG
//
//  Created by lrdsnow on 4/27/24.
//

import Foundation
import UIKit

class DoubleLabelTableViewCell: UITableViewCell {
    let label1 = UILabel()
    let label2 = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        label1.translatesAutoresizingMaskIntoConstraints = false
        label1.text = "Text1"
        
        label2.translatesAutoresizingMaskIntoConstraints = false
        label2.text = "Text2"
        
        contentView.addSubview(label1)
        contentView.addSubview(label2)
        
        NSLayoutConstraint.activate([
            label1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label1.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label1.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            label2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label2.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label2.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            label2.leadingAnchor.constraint(greaterThanOrEqualTo: label1.trailingAnchor, constant: 16)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SettingsViewController: UIViewController {
    
    var tableView: UITableView!
    var data: [[String]] = [["App Version", "Device", "\(osString()) Version"], ["Jailbreak Type", "Architecture", "Tweak Count"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        } else {
            tableView = UITableView(frame: view.bounds, style: .grouped)
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        tableView.register(DoubleLabelTableViewCell.self, forCellReuseIdentifier: "Cell")
        
        if #available(iOS 13.0, *) {} else {
            tableView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        }
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DoubleLabelTableViewCell
        
        let string = data[indexPath.section][indexPath.row]
        cell.label1.text = string
        switch string {
        case "App Version":
            cell.label2.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        case "Device":
            cell.label2.text = appData.deviceInfo.modelIdentifier
        case "\(osString()) Version":
            cell.label2.text = "\(appData.deviceInfo.major).\(appData.deviceInfo.minor)\(appData.deviceInfo.patch == 0 ? "" : ".\(appData.deviceInfo.patch)")\(appData.deviceInfo.build_number == "0" ? "" : " (\(appData.deviceInfo.build_number))")"
        case "Jailbreak Type":
            cell.label2.text = (appData.jbdata.jbtype == .rootful || appData.jbdata.jbtype == .tvOS_rootful) ? "Rootful" : appData.jbdata.jbtype == .rootless ? "Rootless" : appData.jbdata.jbtype == .roothide ? "Roothide" : "Jailed"
        case "Architecture":
            cell.label2.text = appData.jbdata.jbarch
        case "Tweak Count":
            cell.label2.text = "\(appData.installed_pkgs.count)"
        default:
            cell.label2.text = "Unknown"
        }
        cell.backgroundColor = UIColor(hex: "#EBC2FF")?.withAlphaComponent(0.1)
        if #available(iOS 13.0, *) {} else {
            cell.contentView.frame = cell.contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
            cell.textLabel?.textColor = .white
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        if #available(iOS 13.0, *) {} else {
            let cornerRadius = 10
            var corners: UIRectCorner = []

            if indexPath.row == 0
            {
                corners.update(with: .topLeft)
                corners.update(with: .topRight)
            }

            if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
            {
                corners.update(with: .bottomLeft)
                corners.update(with: .bottomRight)
            }

            let maskLayer = CAShapeLayer()
            maskLayer.path = UIBezierPath(roundedRect: cell.bounds,
                                          byRoundingCorners: corners,
                                          cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
            cell.layer.mask = maskLayer
        }
    }
}
