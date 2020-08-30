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
    
    // MARK: - Private
    
//    private lazy var companies = [
//        "Apple": "AAPL",
//        "Microsoft": "MSFT",
//        "Google": "GOOGL",
//        "Amazon": "AMZN",
//        "Facebook": "FB"
//    ]
    
    private lazy var companies: [String: String] = [:]
    
    private func requestQuote(for symbol: String) {
        let token = "pk_ef129a18397448e893e542215faafcb9"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self.parseQuote(from: data)
            } else {
                print("Network error!")
            }
        }
        
        dataTask.resume()
    }
    
    private func requestLogoLink(for symbol: String) {
        let token = "pk_ef129a18397448e893e542215faafcb9"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self.parseLogoQuote(from: data)
            } else {
                print("Network error!")
            }
        }
        
        dataTask.resume()
    }
    
    private func requestAvailableSymbols() {
        let token = "pk_ef129a18397448e893e542215faafcb9"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/ref-data/symbols?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self.parseSymbols(from: data)
            }
        }
        
        dataTask.resume()
    }
    
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double else { return print("Invalid JSON") }
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName,
                                       companySymbol: companySymbol,
                                       price: price,
                                       priceChange: priceChange)
            }
            
            print("Company name is: " + companyName)
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func parseLogoQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            guard
                let json = jsonObject as? [String: Any],
                let logoString = json["url"] as? String else {
                    return print("Invalid JSON")
            }
            
            let logoUrl = URL(string: logoString)
            loadLogoImage(from: logoUrl)
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func loadLogoImage(from url: URL?) {
        guard let url = url else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                
                DispatchQueue.main.async { [weak self] in
                    self?.logoImageView.image = UIImage(data: data)
                }
            } else {
                print("Network error!")
            }
        }
        
        dataTask.resume()
    }
    
    private func parseSymbols(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            guard
                let json = jsonObject as? [[String: Any]] else {
                    print("Invalid JSON")
                    return
            }
            
            for item in json {
                guard
                    let name = item["name"] as? String,
                    let symbol = item["symbol"] as? String else {
                        print("Invalid JSON")
                        return
                }
                companies[name] = symbol
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.companyPickerView.reloadAllComponents()
                self?.requestQuoteUpdate()
            }
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
        
    }
    
    private func displayStockInfo(companyName: String,
                                  companySymbol: String,
                                  price: Double,
                                  priceChange: Double) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        priceChangeLabel.textColor = priceChange.isZero ? .black : (priceChange > 0 ? .green : .red)
        
    }
    
    private func requestQuoteUpdate() {
        if (!activityIndicator.isAnimating) {
            activityIndicator.startAnimating()
        }
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        priceChangeLabel.textColor = .black
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
        requestLogoLink(for: selectedSymbol)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        
        activityIndicator.startAnimating()
        requestAvailableSymbols()
        
//        requestQuoteUpdate()
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
        requestQuoteUpdate()
    }
    
}
