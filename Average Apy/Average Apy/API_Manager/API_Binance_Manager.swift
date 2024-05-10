//
//  File.swift
//  Average Apy
//
//  Created by Kimion 5/8/24.
//


import Foundation
import CryptoKit
import CommonCrypto


class BinanceAPIManager {
    let apiKey: String
    let secretKey: String
    let passphrase: String
    let baseURL = "https://api.binance.com"
    let binanceAPIURL = "https://api.binance.com"

    init(apiKey: String, secretKey: String, passphrase: String? = nil) {
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.passphrase = passphrase ?? ""
    }

    func fetchAccountValuation(completion: @escaping (String?, [AccountType: String]?, Error?) -> Void) {
        
        let endpoint = "/sapi/v1/asset/wallet/balance"
        let request = packageRequest(endpoint: endpoint)
        
        // 发送请求
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("\(#function) Data: ", String(data: data!, encoding: .utf8)!)
            // 检查错误
            if let error = error {
                print("\(#function)请求失败: \(error.localizedDescription)")
                completion("", [:], error)
                return
            }
            
            // 检查响应状态码
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("\(#function)请求失败，状态码: \(httpResponse.statusCode)")
                completion("", [:], error)
                return
            }
            
            var accoutAsset: [AccountType: String] = [:]
            var totalAssetCal: Double = 0
            var totalAsset: String = ""
            
            
            // 解析返回的JSON数据
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String: Any]]
                    // 解析后的 JSON 数组
                print("\(#function)jsonResponse: ", jsonResponse!)
                
                OKXAPIManager.marketPrice { BTCprint, error in
                    //获取BTC价格
                    print("BTCprint: ", BTCprint)
                    
                    jsonResponse?.forEach { accountData in
                        
                        if let walletName = accountData["walletName"] as? String,
                           let balance = accountData["balance"] as? String, balance != "0" {
                            print("walletName: ", walletName)
                            print("totalAssetCal: ", totalAssetCal)
                            
                            totalAssetCal = totalAssetCal + (Double(balance) ?? 0)
                            
                            switch walletName {
                            case "Spot":
                                accoutAsset[.spot] = String(Double(balance)! * BTCprint)
                            case "Funding":
                                accoutAsset[.funding] = String(Double(balance)! * BTCprint)
                            case "Cross Margin":
                                accoutAsset[.crossMargin] = String(Double(balance)! * BTCprint)
                            case "Isolated Margin":
                                accoutAsset[.isolatedMargin] = String(Double(balance)! * BTCprint)
                            case "USDⓈ-M Futures":
                                accoutAsset[.USDFutures] = String(Double(balance)! * BTCprint)
                            case "COIN-M Futures":
                                accoutAsset[.coinFutures] = String(Double(balance)! * BTCprint)
                            case "Earn":
                                accoutAsset[.finance] = String(Double(balance)! * BTCprint)
                            case "Options":
                                accoutAsset[.options] = String(Double(balance)! * BTCprint)
                            case "Trading Bots":
                                accoutAsset[.tradingBots] = String(Double(balance)! * BTCprint)
                            default:
                                break // 如果您有其他情况，您可以在这里添加相应的case语句
                            }
                        }
                    }
                    
                    totalAsset = String(totalAssetCal * BTCprint)
                    
                    print("totalAsset: ", totalAsset)
                    print("assets: ", accoutAsset)
                    
                    completion(totalAsset, accoutAsset, error)
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion("", [:] , error)
            }
        }.resume()
    }
    
    func fetchFundingAssets(completion: @escaping ([CurrencyAsset]?, Error?) -> Void) {
    //查看Funding账户各币种数量
        
        let endpoint = "/sapi/v1/asset/get-funding-asset"
        let request = packageRequest(endpoint: endpoint, httpMethod: "POST")
        
        // 发送请求
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("\(#function) Data: ", String(data: data!, encoding: .utf8)!)
            // 检查错误
            if let error = error {
                print("\(#function)请求失败: \(error.localizedDescription)")
                completion([], error)
                return
            }
            
            // 检查响应状态码
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("\(#function)请求失败，状态码: \(httpResponse.statusCode)")
                completion([], error)
                return
            }
            
            var assets: [CurrencyAsset] = []
            
            // 解析返回的JSON数据
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String: Any]]
                    // 解析后的 JSON 数组
                print("\(#function)jsonResponse: ", jsonResponse!)
                
                
                
                jsonResponse?.forEach { dict in
                    let currency = dict["asset"] as? String ?? ""
                    let balance = dict["free"] as? String ?? ""
                    let available = dict["free"] as? String ?? ""
                    let frozen = dict["locked"] as? String ?? ""
                    print("currency: ",currency, ", balance: ",balance, ", available: ", available, ", frozen: ", frozen)
                    assets.append(CurrencyAsset(currency: currency, balance: balance, available: available, frozen: frozen))
                }
                
                print("assets: ", assets)
                completion(assets, nil)
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion(nil, error)
            }
        }.resume()
    }
    
    func fetchSpotAssets(completion: @escaping ([CurrencyAsset]?, Error?) -> Void) {
        //查看fetchTradingAssets账户各币种数量
            
            let endpoint = "/sapi/v3/asset/getUserAsset"
            let request = packageRequest(endpoint: endpoint, httpMethod: "POST")
            
            // 发送请求
            URLSession.shared.dataTask(with: request) { data, response, error in
                print("\(#function) Data: ", String(data: data!, encoding: .utf8)!)
                // 检查错误
                if let error = error {
                    print("\(#function)请求失败: \(error.localizedDescription)")
                    completion([], error)
                    return
                }
                
                // 检查响应状态码
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    print("\(#function)请求失败，状态码: \(httpResponse.statusCode)")
                    completion([], error)
                    return
                }
                
                var assets: [CurrencyAsset] = []
                
                // 解析返回的JSON数据
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String: Any]]
                        // 解析后的 JSON 数组
                    print("\(#function)jsonResponse: ", jsonResponse!)
                    
                    
                    
                    jsonResponse?.forEach { dict in
                        let currency = dict["asset"] as? String ?? ""
                        let balance = dict["free"] as? String ?? ""
                        let available = dict["free"] as? String ?? ""
                        let frozen = dict["locked"] as? String ?? ""
                        print("currency: ",currency, ", balance: ",balance, ", available: ", available, ", frozen: ", frozen)
                        assets.append(CurrencyAsset(currency: currency, balance: balance, available: available, frozen: frozen))
                    }
                    
                    print("assets: ", assets)
                    completion(assets, nil)
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                    completion(nil, error)
                }
            }.resume()
    }
    
    func fetchSavingAssets(completion: @escaping ([CurrencyAsset]?, Error?) -> Void) {
    //查看Funding账户各币种数量
        let endpoint = "/sapi/v1/simple-earn/flexible/position"
        let request = packageRequest(endpoint: endpoint)
        
        // Perform the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("request (balance) error: ", error!)
                completion(nil, error)
                return
            }
            
            print("request (balance)  data: ", String(data: data, encoding: .utf8)!)

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let dataDict = json?["rows"] as? [[String: Any]]
                print("dataDict: ", dataDict!)
                var assets: [CurrencyAsset] = []

                dataDict?.forEach { dict in
                    print("dict: ", dict)
                
                    let currency = dict["asset"] as? String ?? ""
                    let balance = dict["totalAmount"] as? String ?? ""
                    let available = dict["pendingAmt"] as? String ?? ""
                    let frozen = dict["earnings"] as? String ?? ""
                    print("currency: ",currency, ", balance: ", ", available: ", available, ", frozen: ", frozen)
                    assets.append(CurrencyAsset(currency: currency, balance: balance, available: available, frozen: frozen))
                
                }
                print("assets: ", assets)
                completion(assets, nil)
                
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion(nil, error)
            }
        }.resume()
    }
    
    
    private func packageRequest(endpoint: String, parameter: [String: String]? = [:], httpMethod: String? = "get") -> URLRequest {
        // Binance API 端点
        let url = URL(string: baseURL + endpoint)!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        
        // 准备请求参数
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        var parameters: [String: String] = [
            "timestamp": String(timestamp)
        ]
        
        //将接口所需参数添加到请求参数
        parameters.merge(parameter ?? [:]) {(current, _) in
                return current
        }
        
        // 将参数转换为查询项
        let queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        components.queryItems = queryItems
        let queryString = components.query ?? ""
        print("queryString: ", queryString)
        
        
        //进行签名
        let signature = hmacSha256(data: queryString)
        print("signature: ", signature)

        //将签名添加到查询项
        parameters["signature"] = signature
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        //创建请求，然后把查询项添加到请求
        var request = URLRequest(url: components.url!)
        request.httpMethod = httpMethod
        print("request: ", request)
        
        // 添加 API Key ，内容类型到请求头
        request.addValue(apiKey, forHTTPHeaderField: "X-MBX-APIKEY")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return request
    }
    
    
    private func hmacSha256(data: String) -> String {
        
        let key = SymmetricKey(data: secretKey.data(using: .utf8)!)
        let hmac = HMAC<SHA256>.authenticationCode(for: data.data(using: .utf8)!, using: key)

        let hexString = hmac.compactMap { String(format: "%02x", $0) }.joined()

        return hexString
    }
    
    
}
