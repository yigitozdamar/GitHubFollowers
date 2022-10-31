//
//  GFButton.swift
//  GitHubFollowers
//
//  Created by Yigit Ozdamar on 15.10.2022.
//

import UIKit

class GFButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(backgroundColor: UIColor, title: String) {
        self.init(frame: .zero)
        self.backgroundColor = backgroundColor
        self.setTitle(title, for: .normal)
    }
    
    private func configure() {
        layer.cornerRadius = 10
        setTitleColor(.white, for: .normal) //Normally we dont need because the default color is white.This is for example
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    func set(backGroundColor: UIColor, title: String) {
        self.backgroundColor = backGroundColor
        setTitle(title, for: .normal)
    }
}
