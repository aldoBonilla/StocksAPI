//
//  File.swift
//  
//
//  Created by Aldo Bonilla on 04/04/23.
//

import Foundation
import StocksAPI

@main
struct StocksAPIExec {
    static let stocksAPI = StocksAPI()
    
    static func main() async {
        do {
            let quotes = try await stocksAPI.fetchQuotes(symbols: "AAPL,MSFT,GOOG,TSLA")
            print(quotes)
            
            let tickers = try await stocksAPI.searchTickers(query: "Apple")
            print(tickers)
            
            if let chart = try await stocksAPI.fetchChartData(symbol: "AAPL", range: .oneDay) {
                print(chart)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
