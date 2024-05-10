//
//  tab_ApyView.swift
//  Average Apy
//
//  Created by water on 4/1/24.
//

import SwiftUI

struct tab_ApyView_ori: View {

    
    let data = [
        ["", "Now", "1D", "1W", "1M", "1Y"],
        ["USDT", "0.11", "0.88", "24.0%", "", ""],
        ["USDC", "", "", "", "", ""],
        ["ETH", "", "", "", "", ""],
        ["BTC", "", "", "", "", ""],
        ["SUI", "", "", "", "", ""],
        ["OKB", "", "", "", "", ""],
        ["", "", "", "", "", ""]
        
    ]
    
    @State private var apiResponse: String = ""
    
    
    var body: some View {
        VStack(spacing: -1.0) { // Added spacing between views
            ForEach(Array(0..<data.count), id: \.self) { row in
                HStack(spacing: -1) {
                    ForEach(Array(0..<self.data[row].count), id: \.self) { column in
                        Text(self.data[row][column])
                            .frame(width: 60.0, height: 40)
                            .border(Color.black, width: 1)
                            .padding(0.0)
                    }
                }
            }
            
            Button(action: {
                self.requestAPI()
            }) {
                Text("Refresh")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(20)
            
            Text(apiResponse)
                .padding()
            
        }
        .padding()
    }
    
    
    private func requestAPI() {
        // Make API request here
        // For simplicity, let's just print a sample response
        apiResponse = "API Response: Sample Data"
        
        
        
        // Print a message to indicate the start of the pre-request script
        print("-----Execute the Pre-request Script of collections.-----")

        // Get the current time in milliseconds
        let currentTime = Date().timeIntervalSince1970 * 1000

        // Create a new Date object with the current time
        let date = Date(timeIntervalSince1970: currentTime / 1000)

        // Subtract 7 days from the current date
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: date)!

        // Get the time in milliseconds for the updated date
        let startTimestamp = sevenDaysAgo.timeIntervalSince1970 * 1000

        // Calculate the end time (current time)
        let endTimestamp = currentTime

        // Set environment variables for start and end timestamps
        UserDefaults.standard.set(startTimestamp, forKey: "startTimestamp")
        UserDefaults.standard.set(endTimestamp, forKey: "endTimestamp")

        // Synchronize user defaults
        UserDefaults.standard.synchronize()

        // Print the start and end timestamps
        print("startTimestamp: \(startTimestamp) (\(Date(timeIntervalSince1970: startTimestamp / 1000))) / endTimestamp: \(endTimestamp) (\(Date(timeIntervalSince1970: endTimestamp / 1000)))")
        
        var apydata:[ApyList] = []
        
        get_ApyAPI { apyList in
            if let apyList = apyList {
                // Handle the received data
                print("Received APY List:", apyList)
                apydata = apyList
            } else {
                // Handle the case when data retrieval fails
                print("Failed to retrieve APY List")
            }

        }
        
        print("这个才是我" , apydata)
        print(apydata[0])
        
        
        
    }
    
    
    private func get_ApyAPI(_ token: String = "USDT", _ startTimestamp: String? = nil, _ endTimestamp: String? = nil, completion: @escaping ([ApyList]?) -> Void) {
        // Define the URL for the OKX API endpoint

        var components = URLComponents(string: "https://www.okx.com/api/v5/finance/savings/lending-rate-history")
        components?.queryItems = [
            URLQueryItem(name: "ccy", value: token),
            URLQueryItem(name: "after", value: startTimestamp),
            URLQueryItem(name: "before", value: endTimestamp)
        ]
          
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
                print("Error: \(error)")
                return
            }
            
            // Check if a response was received
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            // Check if the status code indicates success (200 OK)
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP response status code: \(httpResponse.statusCode)")
                return
            }
            
            // Check if data was received
            guard let data = data else {
                print("No data received")
                return
            }
            
            // Convert the data to a string (or perform JSON decoding if the response is JSON)
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
                // Update the UI on the main thread if needed
                DispatchQueue.main.async {
                    self.apiResponse = responseString
                }
            }
            
            
            do {
                // 使用JSONDecoder来解析JSON数据为Swift对象
                let decoder = JSONDecoder()
                let jsonResponse = try decoder.decode(ResponseData.self, from: data)
                  
                // 现在你可以访问jsonResponse中的属性来获取数据
                print(jsonResponse.code)
                for item in jsonResponse.data {
                    print(item.amt)
                    print(item.ccy)
                    print(item.rate)
                    print(item.ts)
                }
                
                let apyList: [ApyList] = jsonResponse.data
               
                completion(apyList)
                
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
            
            
            
        }.resume() // Start the task
        
        
        
    }

}




struct ResponseData: Codable {
    let code: String
    let data: [ApyList]
    let msg: String
}
  
struct ApyList: Codable {
    let amt: String
    let ccy: String
    let rate: String
    let ts: String
}



private func calculate(){
    print("----Executed successfully: 2nd request----")

    // Assuming response data from both requests are stored in variables
    let data2: [[String: Any]] = [
        ["rate": 5.5],
        ["rate": 6.2],
        ["rate": 4.8]
    ]

    let data1: [[String: Any]] = [
        ["rate": 7.3],
        ["rate": 6.9],
        ["rate": 8.1]
    ]

    // Print breakpoint message
    print("-----Breakpoint-----")

    // Combine data from both requests
    var combinedData = data2
    combinedData.append(contentsOf: data1)
    print(combinedData)

    // Calculate average lending rate from combined data
    var totalRate: Double = 0
    combinedData.forEach { entry in
        if let rateString = entry["rate"] as? String,
           let rate = Double(rateString) {
            totalRate += rate
        }
    }

    let averageRate = totalRate / Double(combinedData.count)

    // Log average rate
    print("Average Lending Rate:", averageRate)
    
    
    
    
    
}



#Preview {
    tab_ApyView_ori()
}
