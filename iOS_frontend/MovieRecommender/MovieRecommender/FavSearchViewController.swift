//
//  FavSearchViewController.swift
//  MovieRecommender
//
//  Created by Tanmay Bakshi on 2018-07-04.
//  Copyright © 2018 Tanmay Bakshi. All rights reserved.
//

import UIKit
import Alamofire
import Alamofire_SwiftyJSON

let storage = UserDefaults.standard

class FavSearchViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var searchBar: UITextField!
    @IBOutlet var searchIndicator: UIActivityIndicatorView!
    @IBOutlet var movieTable: UITableView!
    @IBOutlet var statusLabel: UILabel!
    
    var ratingData = [MovieData]()
    var currentMovieData = [MovieData]()
    var searching = false
    
    let movies = MovieHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchIndicator.isHidden = true
        if let favourites = storage.value(forKey: "favs") {
            ratingData = (favourites as! [Data]).map { (md) -> MovieData in
                return NSKeyedUnarchiver.unarchiveObject(with: md) as! MovieData
            }
        } else {
            storage.set(ratingData.map({ (md) -> Data in
                return NSKeyedArchiver.archivedData(withRootObject: md)
            }), forKey: "favs")
            storage.synchronize()
        }
    }
    
    func search() {
        self.view.isUserInteractionEnabled = false
        searchIndicator.isHidden = false
        searchIndicator.startAnimating()
        let query = self.searchBar.text!
        DispatchQueue.global(qos: .userInitiated).async {
            self.currentMovieData = self.movies.splitThreadedSearchForMovieWith(title: query)
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true
                self.searchIndicator.isHidden = true
                self.searchIndicator.stopAnimating()
                self.searching = true
                self.statusLabel.text = "Search results"
                self.movieTable.reloadData()
                self.movieTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }
    
    @IBAction func clearSearch() {
        searching = false
        ratingData = (storage.value(forKey: "favs")! as! [Data]).map { (md) -> MovieData in
            return NSKeyedUnarchiver.unarchiveObject(with: md) as! MovieData
        }
        statusLabel.text = "My favourites"
        searchBar.text = ""
        movieTable.reloadData()
        movieTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    @IBAction func recommend() {
        searching = true
        movies.recommend({ (recommendations) in
            self.currentMovieData = recommendations
            DispatchQueue.main.async {
                self.statusLabel.text = "My recommendations"
                self.movieTable.reloadData()
                self.movieTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        search()
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searching ? currentMovieData.count : ratingData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieCell") as! MovieTableViewCell
        let movieTitle = searching ? currentMovieData[indexPath.row].title! : ratingData[indexPath.row].title!
        var titleParts = movieTitle.split(separator: " ")
        var year = "N/A"
        if titleParts.count > 1 {
            year = String(String(String(titleParts[titleParts.count-1]).split(separator: "(")[0]).split(separator: ")")[0])
            if let yi = Int(year) {
                if yi > 1900 {
                    _ = titleParts.popLast()
                } else {
                    year = "N/A"
                }
            } else {
                year = "N/A"
            }
        }
        let cleanedTitle = titleParts.joined(separator: " ")
        cell.movieTitle.text = cleanedTitle
        cell.movieYear.text = String(year)
        cell.movieTMBDid = searching ? currentMovieData[indexPath.row].tmdbId : ratingData[indexPath.row].tmdbId
        cell.movieId = searching ? currentMovieData[indexPath.row].movieId : ratingData[indexPath.row].movieId
        if !searching {
            cell.ratingButton1.isHidden = true
            cell.ratingButton2.isHidden = true
            cell.ratingButton3.isHidden = true
            cell.ratingButton4.isHidden = true
            cell.ratingButton5.isHidden = true
            cell.ratingLabel.text = "\(ratingData[indexPath.row].rating!)"
        } else {
            cell.ratingButton1.isHidden = false
            cell.ratingButton2.isHidden = false
            cell.ratingButton3.isHidden = false
            cell.ratingButton4.isHidden = false
            cell.ratingButton5.isHidden = false
            cell.ratingLabel.text = "Rating:"
        }
        cell.loadCover()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.dequeueReusableCell(withIdentifier: "movieCell")!.frame.height
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (_, actionIndexPath) in
            if self.searching {
                self.currentMovieData.remove(at: actionIndexPath.row)
            } else {
                self.ratingData.remove(at: actionIndexPath.row)
                storage.set(self.ratingData.map({ (md) -> Data in
                    return NSKeyedArchiver.archivedData(withRootObject: md)
                }), forKey: "favs")
                storage.synchronize()
            }
            tableView.reloadData()
            self.movieTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        return [delete]
    }
    
}
