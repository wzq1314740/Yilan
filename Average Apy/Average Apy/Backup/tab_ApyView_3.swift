//
//  tab_ApyView.swift
//  Average Apy
//
//  Created by water on 4/15/24.
//

import SwiftUI
import Foundation

struct tab_ApyView_3: View {
    init() {
        self.updateTime = UserDefaults.standard.string(forKey: "updateTime") ?? "-"
        self.apiResponse = ""
        self.tokenString = UserDefaults.standard.string(forKey: "tokenSting") ?? tokenInitString

        // 加载数据
        let publicInstance = PublicPlist()
        if let loadedObjects: [String: EveryApy] = publicInstance.readCodableDic(fileName: "LocalCache.plist") {
            // 使用loadedObjects
            self.apyForm = loadedObjects
        } else {
            // 数据加载失败
            self.apyForm = [:]
        }
        
        
    }
    @State private var apyForm: [String: EveryApy]
    @State private var updateTime: String
    @State private var tokenString: String
    private let tokenInitString = "USDT,USDC,ETH,BTC,SUI,OKB"
    //USDT,USDC,ETH,BTC,SUI,OKB
    let unitString: [String] = ["Token", "N", "D", "W", "M", "S", "H", "Y"]

    
    class EveryApy: Codable {
        //Definition of interest rate list
        let token: String
        var rate: [Float] = []
    //    var date: [Int] = []
        var internet = 1
        var times: Int = 0
        var unit: [Int]
    
        init(token: String, unit:[Int]) {
            self.token = token
            self.unit = unit
        }
        
        var ratePer: [String] {
            var ratesPer: [String] = []
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 1
            formatter.minimumFractionDigits = 0
            var i = 0

            for _ in unit {
                if i < rate.count {
                    let number = NSNumber(value: rate[i])
                    ratesPer.append(formatter.string(from: number) ?? "-")
                } else {
                    // 处理索引超出 rate 数组范围的情况
                    ratesPer.append("-") // 直接添加默认值表示没有对应的值
                }
                i += 1
            }
            return ratesPer
        }
          
        
        func apy(token: String, unit: [Int], completion: @escaping ([Float]?) -> Void){
            //get data of Apy
            // Print a message to indicate the start of the pre-request script
            print("-----Execute the Pre-request Script of collections.-----")
            print("token: ",token,"; unit: ", unit)

            // Create a new Date object with the current time
            let endTimeDate = Date()
            // Get the current time in milliseconds（ the end time ）
            let endTimestamp = Int(endTimeDate.timeIntervalSince1970 * 1000)
            // Subtract 7 days from the current date
            let MaxUnit:Int = unit.max()!
            let startTimeDate = Calendar.current.date(byAdding: .day, value: -MaxUnit, to: endTimeDate)!
            // Get the time in milliseconds for the updated date
            let startTimestamp = Int(startTimeDate.timeIntervalSince1970 * 1000)
            // Print the start and end timestamps
            print("startTimestamp: \(startTimestamp) (\(startTimeDate) / endTimestamp: \(endTimestamp)) (\(endTimeDate))")

            let data:[ApyData] = []
            getApy(token: token,unit,data: data, startTimestamp: startTimestamp, endTimestamp: endTimestamp) { rate in
                if let rate: [Float] = rate {
                    completion(rate)
                }
            }

            
        }


        private func getApy(token: String = "USDT", _ unit: [Int] = [1], data:[ApyData], startTimestamp: Int, endTimestamp: Int, completion: @escaping ([Float]?) -> Void)  {
            times += 1
            print("这是接口第", times, "次调用")
            
            getApy_API(token,unit, data, startTimestamp, endTimestamp) { apyDataNew in
                if let apyDataNew = apyDataNew {
                    // Handle the received data
                    print("Received APY List:", apyDataNew)
                    var data = data
                    data.append(contentsOf: apyDataNew)
                    if let last = apyDataNew.last, let tsInt = last.tsInt, startTimestamp < tsInt - 3600000 {
                        
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                print("这段代码将在0.5秒后执行")
                                // 这里放你想要延迟执行的代码
                                self.getApy(token: token,unit, data: data, startTimestamp:startTimestamp , endTimestamp: Int(tsInt)){ rate in
                                    completion(rate)
                                }
                            }
                        } else{
                            print("Got the all apy data")
                            let rate = self.calculate(token: token,unit: unit,apyData: data)
                            //Update rate
                                self.rate = rate
                                self.internet = 3
                                print("token: ", token, "Internet: ", self.internet, " self: ", self)
                                completion(rate)
                        }
                } else {
                    // Handle the case when data retrieval fails
                    print("Failed to retrieve APY List")
                }
            }
        }



        private func getApy_API(_ token: String = "USDT", _ unit: [Int] = [1], _ apyData: [ApyData], _ startTimestamp: Int? = nil, _ endTimestamp: Int? = nil, completion: @escaping ([ApyData]?) -> Void) {
            // Define the URL for the OKX API endpoint

            var components = URLComponents(string: "https://www.okx.com/api/v5/finance/savings/lending-rate-history")
            components?.queryItems = [
                URLQueryItem(name: "ccy", value: token),
                URLQueryItem(name: "after", value: endTimestamp.flatMap { String($0) }  ),
                URLQueryItem(name: "before", value: startTimestamp.flatMap { String($0) }  )
            ]
            print("URLComponents: ", components?.url as Any)
              
            guard let url = components?.url else {
                print("Invalid URL")
                return
            }

            // Create a URL request with the defined URL
            var request = URLRequest(url: url)
            request.httpMethod = "GET" // Set the HTTP method to GET
            
            // Create a URLSession task to perform the request
            URLSession.shared.dataTask(with: request) { data, response, error in
                // Check for errors
                
                if let error = error {
                    print("URLRequest - Error: \(error)")
                    return
                }
                // Check if a response was received
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("URLRequest - Invalid response")
                    return
                }
                // Check if the status code indicates success (200 OK)
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("URLRequest - HTTP response status code: \(httpResponse.statusCode)")
                    return
                }
                // Check if data was received
                guard let data = data else {
                    print("URLRequest - No data received")
                    return
                }
                // Convert the data to a string (or perform JSON decoding if the response is JSON)
                if let responseString = String(data: data, encoding: .utf8) {
                    //print("API Response: \(responseString)")
                    // Update the UI on the main thread if needed
                    DispatchQueue.main.async {
                        //self.apiResponse = responseString
                    }
                }
                do {
                    // 使用JSONDecoder来解析JSON数据为Swift对象
                    let decoder = JSONDecoder()
                    let jsonResponse = try decoder.decode(Response.self, from: data)
                      
                    // 现在你可以访问jsonResponse中的属性来获取数据
        //            print("jsonResponse.code: ", jsonResponse.code)
        //            for item in jsonResponse.data {
        //                print("Individual Apy data: ",  item.amt,",",item.ccy,",",item.rate,"%,",item.ts,",",Date(timeIntervalSince1970: TimeInterval((Int64(item.ts) ?? 0)/1000)))
        //            }
                    let apyData: [ApyData] = jsonResponse.data
                    completion(apyData)
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            }.resume() // Start the task
        }

        private func calculate(token: String, unit: [Int] = [1], apyData: [ApyData]) -> [Float] {
            print("----Executed successfully: Calculate apy----")
            // Calculate average lending rate from combined data
            
            var timestamp: [Int] = []
            var unitOder = 0
            var total: Float = 0
            var averageRate: [Float] = []
            unit.forEach { unit in
                let startTimeDate = Calendar.current.date(byAdding: .day, value: -unit, to: Date())!
                // Get the time in milliseconds for the updated date
                let startTimestamp = Int(startTimeDate.timeIntervalSince1970 * 1000)
                timestamp.append(startTimestamp)
            }
            
            var totalRate: Float = 0
            apyData.forEach { hoursData in
                if let hourApy = hoursData.rateFloat{
                    totalRate += hourApy
                    total += 1
                    
                    if hoursData.tsInt ?? 0 < timestamp[unitOder] + 3600000{
                        // Log average rate
                        averageRate.append(totalRate / total)
                        print("total: ", total, " ,unit: ", unit[unitOder], " unitOrder: ", unitOder, " timestamp: ", timestamp[unitOder], "Average Lending Rate:", averageRate[unitOder], ", totalRate: ", totalRate)
                        unitOder += 1
                    }
                }
            }
            return averageRate
        }
        
        struct Response: Codable {
            let code: String
            let data: [ApyData]
            let msg: String
        }
          
        struct ApyData: Codable {
            var amt: String
            let ccy: String
            let rate: String
            let ts: String
            
            
            // 如果需要，您可以添加计算属性将字符串转换为Float
            var amtFloat: Float? {
                return Float(amt)
            }
              
            var rateFloat: Float? {
                return Float(rate)
            }
              
            var tsInt: Int64? {
                return Int64(ts)
            }
        }

    }


    private func initialization() {
        //initialize data of Apy
        if tokenString == "" {
            tokenString = tokenInitString
        }
        //USDT,USDC,ETH,BTC,SUI,OKB
        let unit:[Int] = [0,1,7,30,91,182,365]
        //0,1,7,30,91,182,365
        //let unitDic:[String: Int] = ["N": 0, "D": 1, "W": 7, "M": 30, "S": 91, "H": 182, "Y": 365]
        let token:[String] = tokenString.components(separatedBy: ",")
        var order = 0
        let date = Date()
        initializationApy() { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let formattedDate = formatter.string(from: date)
            updateTime = formattedDate
            UserDefaults.standard.set(tokenString, forKey: "tokenSting")
            UserDefaults.standard.set(updateTime, forKey: "updateTime")

            let publicInstance = PublicPlist()
            publicInstance.saveCodableDic(objects: apyForm,fileName: "LocalCache.plist")
        }
        
        
        func initializationApy(completion: @escaping (Int?) -> Void){

            print("这是开始计算第", order, "个币")
            initializationApy_token(){ _ in
                print("order: ",order, " token.count: ", token.count)
                order += 1
                if order < token.count {
                    print("order: ",order, " token.count: ", token.count)
                    initializationApy(){ _ in
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }

        }
        
        
        func initializationApy_token(completion: @escaping (Int?) -> Void){
            let EveryApy = EveryApy(token: token[order],unit: unit)
            EveryApy.apy(token: token[order], unit: unit){ rate in
                if let returnRate = rate  {
                    EveryApy.rate = returnRate
                    apyForm[token[order]] = EveryApy
                    completion(nil)
                }
            }

        }
    }

    
    @State private var apiResponse: String = ""
    
    
    var body: some View {
        VStack(spacing: 0) { // Added spacing between views
            HStack(alignment: .center, spacing: -1) {
                TextField("Token", text: $tokenString)
                    .frame(width: 260, height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1) // 设置边框为灰色，线宽为1
                        .padding(.all, -5)
                )
                    .padding(10)
                Button(action: {
                    initialization()
                    
                }){
                    Text("Update")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(5)
            }
            .padding(.vertical, 15)

            HStack(spacing: -1) {
                ForEach(0..<unitString.count, id: \.self) { index in
                    Text("\(unitString[index])") // Convert Int to String for display
                        .frame(width: 50.0, height: 40)
                        .border(Color.black, width: 1)
                        .padding(0.0)
                }
            }

            ForEach(Array(apyForm.keys), id: \.self) { token in
                if let apy = apyForm[token] {
                    HStack(spacing: -1) {
                        Text(token)
                            .frame(width: 50.0, height: 40)
                            .border(Color.black, width: 1)
                            .padding(0.0)
                        ForEach(0..<unitString.count-1, id: \.self) { index in
                            Text("\(apy.ratePer[index])") // Convert Int to String for display
                                .frame(width: 50.0, height: 40)
                                .border(Color.black, width: 1)
                                .padding(0.0)
                        }
                    }
                }
            }
            Text("Last update time: \(updateTime)")
                .padding(15)

            
            Button(action: {
                    print("apyForm[\"USDT\"]!.internet: ", apyForm["USDT"]!.rate)

            }) {
                Text("Check")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(15)
            
            Text(apiResponse)
                .padding()
            Spacer()
            
        }
    }
    
        


}





#Preview {
    tab_ApyView_3()
}
