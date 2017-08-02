//
//  CurrencyCell.swift
//  CryptoС
//
//  Created by Artur Kablak on 27/07/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

import UIKit

class CurrencyCell: UITableViewCell {
    
    
    // MARK: - Constants & Variables
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var change: UILabel!
    @IBOutlet weak var price: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
//        price.baselineAdjustment = .alignCenters
    }


    // MARK: - Populating cell with fetched currencies
    
    func configure(_ currencyModel: CurrencyModel) {
        
        name.text = currencyModel.name
        change.text = currencyModel.change
        price.text = currencyModel.priceUSD
        
    }

}
