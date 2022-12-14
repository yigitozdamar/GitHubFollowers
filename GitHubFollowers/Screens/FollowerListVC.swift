//
//  FollowerListVC.swift
//  GitHubFollowers
//
//  Created by Yigit Ozdamar on 16.10.2022.
//

import UIKit

protocol FollowerListVCDelegate: AnyObject {
    func didRequestFollowers(for username: String)
}

class FollowerListVC: GFDataLoadingVC {
    
    enum Section {
        case main
    }
    
    var username: String!
    var followers: [Follower] = []
    var filteredFollower: [Follower] = []
    var page = 1
    var hasMoreFollowers = true
    var isSearching = false
    var isLoadingMoreFollowers = false
    
    var collectionView : UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section,Follower>!
    
    init(username: String) {
        super.init(nibName: nil, bundle: nil)
        self.username = username
        title = username
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewController()
        configureCollectionView()
        configureSearchController()
        getFollowers(username: username, page: page)
        configureDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UIHelper.createThreeColumnFlownLayout(in: view))
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(FollowerCell.self, forCellWithReuseIdentifier: FollowerCell.reuseID)
    }
    
    func configureSearchController() {
        let searchController = UISearchController()
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search for a username"
        navigationItem.searchController = searchController
    }
    
    func configureViewController() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton
    }
    
    
    func getFollowers(username: String, page: Int) {
        showLoadingView()
        isLoadingMoreFollowers = true
        
        Task{
            do {
                let followers = try await NetworkManager.shared.getFollowers(for: username, page: page)
                updateUI(with: followers)
                dismissLoadingView()
            } catch  {
                if let gfError = error as? GFError {
                    presentGFAlert(title: "Bad Stuff Happened", message: gfError.rawValue, buttonTitle: "Ok")
                }else {
                    presentDefaultError()
                }
                dismissLoadingView()
            }
        }
        
        // Bu y??ntem de kullan??labilir...//
        
        //        guard let followers = try? await NetworkManager.shared.getFollowers(for: username, page: page) else {
        //            presentDefaultError()
        //            dismissLoadingView()
        //            return
        //        }
        //
        //        updateUI(with: followers)
        //        dismissLoadingView()
        
        
        // Bu ilk kullan??lan eski y??ntem... //
        
        //        NetworkManager.shared.getFollowers(for: username, page: page) { [weak self] result in
        //
        //            guard let self = self else {return}
        //            self.dismissLoadingView()
        //
        //            switch result {
        //                case .success(let followers):
        //                      updateUI(with: followers)
        //
        //                case .failure(let error):
        //                    self.presentGFAlertOnMainThread(title: "Bad Stuff Happened", message: error.rawValue, buttonTitle: "Ok")
        //            }
        //            isLoadingMoreFollowers = false
        //        }
        
        
    }
    
    func updateUI(with followers: [Follower]) {
        if followers.count < 100 {self.hasMoreFollowers = false}
        self.followers.append(contentsOf: followers)
        
        if self.followers.isEmpty {
            let message = "This user doesn't have any followers. Go follow them ????"
            DispatchQueue.main.async {
                self.showEmptyStateView(with: message, in: self.view)
            }
            return
        }
        self.updateData(on: self.followers)
    }
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section,Follower>(collectionView: collectionView, cellProvider: { collectionView, indexPath, follower in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowerCell.reuseID, for: indexPath) as! FollowerCell
            cell.set(follower: follower)
            return cell
        })
    }
    
    func updateData(on followers: [Follower]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Follower>()
        snapshot.appendSections([.main])
        snapshot.appendItems(followers)
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
        
    }
    
    @objc func addButtonTapped() {
        
        showLoadingView()
        
        Task{
            do{
                let user = try await NetworkManager.shared.getUserInfo(for: username)
                addUserToFavorites(user: user)
                dismissLoadingView()
            }catch{
                if let gfError = error as? GFError {
                    presentGFAlert(title: "Something went wrong", message: gfError.rawValue, buttonTitle: "Ok")
                }else{
                    presentDefaultError()
                }
                dismissLoadingView()
            }
        }
    }
    
    func addUserToFavorites(user: User) {
        let favorite = Follower(login: user.login, avatarUrl: user.avatarUrl)
        
        PersistanceManager.updateWith(favorite: favorite, actionType: .add) { [weak self] error in
            guard let self = self else { return }
            
            guard let error = error else {
                DispatchQueue.main.async {
                    self.presentGFAlert(title: "Success!", message: "You have successfully added this user :) ", buttonTitle: "Ok")
                }
                
                return
            }
            DispatchQueue.main.async {
                self.presentGFAlert(title: "Something went wrong!", message: error.rawValue, buttonTitle: "Ok")
            }
            
        }
    }
    
}

extension FollowerListVC: UICollectionViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height {
            guard hasMoreFollowers, isLoadingMoreFollowers else { return }
            page += 1
            getFollowers(username: username, page: page)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let activeArray = isSearching ? filteredFollower : followers
        let follower = activeArray[indexPath.item]
        
        let destVC = UserInfoVC()
        destVC.username = follower.login
        destVC.delegate = self
        let navController = UINavigationController(rootViewController: destVC)
        present(navController, animated: true)
        
    }
}

extension FollowerListVC: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let filter = searchController.searchBar.text, !filter.isEmpty else {
            filteredFollower.removeAll()
            updateData(on: followers)
            isSearching = false
            return
            
        }
        isSearching = true
        filteredFollower = followers.filter{ $0.login.lowercased().contains(filter.lowercased()) }
        updateData(on: filteredFollower)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        updateData(on: followers)
    }
}

extension FollowerListVC: FollowerListVCDelegate {
    
    func didRequestFollowers(for username: String) {
        //get followers for that user
        self.username = username
        page = 1
        title = username
        followers.removeAll()
        filteredFollower.removeAll()
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        getFollowers(username: username, page: page)
    }
    
}
