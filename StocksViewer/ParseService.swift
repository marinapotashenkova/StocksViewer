//
//  ParseService.swift
//  StocksViewer
//
//  Created by Марина on 30.08.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import Foundation

class ParseService {
    
    func getCompanyInfo(from data: Data) -> StockInfo? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double else {
                    print("Invalid JSON")
                    return nil
            }
            
            print("Company name is: " + companyName)
            return StockInfo(companyName: companyName, companySymbol: companySymbol, price: price, priceChange: priceChange)
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
            return nil
        }
    }
    
    func getCompanies(from data: Data) -> [String : String]? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            guard
                let json = jsonObject as? [[String: Any]] else {
                    print("Invalid JSON")
                    return nil
            }
            
            var companies: [String : String] = [:]
            for item in json {
                guard
                    let name = item["name"] as? String,
                    let symbol = item["symbol"] as? String else {
                        print("Invalid JSON")
                        return nil
                }
                companies[name] = symbol
            }
            return companies
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
            return nil
        }
        
    }
    
    func getLogoUrl(from data: Data) -> URL? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            guard
                let json = jsonObject as? [String: Any],
                let logoString = json["url"] as? String else {
                    print("Invalid JSON")
                    return nil
            }
            
            return URL(string: logoString)
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
            return nil
        }
    }
    
}
