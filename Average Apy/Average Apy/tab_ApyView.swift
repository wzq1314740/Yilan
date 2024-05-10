//
//  tab_ApyView.swift
//  Average Apy
//
//  Created by water on 4/1/24.
//

import SwiftUI
import Foundation
import CoreData

struct tab_ApyView: View {
    @Environment(\.managedObjectContext) private var viewContext
     
    init() {
        self.updateTime = UserDefaults.standard.string(forKey: "updateTime") ?? "-"
        self.tokenString = UserDefaults.standard.string(forKey: "tokenSting") ?? tokenInitString
        
        // 加载数据
        let publicInstance = PublicPlist()
        if let loadedObjects: [EveryApy] = publicInstance.readCodable(fileName: "LocalCache.plist") {
            // 使用loadedObjects
            print("Load Apy cache")
            self.apyForm = loadedObjects
        } else {
            // 数据加载失败
            print("Load Apy cache failure")
            self.apyForm = []
        }
    }
    
    @State private var apyForm: [EveryApy]
    @State private var updateTime: String
    @State private var tokenString: String = ""
    @State private var loadState: Bool = false
    //For loading button
    @State private var progress_token: String = ""
    @State private var progress_request: String = ""
    @State private var requestTimes: Int = 0
    //display the progress of loading
    @State private var apiResponse: String = ""
    @State private var showConfirmation = false
    @State private var alertType = 0
    @State private var timestamp: [Int] = []
    @State private var startTimestamp: Int = 0
    @State private var endTimestamp: Int = 0
    
    
    private let tokenInitString = "USDT,USDC,ETH,BTC,SUI,OKB,MERL,BNB"
    //USDT,USDC,ETH,BTC,SUI,OKB  USDT,USDC,ETH,BTC,SUI,OKB,MERL,LDO,MAGIC,GMX,UNI,FLM,ZEM,ZRX,MKR,SNX,ANT
    let unitString: [String] = ["Token", "N", "L", "D", "W", "M", "S", "H", "Y"]
    
    
    class EveryApy: Codable {
        //Definition of interest rate list
        let token: String
        var rate: [Float] = []
        var nextRate: Float = 0
        //    var date: [Int] = []
        var internet = 1
        var requestTimes: Int = 0
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
            
            let number = NSNumber(value: nextRate)
            ratesPer.append(formatter.string(from: number) ?? "-")
            
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
        
    }
    
    
    func startGetApy(token: String, unit: [Int], completion: @escaping ([Float]?) -> Void){
        //get data of Apy
        // Print a message to indicate the start of the pre-request script
        print("-----Execute the Pre-request Script of collections.-----")
        print("token: ",token,"; unit: ", unit)
        var cacheStartTimestamp:Int = startTimestamp

        
        let dataCache:[ApyData] = loadCache(token: token, startTimestamp: String(startTimestamp))
        let datas:[ApyData] = []
        requestTimes = 0
        
        if dataCache.count > 0 {
            if let timestamp = dataCache[0].tsInt  {
                //limit the range of the request of Apy data
                if startTimestamp < timestamp {
                    cacheStartTimestamp = timestamp
                    print("有缓存数据timestamp: \(timestamp)")
                }
            }
        } else {
            print("无缓存数据timestamp")
        }
        
        getApy(token: token,unit: unit,data: datas, dataCache: dataCache, startTimestamp: cacheStartTimestamp, endTimestamp: endTimestamp) { rate in
            progress_request = ""
            if let rate: [Float] = rate {
                completion(rate)
            }

        }
    }
    
    func loadCache(token: String, startTimestamp: String) -> [ApyData]  {
        //read apyData for cache (core data)
        let privateContext = PersistenceController.shared.newPrivateContext()
        //read Cache Apy
        var items: [ApyDataEntity] = []
        let fetchRequest: NSFetchRequest<ApyDataEntity> = ApyDataEntity.fetchRequest()
        
        // 设置筛选条件
        let predicate1 = NSPredicate(format: "ccy == %@", token)
        let predicate2 = NSPredicate(format: "ts >= %@", startTimestamp)
        // 使用 AND 组合两个条件
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
        fetchRequest.predicate = compoundPredicate
        
        // 设置排序规则
        let sortDescriptor = NSSortDescriptor(key: "ts", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            items = try privateContext.fetch(fetchRequest)
            print("加载", token, "缓存数据", items.count, "条记录")
        } catch {
            print("无法加载数据")
        }
        
        
        var datasCache:[ApyData] = []
        for item in items{
//            print("Core data result: ", "amt: ", item.amt ?? "-", "ccy: ", item.ccy ?? "-", "rate: ", item.rate ?? "-", "ts: ", item.ts ?? "-", "ID: ", item.id ?? "-")
            let data = ApyData(amt: item.amt!, ccy: item.ccy!, rate: item.rate!, ts: item.ts!)
            datasCache.append(data)
        }
        return datasCache
    }
    
    private func getApy(token: String = "USDT", unit: [Int] = [1], data:[ApyData], dataCache:[ApyData], startTimestamp: Int, endTimestamp: Int, completion: @escaping ([Float]?) -> Void)  {
        requestTimes += 1
        print("这是接口第", requestTimes, "次调用")
        //progress_request = "这是接口第\(requestTimes)/88次调用"
        progress_request = "获取APY数据-->进度：\(requestTimes)/88次"
        
        //let startTimestamp = data[0].tsInt
        
        getApy_API(token,unit, data, startTimestamp, endTimestamp) { apyDataNew in
            var rate: [Float] = []
            if let apyDataNew = apyDataNew {
                // Handle the received data
                print("Received APY List:", apyDataNew)
                var data = data
                data.append(contentsOf: apyDataNew)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let last = apyDataNew.last, let tsInt = last.tsInt, startTimestamp < tsInt - 3600000 {

                            print("这段代码将在0.3秒后执行")
                            // 这里放你想要延迟执行的代码
                        self.getApy(token: token,unit: unit, data: data, dataCache:dataCache, startTimestamp:startTimestamp , endTimestamp: Int(tsInt)){ rate in
                                completion(rate)
                            }
                        
                    } else{
                        print("Got the ", token, " apy data")
                        
                        //save apyData for cache
                        let persistenceController = PersistenceController.shared
                        let context = persistenceController.container.viewContext
                        
                        //                            //save apyData for cache
                        //                            let privateContext = PersistenceController.shared.newPrivateContext()
                        //                            privateContext.perform {}
                        
                        // 假设你已经有了一个托管对象上下文
                        for data in data {
                            let entity = ApyDataEntity(context: context)
                            entity.amt = data.amt
                            entity.ccy = data.ccy
                            entity.rate = data.rate
                            entity.ts = data.ts
                            entity.create_time = Date()
                        }
                        //Save to core data
                        DispatchQueue.main.async {
                            do {
                                print("Try to save core data: ", token)
                                try context.save()
                                print("Saved successfully: ", token)
                            } catch let error as NSError {
                                // Handle the error.
                                print("Fail Saving: ", error, " error info: ", error.userInfo)
                            }
                        }
                        
                        data.append(contentsOf: dataCache)
                        rate = self.calculate(token: token,unit: unit,apyData: data)
                        completion(rate)
                    }
                }
            } else {
                // Handle the case when data retrieval fails
                print("Failed to retrieve APY List")
                completion(rate)
            }
        }
    }
    
    
    
    private func getApy_API(_ token: String = "USDT", _ unit: [Int] = [1], _ apyData: [ApyData], _ startTimestamp: Int? = nil, _ endTimestamp: Int? = nil, completion: @escaping ([ApyData]?) -> Void) {
        
        struct Response: Codable {
            let code: String
            let data: [ApyData]
            let msg: String
        }
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
                completion(nil)
            }
            // Check if a response was received
            guard let httpResponse = response as? HTTPURLResponse else {
                print("URLRequest - Invalid response")
                completion(nil)
                return
            }
            // Check if the status code indicates success (200 OK)
            guard (200...299).contains(httpResponse.statusCode) else {
                print("URLRequest - HTTP response status code: \(httpResponse.statusCode)")
                completion(nil)
                return
            }
            // Check if data was received
            guard let data = data else {
                print("URLRequest - No data received")
                completion(nil)
                return
            }
            // Convert the data to a string (or perform JSON decoding if the response is JSON)
            if let responseString = String(data: data, encoding: .utf8) {
                //if let responseString = String(data: data, encoding: .utf8) {
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
        

        var unitOder = 0
        var total: Float = 0
        var averageRate: [Float] = []

        
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
    

    
    struct ApyData: Codable {
        let amt: String
        let ccy: String
        let rate: String
        let ts: String
        
        // 自定义初始化器
        init(amt: String, ccy: String, rate: String, ts: String) {
            self.amt = amt
            self.ccy = ccy
            self.rate = rate
            self.ts = ts
        }
        
        
        // 如果需要，您可以添加计算属性将字符串转换为Float
        var amtFloat: Float? {
            return Float(amt)
        }
        
        var rateFloat: Float? {
            return Float(rate)
        }
        
        var tsInt: Int? {
            return Int(ts)
        }
    }
    
    
    private func getNextApy_API(completion: @escaping ([NextHourData]?) -> Void) {
        
        struct nextHourResponse: Codable {
            let code: String
            let data: [NextHourData]
            let msg: String
        }
        // Define the URL for the OKX API endpoint
        
        let components = URLComponents(string: "https://www.okx.com/api/v5/finance/savings/lending-rate-summary")
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
                completion(nil)
            }
            // Check if a response was received
            guard let httpResponse = response as? HTTPURLResponse else {
                print("URLRequest - Invalid response")
                completion(nil)
                return
            }
            // Check if the status code indicates success (200 OK)
            guard (200...299).contains(httpResponse.statusCode) else {
                print("URLRequest - HTTP response status code: \(httpResponse.statusCode)")
                completion(nil)
                return
            }
            // Check if data was received
            guard let data = data else {
                print("URLRequest - No data received")
                completion(nil)
                return
            }
            // Convert the data to a string (or perform JSON decoding if the response is JSON)
            if let responseString = String(data: data, encoding: .utf8) {
                //if let responseString = String(data: data, encoding: .utf8) {
                //print("API Response: \(responseString)")
                // Update the UI on the main thread if needed
                DispatchQueue.main.async {
                    //self.apiResponse = responseString
                }
            }
            do {
                // 使用JSONDecoder来解析JSON数据为Swift对象
                let decoder = JSONDecoder()
                let jsonResponse = try decoder.decode(nextHourResponse.self, from: data)
                
                // 现在你可以访问jsonResponse中的属性来获取数据
                //            print("jsonResponse.code: ", jsonResponse.code)
                //            for item in jsonResponse.data {
                //                print("Individual Apy data: ",  item.amt,",",item.ccy,",",item.rate,"%,",item.ts,",",Date(timeIntervalSince1970: TimeInterval((Int64(item.ts) ?? 0)/1000)))
                //            }
                let nextHourData: [NextHourData] = jsonResponse.data
                completion(nextHourData)
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume() // Start the task
    }

    

    
    struct NextHourData: Codable {
        let avgAmt: String
        let avgAmtUsd: String
        let avgRate: String
        let ccy: String
        let estRate: String
        let preRate: String
        
        // 自定义初始化器

        // 如果需要，您可以添加计算属性将字符串转换为Float
        var estRateFloat: Float? {
            return Float(estRate)
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
        var nextHour: [String: NextHourData] = [:]
        
        apyForm = []
        updateTime = "-"
        timestamp = []
        
        unit.forEach { unit in
            let startTimeDate = Calendar.current.date(byAdding: .day, value: -unit, to: Date())!
            // Get the time in milliseconds for the updated date
            let startTimestamp = Int(startTimeDate.timeIntervalSince1970 * 1000)
            timestamp.append(startTimestamp)
        }
        
        // Create a new Date object with the current time
        let endTimeDate = Date()
        // Get the current time in milliseconds（ the end time ）
        endTimestamp = Int(endTimeDate.timeIntervalSince1970 * 1000)
        // Subtract 7 days from the current date
        //let MaxUnit:Int = unit.max()!
        let startTimeDate = Calendar.current.date(byAdding: .day, value: -365, to: endTimeDate)!
        // Get the time in milliseconds for the updated date
        startTimestamp = Int(startTimeDate.timeIntervalSince1970 * 1000)
        // Print the start and end timestamps
        print("startTimestamp: \(startTimestamp) (\(startTimeDate)) / endTimestamp: \(endTimestamp)) (\(endTimeDate))")
        
        //获取下一小时利率
        getNextApy_API() { nextHourData in
            if let nextHourData = nextHourData {
                // 使用 Dictionary 初始化器转换
                nextHour = Dictionary(uniqueKeysWithValues: nextHourData.map { ($0.ccy, $0) })
                print("已获取下一小时利率")
            }
        }


        initializationApy() { _ in
            print("完成")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let formattedDate = formatter.string(from: date)
            updateTime = formattedDate
            UserDefaults.standard.set(tokenString, forKey: "tokenSting")
            UserDefaults.standard.set(updateTime, forKey: "updateTime")
            
            let publicInstance = PublicPlist()
            publicInstance.saveCodable(objects: apyForm,fileName: "LocalCache.plist")
            
            loadState = false
        }
        
        
        func initializationApy(completion: @escaping (Int?) -> Void){
            initializationApy_token(){ _ in
                print("计算第", order+1, "/", token.count, "个币完成: ", token[order])
                progress_token = "计算第\(order+1)/\(token.count)个币完成"
                order += 1
                if order < token.count && order < 10 {
                    //print("order: ",order, " token.count: ", token.count)
                    initializationApy(){ _ in
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
            
        }
        
        
        func initializationApy_token(completion: @escaping (Int?) -> Void){
            let everyApy = EveryApy(token: token[order],unit: unit)
            
            print("开始计算第", order+1, "/", token.count, "个币: ", token[order])
            progress_token = "计算第\(order+1)/\(token.count)个币: \(token[order])"
            
            startGetApy(token: token[order], unit: unit){ rate in
                if let returnRate = rate  {
                    everyApy.rate = returnRate
                    everyApy.nextRate = nextHour[token[order]]?.estRateFloat ?? 0
                    apyForm.append(everyApy)
                }
                completion(nil)
            }
            
        }
    }
    

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(alignment: .center) {
                        TextField("请输入币种名称，用逗号隔开", text: $tokenString)
                            .padding(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5)) // 设置内边距
                            .frame(width: 220, height: 55)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1) // 设置边框为灰色，线宽为1
                            )
                        Spacer()
                        Button(action: {
                            loadState = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                initialization()
                            }
                            
                        }) {
                            Text("Update")
                                .padding(14)
                                .background(loadState ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(loadState)
                        .padding(0) // 设置按钮右侧的内边距
                    }
                }
                
                Section{

                    
                    ScrollView(.horizontal, showsIndicators: true) {
                        VStack(spacing: -1) {
                            HStack(spacing: -1) {
                                ForEach(0..<unitString.count, id: \.self) { index in
                                    Text("\(unitString[index])") // Convert Int to String for display
                                        .frame(width: 45, height: 40)
                                        .border(Color.black, width: 1)
                                        .padding(0.0)
                                        .font(/*@START_MENU_TOKEN@*/.subheadline/*@END_MENU_TOKEN@*/)
                                }
                            }
                            
                            ForEach(0..<apyForm.count, id: \.self) { token_index in
                                HStack(spacing: -1) {
                                    Text(apyForm[token_index].token)
                                        .frame(width: 45, height: 40)
                                        .border(Color.black, width: 1)
                                        .padding(0.0)
                                        .font(/*@START_MENU_TOKEN@*/.subheadline/*@END_MENU_TOKEN@*/)
                                    ForEach(0..<unitString.count-1, id: \.self) { index in
                                        Text("\(apyForm[token_index].ratePer[index])") // Convert Int to String for display
                                            .frame(width: 45.0, height: 40)
                                            .border(Color.black, width: 1)
                                            .padding(0.0)
                                            .font(/*@START_MENU_TOKEN@*/.subheadline/*@END_MENU_TOKEN@*/)
                                    }
                                }
                            }
                        }
                        .padding(.top, 5.0)
                        
                    }
                    
                    Section{
                        Text("Last update time: \(updateTime)")
                            .foregroundColor(Color.secondary)
                        
                        Text(progress_token)
                            .foregroundColor(Color.gray)
                            .padding(.bottom, 0.0)
                        Text(progress_request)
                            .foregroundColor(Color.gray)
                            .padding(.top, 0.0)
                    }
                    
                    
                }
                
                
                
                Button(action: {
                    alertType = 0
                    showConfirmation.toggle()
                }) {
                    Text("Clear Cache")
                        .cornerRadius(8)
                }
                
            }
            .alert(isPresented: $showConfirmation) {
                // 定义确认框的内容
                if alertType == 0 {
                    return Alert(
                        title: Text("删除历史利率数据"),
                        message: Text("确定删除缓存吗？"),
                        primaryButton: .default(Text("确认删除")) {
                            // 在确认后执行的操作
                            let publicInstance = PublicPlist()
                            if publicInstance.clearPlistData(fileName: "LocalCache.plist") {
                                // 数据删除成功，更新状态
                                print("Deleted apy data successfully.")
                            } else {
                                // 数据删除失败
                                print("Failed to clear the data.")
                            }
                            // 创建 fetch 请求
                            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ApyDataEntity")
                            // 执行 fetch 请求
                            do {
                                // 获取所有实例
                                let results = try viewContext.fetch(fetchRequest)
                                // 遍历结果并删除每个实例
                                for obj in results {
                                    viewContext.delete(obj as! NSManagedObject)
                                }
                                // 保存上下文
                                try viewContext.save()
                                print("Deleted Core data successfully.")
                            } catch let error as NSError {
                                print("Error fetching \("ApyDataEntity"): \(error), \(error.userInfo)")
                            }
                            alertType = 1
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showConfirmation = true
                            }
                        },
                        secondaryButton: .cancel()
                    )
                } else {
                    return Alert(
                        title: Text("Success"),
                        message: Text("Data has been deleted successfully."),
                        dismissButton: .default(Text("OK")))
                }
                
            }
            .navigationBarTitle("OKX 历史杠杆利率")
            
        }
    }
}





#Preview {
    tab_ApyView()
}
