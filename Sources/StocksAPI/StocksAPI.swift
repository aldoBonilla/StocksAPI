import Foundation

public struct StocksAPI {
    private let _session = URLSession.shared
    private let _jsonDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
    private let _baseURL = "https://query1.finance.yahoo.com"

    public init() {}
    
    public func fetchChartData(symbol: String, range: ChartRange) async throws -> ChartData? {
        guard var urlComponents = URLComponents(string: "\(_baseURL)/v8/finance/chart\(symbol)") else {
            throw APIError.invalidURL
        }
        urlComponents.queryItems = [
            .init(name: "range", value: range.rawValue),
            .init(name: "interval", value: range.interval),
            .init(name: "indicators", value: "quote"),
            .init(name: "includeTimeStamps", value: "true")
        ]
        guard let url = urlComponents.url else { throw APIError.invalidURL }
        let (response, statusCode): (ChartResponse, Int) = try await _fetch(url: url)
        if let error = response.error {
            throw APIError.httpStatusCodeFailed(statusCode: statusCode, error: error)
        }
        return response.data?.first
    }
    
    public func searchTickers(query: String, isEquityTypeOnly: Bool = true) async throws -> [Ticker] {
        guard var urlComponents = URLComponents(string: "\(_baseURL)/v1/finance/search") else {
            throw APIError.invalidURL
        }
        urlComponents.queryItems = [
            .init(name: "q", value: query),
            .init(name: "quotesCount", value: "20"),
            .init(name: "lange", value: "en-US")
        ]
        guard let url = urlComponents.url else { throw APIError.invalidURL }
        let (response, statusCode): (SearchTickersResponse, Int) = try await _fetch(url: url)
        if let error = response.error {
            throw APIError.httpStatusCodeFailed(statusCode: statusCode, error: error)
        }
        if isEquityTypeOnly {
            let data = response.data ?? []
            let filteredData = data.filter { ticker in
                let quoteType = ticker.quoteType ?? ""
                return quoteType.localizedCaseInsensitiveCompare("equity") == .orderedSame
            }
            return filteredData
        } else {
            return response.data ?? []
        }
        
    }
    
    public func fetchQuotes(symbols: String) async throws -> [Quote] {
        guard var urlComponents = URLComponents(string: "\(_baseURL)/v7/finance/quote") else {
            throw APIError.invalidURL
        }
        urlComponents.queryItems = [.init(name: "symbols", value: symbols)]
        guard let url = urlComponents.url else { throw APIError.invalidURL }
        let (response, statusCode): (QuoteResponse, Int) = try await _fetch(url: url)
        if let error = response.error {
            throw APIError.httpStatusCodeFailed(statusCode: statusCode, error: error)
        }
        return response.data ?? []
    }
    
    private func _fetch<D: Decodable>(url: URL) async throws -> (D, Int) {
        let (data, response) = try await _session.data(from: url)
        let statusCode = try _validateHTTPResponseCode(response)
        return (try _jsonDecoder.decode(D.self, from: data), statusCode)
    }
    
    private func _validateHTTPResponseCode(_ response: URLResponse) throws -> Int {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponseType
        }
        
        guard 200...299 ~= httpResponse.statusCode ||
                400...499 ~= httpResponse.statusCode else {
            throw APIError.httpStatusCodeFailed(statusCode: httpResponse.statusCode, error: nil)
        }
        return httpResponse.statusCode
    }
}
