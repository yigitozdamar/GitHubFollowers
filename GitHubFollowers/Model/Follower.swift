//
//  Follower.swift
//  GitHubFollowers
//
//  Created by Yigit Ozdamar on 17.10.2022.
//

import Foundation

struct Follower: Codable, Hashable {
    var login: String
    var avatarUrl: String
}
