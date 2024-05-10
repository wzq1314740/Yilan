//
//  API_Manager.swift
//  Average Apy
//
//  Created by ChatGPT on 5/4/24.
//

import Foundation
import CryptoKit



class OKXAPIManager {
    let apiKey: String
    let secretKey: String
    let passphrase: String
    let baseURL = "https://www.okx.com"

    init(apiKey: String, secretKey: String, passphrase: String) {
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.passphrase = passphrase
    }

    func fetchAccountValuation(completion: @escaping (String?, [AccountType: String]?, Error?) -> Void) {
        //查看账户总资产估值
        struct Response: Codable {
            let code: String
            let data: [AccountData]
            let msg: String
        }
        
        // 定义一个结构体来匹配 JSON 中的 details 对象
        struct AccountValuation: Codable {
            let classic: String
            let earn: String
            let funding: String
            let trading: String
        }

        // 定义一个结构体来匹配 JSON 中的顶层数据结构
        struct AccountData: Codable {
            let details: AccountValuation
            let totalBal: String
            let ts: String // 或使用 Int 如果时间戳是整数值
        }
        
        let endpoint = "/api/v5/asset/asset-valuation?ccy=usd"
        let request = packageRequest(endpoint: endpoint)

        // Perform the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("request (asset-valuation) error: ", error!)
                completion("", nil, error)
                return
            }
            
            //print("request (asset-valuation) data: ", String(data: data, encoding: .utf8)!)


            do {
                // 使用JSONDecoder来解析JSON数据为Swift对象
                let decoder = JSONDecoder()
                
                // 由于 JSON 数据包含数组，我们首先需要将其解码为一个包含 AccountData 的数组
                let jsonResponse = try? decoder.decode(Response.self, from: data)
                //print("jsonData (asset-valuation) : ", jsonData!)
                if let  accountData = jsonResponse?.data.first {
                    print("Total Balance: \(accountData.totalBal), funding: \(accountData.details.funding), trading: \(accountData.details.trading), Earn: \(accountData.details.earn)")
                    
                    let accoutAsset: [AccountType: String] = [.funding: accountData.details.funding, .trading: accountData.details.trading, .finance: accountData.details.earn]
                    
                    completion(accountData.totalBal, accoutAsset, error)
                    
                    
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func fetchFundingAssets(completion: @escaping ([CurrencyAsset]?, Error?) -> Void) {
    //查看Funding账户各币种数量
        let endpoint = "/api/v5/asset/balances"
        let request = packageRequest(endpoint: endpoint)
        
        // Perform the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("request (fetchFundingAssets) error: ", error!)
                completion(nil, error)
                return
            }
            
            print("request (fetchFundingAssets)  data: ", String(data: data, encoding: .utf8)!)

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let dataDict = json?["data"] as? [[String: Any]]
                print("dataDict: ", dataDict!)
                var assets: [CurrencyAsset] = []

                dataDict?.forEach { dict in
                    print("dict: ", dict)
                
                    let currency = dict["ccy"] as? String ?? ""
                    let balance = dict["bal"] as? String ?? ""
                    let available = dict["availBal"] as? String ?? ""
                    let frozen = dict["frozenBal"] as? String ?? ""
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
    
    func fetchTradingAssets(completion: @escaping ([CurrencyAsset]?, Error?) -> Void) {
    //查看Funding账户各币种数量
        let endpoint = "/api/v5/account/balance"
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
                let dataDict = json?["data"] as? [[String: Any]]
                var assets: [CurrencyAsset] = []
                
                dataDict?.forEach { dict in
                    if let details = dict["details"] as? [[String: Any]] {
                        details.forEach { detail in
                            let currency = detail["ccy"] as? String ?? ""
                            let balance = detail["eq"] as? String ?? ""
                            let available = detail["availBal"] as? String ?? ""
                            let frozen = detail["frozenBal"] as? String ?? ""
                            let liability = detail["liab"] as? String ?? ""
                            print("currency: ",currency, ", balance: ",balance, ", available: ", available, ", frozen: ", frozen, "liability: ", liability)
                            assets.append(CurrencyAsset(currency: currency, balance: balance, available: available, frozen: frozen, liability: liability))
                        }
                    }
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
        let endpoint = "/api/v5/finance/savings/balance"
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
                let dataDict = json?["data"] as? [[String: Any]]
                print("dataDict: ", dataDict!)
                var assets: [CurrencyAsset] = []

                dataDict?.forEach { dict in
                    print("dict: ", dict)
                
                    let currency = dict["ccy"] as? String ?? ""
                    let balance = dict["amt"] as? String ?? ""
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
    
    private func packageRequest(endpoint: String) -> URLRequest {
        
        let url = URL(string: baseURL + endpoint)!
        print("Url: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Prepare the timestamp
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        // Prepare the signature
        let preHash = timestamp + "GET" + endpoint
        let signature = hmacSha256(data: preHash, secret: secretKey)
        
        // Set the request headers
        request.addValue(apiKey, forHTTPHeaderField: "OK-ACCESS-KEY")
        request.addValue(timestamp, forHTTPHeaderField: "OK-ACCESS-TIMESTAMP")
        request.addValue(passphrase, forHTTPHeaderField: "OK-ACCESS-PASSPHRASE")
        request.addValue(signature, forHTTPHeaderField: "OK-ACCESS-SIGN")
        
        return request
    }
    
    
    private func hmacSha256(data: String, secret: String) -> String {
        let key = SymmetricKey(data: secret.data(using: .utf8)!)
        let hmac = HMAC<SHA256>.authenticationCode(for: data.data(using: .utf8)!, using: key)
        
        return Data(hmac).base64EncodedString()
    }
    
    
    static func marketPrice(instId: String? = "BTC-USDT", completion: @escaping (Double, Error?) -> Void) {
    //获取币种指数价格
        let instId = instId ?? "BTC-USDT"
        let url = URL(string: "https://www.okx.com/api/v5/market/index-tickers?instId=\(instId)")!
        print("url: ", url)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Perform the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("\(#function) Data: ", String(data: data!, encoding: .utf8)!)
            if let error = error {
                print("\(#function)请求失败: \(error.localizedDescription)")
                completion(0, error)
                return
            }
            
            // 检查响应状态码
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("\(#function)请求失败，状态码: \(httpResponse.statusCode)")
                completion(0, error)
                return
            }

            do {
                // 使用 JSONSerialization 解析 JSON 数据
                if let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any],
                   let dataArray = jsonResponse["data"] as? [[String: Any]] {
                    print("\(#function)jsonResponse: ", jsonResponse)
                    // 遍历数据数组，查找符合条件的数据
                    for dataItem in dataArray {
                        if let instId = dataItem["instId"] as? String,
                           instId == "BTC-USDT",
                           let idxPx = dataItem["idxPx"] as? String {
                            
                            print("BTC价格： ", idxPx)
                            completion(Double(idxPx) ?? 0, error)
                        
                        }
                    }
                } else {
                    print("Failed to parse JSON data or data array not found.")
                }
            } catch {
                print("Failed to parse JSON data: \(error)")
                completion(0, error)
            }
        }.resume()
    }
    
    
    
    
    
    
    
    
}
