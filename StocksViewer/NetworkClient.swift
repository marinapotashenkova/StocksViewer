//
//  NetworkClient.swift
//  StocksViewer
//
//  Created by Марина on 30.08.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import Foundation

enum NetworkClientError: Error {
    case noInternetConnection
    case serverAvailabilityError
    case requestError
    case unhandledError
}

class NetworkClient {
    
    // Private
    
    private let token = "pk_ef129a18397448e893e542215faafcb9"
    
    private let parseService = ParseService()
    
    private func generateErrorFrom(statusCode: Int?, error: Error?) -> NetworkClientError {
        if let statusCode = statusCode {
            if statusCode / 100 == 4 {
                return .requestError
            } else if statusCode / 100 == 5 {
                return .serverAvailabilityError
            }
        } else if error != nil {
            return .noInternetConnection
        }
        return .unhandledError
    }
    
    private func loadLogoImage(from url: URL, completionHandler: @escaping (Data?, NetworkClientError?) -> Void) {
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                completionHandler(data, nil)
            } else {
                print("Network error!")
                let generatedError = self.generateErrorFrom(statusCode: (response as? HTTPURLResponse)?.statusCode, error: error)
                completionHandler(nil, generatedError)
                
            }
        }
        
        dataTask.resume()
    }
    
    // Public
    
    func requestQuote(for symbol: String, completionHandler: @escaping (StockInfo?, NetworkClientError?) -> ()){
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            completionHandler(nil, .requestError)
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                if let companyInfo = self.parseService.getCompanyInfo(from: data) {
                    completionHandler(companyInfo, nil)
                } else {
                    completionHandler(nil, .requestError)
                }
            } else {
                print("Network error!")
                let generatedError = self.generateErrorFrom(statusCode: (response as? HTTPURLResponse)?.statusCode, error: error)
                completionHandler(nil, generatedError)
            }
        }
        
        dataTask.resume()
    }
    
    func requestAvailableCompanies(completionHandler: @escaping ([String: String]?, NetworkClientError?) -> Void) {
        guard let url = URL(string: "https://cloud.iexapis.com/stable/ref-data/symbols?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                if let companies = self.parseService.getCompanies(from: data) {
                    completionHandler(companies, nil)
                } else {
                    completionHandler(nil, .requestError)
                }
            } else {
                print("Network error!")
                let generatedError = self.generateErrorFrom(statusCode: (response as? HTTPURLResponse)?.statusCode, error: error)
                completionHandler(nil, generatedError)
                
            }
        }
        
        dataTask.resume()
    }
    
    func requestLogoImage(for symbol: String, completionHandler: @escaping (Data?, NetworkClientError?) -> Void) {
        
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)") else {
            completionHandler(nil, .requestError)
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                if let logoUrl = self.parseService.getLogoUrl(from: data) {
                    self.loadLogoImage(from: logoUrl) { (imageData, imageError) in
                        if let imageData = imageData,
                            imageError == nil {
                            completionHandler(imageData, imageError)
                        }
                    }
                } else {
                    completionHandler(nil, .requestError)
                }
            } else {
                print("Network error!")
                let generatedError = self.generateErrorFrom(statusCode: (response as? HTTPURLResponse)?.statusCode, error: error)
                completionHandler(nil, generatedError)
            }
        }
            
        dataTask.resume()
    }
    
}


