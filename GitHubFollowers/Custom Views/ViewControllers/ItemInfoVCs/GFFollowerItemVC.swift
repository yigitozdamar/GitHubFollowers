//
//  GFFollowerItemVC.swift
//  GitHubFollowers
//
//  Created by Yigit Ozdamar on 25.10.2022.
//

import UIKit

class GFFollowerItemVC: GFItemInfoVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureItems()
    }
    
    private func configureItems() {
        itemInfoOne.set(itemInfoType: .followers, withCount: user.followers)
        itemInfoTwo.set(itemInfoType: .following, withCount: user.following)
        actionButton.set(backGroundColor: .systemGreen, title: "Get Followers")
    }
}
