//
//  ConverterVC.swift
//  CryptoС
//
//  Created by Artur Kablak on 27/07/17.
//  Copyright © 2017 Artur Kablak. All rights reserved.
//

import UIKit

class ConverterVC: UIViewController, UITextFieldDelegate {

    // MARK: - Constants & Variables

    @IBOutlet weak var numberField: UITextField! {
        didSet { // adding done button to number pad
            let toolbar = UIToolbar(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 0, height: 44)))
            toolbar.items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
                             UIBarButtonItem(barButtonSystemItem: .done, target: self.numberField, action: #selector(resignFirstResponder))]
            numberField.inputAccessoryView = toolbar
        }
    }
    @IBOutlet weak var conversionLabel: UILabel!
    @IBOutlet weak var conversionButton: UIButton!
    
    @IBOutlet weak var fromCurrency: UILabel!
    @IBOutlet weak var toCurrency: UILabel!
    
    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?
    
    var currency: CurrencyModel?
    var amountDefault: String = "1"
    var currencyToUSD = true
    
    
    // MARK: - VC life cycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true

        numberField.text = amountDefault
        numberField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardNotification(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillChangeFrame,
                                               object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        conversionMethod()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Method for moving textField when keyboard appears
    
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.keyboardHeightLayoutConstraint?.constant = 0.0
            } else {
                self.keyboardHeightLayoutConstraint?.constant = (0 - (endFrame?.size.height)!/2) + 10
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    func textFieldDidChange(_ textField: UITextField) { // changing currency exchange on the fly
        
        conversionMethod()
    }
    
    @IBAction func conversion(_ sender: Any) { // button for switching conversion
        
//        numberField.resignFirstResponder()
        currencyToUSD = !currencyToUSD
        conversionMethod()
    }
    
    
    // MARK: - Main method for converting currencies
    
    private func conversionMethod() {
        
        guard currency?.priceUSD != nil, numberField.text?.isEmpty == false, let sumToConvert = Double(numberField.text!)
            else { return }
        
        if currencyToUSD == true {
            fromCurrency.text = "(\(currency!.symbol))"
            toCurrency.text = "$"
            let conversion = Double(currency!.priceUSD)! * sumToConvert
            conversionLabel.text = String(conversion)
        } else {
            fromCurrency.text = "$"
            toCurrency.text = "(\(currency!.symbol))"
            let conversion = sumToConvert / Double(currency!.priceUSD)!
            let rounding = Double(round(10000 * conversion)/10000)
            conversionLabel.text = String(rounding)
        }

    }

}
