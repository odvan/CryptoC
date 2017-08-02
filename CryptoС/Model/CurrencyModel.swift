//
//  CurrencyModel.swift
//  CryptoС
//
//  Created by Artur Kablak on 27/07/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

import Foundation
import UIKit

enum Result <T>{ // completion handler for fetching method
    case Success(T)
    case Error(String)
}

struct CurrencyModel { // casual struct for currency model
    
    let name: String
    let id: String
    let rank: String
    let change: String
    let priceUSD: String
    let symbol: String
    
    init(name: String, id: String, rank: String, change: String, priceUSD: String, symbol: String) {
        
        self.name = name
        self.id = id
        self.rank = rank
        self.change = change
        self.priceUSD = priceUSD
        self.symbol = symbol
        
    }
    
}

extension CurrencyModel {
    
    init?(json: [String : Any]) { // init CurrencyModel from JSON data
        
        guard let name = json["name"] as? String else { return nil }
        let id = json["id"] as? String ?? ""
        let rank = json["rank"] as? String ?? ""
        let change = json["percent_change_1h"] as? String ?? ""
        let priceUSD = json["price_usd"] as? String ?? "0"
        let symbol = json["symbol"] as? String ?? ""
        
        self.name = name
        self.id = id
        self.rank = rank
        self.change = { () -> String in
            if change.characters.first == "-" {
                return "▽"
            } else {
                return "▲"
            }
        }()
        self.priceUSD = priceUSD
        self.symbol = symbol
    }
    
    
    // MARK: - Method for fetching currencies
    
    static func fetchCurrencies(fromURL: String, completion: @escaping (Result<[CurrencyModel]>) -> ()) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        guard let url = URL(string: fromURL) else {
            completion(.Error("Invalid URL, we can't update your feed"))
            print("Invalid URL, we can't update your feed")
            return
        }
        
        let urlRequest = URLRequest(url: url)
        let taskFetchingCurrencies = Config.session.dataTask(with: urlRequest) { (data, response, error) in
            
            
            guard error == nil else {
                completion(.Error(error!.localizedDescription))
                print("error while fecthing data: \(error!.localizedDescription)")
                return
            }
            print("🔶 \(response!)")
            
            var currencies: [CurrencyModel] = []
            
            guard let data = data else {
                completion(.Error(error?.localizedDescription ?? "There are no new currencies to show"))
                return }
            
            guard let jsonCurrencies = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [[String : Any]]
                else {
                    completion(.Error(error?.localizedDescription ?? "There are no new currencies to show"))
                    return }
            
            for currency in jsonCurrencies {
                if let someCurrency = CurrencyModel(json: currency) {
                    currencies.append(someCurrency)
                }
            }
            print("currencies: \(currencies)")
            completion(.Success(currencies))
        }
        taskFetchingCurrencies.resume()
    }
}
