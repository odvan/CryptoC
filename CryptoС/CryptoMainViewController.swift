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
    var fetchedCurrencies: [CurrencyModel]? {
        didSet {
            currencyTable.reloadData()
        }
    }
    var collapseDetailViewController = true
    var rowSelectedAtLeastOnce = false
    var timer: Timer?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitViewController?.delegate = self
        splitViewController?.preferredDisplayMode = .allVisible
        
        mainFetch()
        
        print("\(self.view.frame.size.width), collapsed: \(splitViewController?.isCollapsed)")
        if self.view.frame.size.width == 736 || UIDevice.current.userInterfaceIdiom == .pad {
            firstSegue()
        }
        
        timer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(CryptoMainViewController.settingUpdate), userInfo: nil, repeats: true)

        
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        
//        mainFetch()
//    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("view bounds:\(view.bounds.height)|\(view.bounds.width)")
        if view.bounds.height == 414 && rowSelectedAtLeastOnce == false { // firing segue to the first currency converter vc when rotating iPhone6+ and splitting screen
            firstSegue()
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
    
    @objc private func settingUpdate() {
        
        mainFetch()
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        print(" 💔 💔 💔 ")
        return collapseDetailViewController
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { // casual preparing data for sending to ConverterVC
        
        if segue.identifier == "conversionSegue" {
            
            guard fetchedCurrencies != nil else
            { print("error: no data")
                return }
            
            rowSelectedAtLeastOnce = true
            
            let converterNC = segue.destination as! UINavigationController
            let converterVC = converterNC.topViewController as! ConverterVC
            
            if let indexFirst = sender as? IndexPath {
                let currency = fetchedCurrencies![indexFirst.row]
                converterVC.title = "convert \(currency.name)"
                converterVC.currency = currency
                
            } else if let index = currencyTable.indexPathForSelectedRow {
                print("✝️ index \(index)")
                let currency = fetchedCurrencies![index.row]
                converterVC.title = "convert \(currency.name)"
                converterVC.currency = currency
            }
        }
    }
    
    // Show first cell in ConverterVC
    func firstSegue() {
        rowSelectedAtLeastOnce = true
        print("It's iPhone Plus in landscape mode or iPad, collapsed: \(splitViewController?.isCollapsed), view bounds:\(view.bounds.height)|\(view.bounds.width)")
        let initialIndexPath = IndexPath(row: 0, section: 0)
        self.currencyTable.selectRow(at: initialIndexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
        
        let delayInSeconds = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            self.performSegue(withIdentifier: "conversionSegue", sender: initialIndexPath)
        }
        collapseDetailViewController = false
    }

    // MARK: - Table methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if fetchedCurrencies != nil {
            return fetchedCurrencies!.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = currencyTable.dequeueReusableCell(withIdentifier: Config.currencyCell, for: indexPath) as! CurrencyCell
        
        let currency = fetchedCurrencies![indexPath.row] as CurrencyModel
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

