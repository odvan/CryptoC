//
//  ViewController.swift
//  CryptoС
//
//  Created by Artur Kablak on 27/07/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

import UIKit

class CryptoMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISplitViewControllerDelegate {
    
    
    // MARK: - Constants & Variables

    @IBOutlet weak var currencyTable: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var fetchedCurrencies: [CurrencyModel]? { // our model
        didSet {
            currencyTable.reloadData()
        }
    }
    var filteredCurrencies: [CurrencyModel]? { // filtered currency
        didSet {
            currencyTable.reloadData()
        }
    }
    
    var collapseDetailViewController = true
    var rowSelectedAtLeastOnce = false
    var timer: Timer?
    let searchController = UISearchController(searchResultsController: nil)
    var firstLayout = true

    
    // MARK: - VC life cycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController?.delegate = self
        splitViewController?.preferredDisplayMode = .allVisible
        
        searchBarSetup()
        mainFetch()
        
        timer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(CryptoMainViewController.settingUpdate), userInfo: nil, repeats: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("view bounds:\(view.bounds.height)|\(view.bounds.width)")
        if view.bounds.height == 414 && rowSelectedAtLeastOnce == false { // firing segue to the first currency cell when rotating iPhone6+ to landscape mode
            firstSegue()
        }
        
        if firstLayout { // hiding searchBar at the start
            currencyTable.setContentOffset(CGPoint(x: 0, y: self.currencyTable.tableHeaderView!.frame.size.height - self.currencyTable.contentInset.top), animated: false)
            firstLayout = false
            print("offset: \(currencyTable.contentOffset.y)")
        }
    }
    

    // MARK: - Wrapping main method for fetching currencies
    
    private func mainFetch() {
        
        activityIndicator.startAnimating()
        
        CurrencyModel.fetchCurrencies(fromURL: Config.defaultURL) { [weak self] result in
            
            switch result {
            case .Success(let currencies):
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.activityIndicator.stopAnimating()
                    self?.fetchedCurrencies = currencies
                    self?.currencyTable.reloadData()
                    print("\(self?.view.frame.size.width), collapsed: \(self?.splitViewController?.isCollapsed)")
                    if self?.view.frame.size.height == 414 || UIDevice.current.userInterfaceIdiom == .pad { // firing segue to first currency cell after fetching data
                        self?.firstSegue()
                    }
                }
                
            case .Error(let message):
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self?.activityIndicator.stopAnimating()
                    self?.showAlertWith(title: "Error", message: message)
                }
            }
        }
    }
    
    @objc private func settingUpdate() { // updating results every five minutes
        
        mainFetch()
    }
    
    
    // MARK: - SearchBar setup & main method
    
    private func searchBarSetup() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.placeholder = NSLocalizedString("Search Currency", comment: "")
        currencyTable.tableHeaderView = searchController.searchBar
    }
    
    func searchingCurrency(searchText: String, scope: String = "All") {
        filteredCurrencies = fetchedCurrencies?.filter { currency in
            return currency.name.lowercased().contains(searchText.lowercased())
        }
        
    }
    
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        print(" 💔 💔 💔 ")
        return collapseDetailViewController
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { // casual data preparation for sending to ConverterVC
        
        if segue.identifier == "conversionSegue" {
            
            guard fetchedCurrencies != nil else
            { print("error: no data")
                return }
            
            let currency: CurrencyModel
            rowSelectedAtLeastOnce = true
            
            let converterNC = segue.destination as! UINavigationController
            let converterVC = converterNC.topViewController as! ConverterVC
            
            if let indexFirst = sender as? IndexPath {
                currency = fetchedCurrencies![indexFirst.row]
                converterVC.title = "convert \(currency.name)"
                converterVC.currency = currency
                
            } else if let index = currencyTable.indexPathForSelectedRow {
                print("✝️ index \(index)")
                
                if searchController.isActive && searchController.searchBar.text != "" {
                    currency = filteredCurrencies![index.row] as CurrencyModel
                } else {
                    currency = fetchedCurrencies![index.row] as CurrencyModel
                }
                converterVC.title = "convert \(currency.name)"
                converterVC.currency = currency
            }
        }
    }
    
    func firstSegue() { // Show first cell after fetching data in detail VC
        rowSelectedAtLeastOnce = true
        print("It's iPhone Plus in landscape mode or iPad, collapsed: \(splitViewController?.isCollapsed), view bounds:\(view.bounds.height)|\(view.bounds.width)")
        let initialIndexPath = IndexPath(row: 0, section: 0)
        self.currencyTable.selectRow(at: initialIndexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
        
        self.performSegue(withIdentifier: "conversionSegue", sender: initialIndexPath)
        collapseDetailViewController = false
    }

    
    // MARK: - Table methods, usual stuff
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredCurrencies!.count
        } else if fetchedCurrencies?.count != nil {
            return fetchedCurrencies!.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = currencyTable.dequeueReusableCell(withIdentifier: Config.currencyCell, for: indexPath) as! CurrencyCell
        
        let currency: CurrencyModel
        if searchController.isActive && searchController.searchBar.text != "" {
            currency = filteredCurrencies![indexPath.row] as CurrencyModel
        } else {
            currency = fetchedCurrencies![indexPath.row] as CurrencyModel
        }
        
        cell.configure(currency)
        
        return cell
        
    }
}


// MARK: - Displaying alert message when error occured

extension CryptoMainViewController {
    
    func showAlertWith(title: String, message: String, style: UIAlertControllerStyle = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: "OK", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
}


// MARK: - Conform to UISearchResultsUpdating protocol

extension CryptoMainViewController: UISearchResultsUpdating {
    @available(iOS 8.0, *)
    public func updateSearchResults(for searchController: UISearchController) {
        searchingCurrency(searchText: searchController.searchBar.text!)
    }
}
