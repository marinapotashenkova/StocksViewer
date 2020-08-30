//
//  ViewController.swift
//  StocksViewer
//
//  Created by Марина on 29.08.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // UI
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var selectCompanyLabel: UILabel!
    
    // MARK: - Private
    
    private let networkClient = NetworkClient()
    private lazy var companies: [String: String] = [ "-" : "-" ]
    
    private func display(stockInfo: StockInfo) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = stockInfo.companyName
        companySymbolLabel.text = stockInfo.companySymbol
        priceLabel.text = "\(stockInfo.price)"
        priceChangeLabel.text = "\(stockInfo.priceChange)"
        priceChangeLabel.textColor = stockInfo.priceChange.isZero ? .black : (stockInfo.priceChange > 0 ? .green : .red)
        
    }
    
    private func displayWaitingForRequest() {
        if activityIndicator.isAnimating {
            activityIndicator.startAnimating()
        }

        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        priceChangeLabel.textColor = .black
        
    }
    
    private func requestQuoteUpdate() {
        
        if activityIndicator.isAnimating {
            activityIndicator.startAnimating()
        }

        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        priceChangeLabel.textColor = .black
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        
        networkClient.requestQuote(for: selectedSymbol) { [unowned self] (stockInfo, error) in
            if let stockInfo = stockInfo,
                error == nil {
                DispatchQueue.main.async {
                    self.display(stockInfo: stockInfo)
                }
            } else if let error = error {
                self.errorHandler(error: error)
            } else {
                self.callAlertWith(title: "Error", message: "Sorry, there is some unexpected error occurred. Please try later")
            }
        }
        
        networkClient.requestLogoImage(for: selectedSymbol) { [unowned self] (imageData, error) in
            if let imageData = imageData,
                error == nil {
                DispatchQueue.main.async {
                    self.logoImageView.image = UIImage(data: imageData)
                }
            } else if let error = error {
                self.errorHandler(error: error)
            } else {
                self.callAlertWith(title: "Error", message: "Sorry, there is some unexpected error occurred. Please try later")
            }
        }
        
    }
    
    private func errorHandler(error: NetworkClientError) {
        switch error {
        case .noInternetConnection:
            self.callAlertWith(title: "Error", message: "It seems like your internet connection is lost. Please check your connection")
        case .requestError:
            self.callAlertWith(title: "Error", message: "Sorry, there is some error occurred on the app. We are already working on the fix. Please try later")
        case .serverAvailabilityError:
            self.callAlertWith(title: "Error", message: "Sorry, there is some error occurred on the server. We are already working on the fix. Please try later")
        default:
            self.callAlertWith(title: "Error", message: "Sorry, there is some unexpected error occurred. Please try later")
        }
    }
    
    private func callAlertWith(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                            
            let action = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in
            print("OK")
        }
        
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    private func performInitialRequests() {
        networkClient.requestAvailableCompanies { [unowned self] (companies, error) in
            if let companies = companies,
                error == nil {
                self.companies = companies
                DispatchQueue.main.async {
                    self.companyPickerView.reloadAllComponents()
                    self.requestQuoteUpdate()
                }
            } else if let error = error {
                self.errorHandler(error: error)
            } else {
                self.callAlertWith(title: "Error", message: "Sorry, there is some unexpected error occurred. Please try later")
            }
        }
    }
    
    private func setup() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        performInitialRequests()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        setup()
    }
    
}

// MARK: - UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
    
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectCompanyLabel.isHidden = true
        requestQuoteUpdate()
    }
    
}
