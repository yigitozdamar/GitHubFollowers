//
//  UITableView+Ext.swift
//  GitHubFollowers
//
//  Created by Yigit Ozdamar on 31.10.2022.
//

import UIKit

extension UITableView {
    
    func reloadDataOnMainThread() {
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
    
    func removeExcessCells() {
        tableFooterView = UIView(frame: .zero)
    }
}
