//
//add item
// ChatGPT
//
//
import SwiftUI
import SwiftData
import CoreData
import CryptoKit
import CommonCrypto

struct tab_Testview1: View {
    @State var errorMessage: String = ""
    @State var errorCode: String = ""
    
    let apiKey: String = "RfWa6jaHISGCDZnZmBDXddVCXdUQH5n3y2YFGXVeN0RKthgV5jOCP4wsltJBhPz1"
    let secretKey: String = "gTmFb8jMvkyoFwTrIcR8t5XLOwJwS4JVfTwSqTZup8OertZ6JyKxRjNjVkyCSKkn"
    let baseURL = "https://api.binance.com"
    let binanceAPIURL = "https://api.binance.com"
    
    func fetchAccountValuation(completion: @escaping (String?, [AccountType: String]?, Error?) -> Void) {
        let endpoint = "/sapi/v1/asset/wallet/balance"
        //var request = packageRequest(endpoint: endpoint)
        
        
        // Binance API 端点
        let url = URL(string: baseURL + endpoint)!
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        
        // 准备请求参数
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        var parameters: [String: String] = [
            "timestamp": String(timestamp)
        ]

        // 将参数转换为查询项
        let queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        components.queryItems = queryItems
        let queryString = components.query ?? ""

        
        //进行签名
        let signature = hmacSha256(data: queryString)
        print("signature1: ", signature)
        
        
        
        //将签名添加到查询项
        parameters["signature"] = signature
        print("parameters: ", parameters)
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        print("components: ", components)
        
        //创建请求，然后把查询项添加到请求
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        print("components.url: ", components.url!)
        print("request: ", request)
        
        // 添加 API Key ，内容类型到请求头
        request.addValue(apiKey, forHTTPHeaderField: "X-MBX-APIKEY")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        print("request :", request)
        

        // 发送请求
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("data: ", String(data: data!, encoding: .utf8)!)
            
            // 检查错误
            if let error = error {
                print("请求失败: \(error.localizedDescription)")
                return
            }
            
            // 检查响应状态码
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("请求失败，状态码: \(httpResponse.statusCode)")
                errorCode = String(httpResponse.statusCode)
                return
            }
            
            // 解析返回的JSON数据
            if let data = data, let jsonResult = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // 打印返回的JSON结果
                print("jsonResult: ",jsonResult)
            }
        }.resume()
        
        
        
    }
    

    private func hmacSha256(data: String) -> String {
        let key = SymmetricKey(data: secretKey.data(using: .utf8)!)
        let hmac = HMAC<SHA256>.authenticationCode(for: data.data(using: .utf8)!, using: key)
        let hmacdata = Data(hmac).base64EncodedString()
        print("H2-Data: ", hmac)
        print("H2-hmacdata: ", hmacdata)
        let hashedCode: HashedAuthenticationCode<SHA256> = hmac
            let hexString = hashedCode.compactMap { String(format: "%02x", $0) }.joined()
        print("hashedCode: ", hashedCode)
        print("hexString: ", hexString)
        return hexString
    }
    
    
    
    
    

    
    @State private var apiResponse: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                fetchAccountValuation() {totalAsset, accountAsset, error in
                    if let error = error {
                        print("Error fetching assets: \(error)")
                    }
                    
                }
                
            })
            {
                Text("Text")
            }
            Text(errorCode)
            Text(errorMessage)
        }
    }
        
    

}



#Preview {
    tab_Testview1()
}

