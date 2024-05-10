//
//add item
// ChatGPT
//
//
import SwiftUI
import SwiftData
import CoreData

struct tab_Testview: View {
    @Environment(\.managedObjectContext) private var viewContext
    

    
    @FetchRequest(
        entity: ApyDataEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ApyDataEntity.ts, ascending: true)]
    ) var items: FetchedResults<ApyDataEntity>
    
    
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
        func getApy()  {
            
            getApy_API() { _ in
                let data1 = ApyData(amt: "111111.9767349", ccy: "USDT", rate: "0.01", ts:"10000011111")
                let data2 = ApyData(amt: "222222.9767349", ccy: "USDT", rate: "0.01", ts:"10000022222")
                let data3 = ApyData(amt: "333333.9767349", ccy: "USDT", rate: "0.01", ts:"10000033333")
                let data4 = ApyData(amt: "4444.9767349", ccy: "USDT", rate: "0.01", ts:"10000044444")
                
                var datas:[ApyData] = []
                var datas1:[ApyData] = []
                
                datas.append(data1)
                datas.append(data2)
                datas1.append(data3)
                datas1.append(data4)
                datas.append(contentsOf: datas1)

                let persistenceController = PersistenceController.shared
                let context = persistenceController.container.viewContext
                
                
                // 假设你已经有了一个托管对象上下文
                for data in datas {
                    let entity = ApyDataEntity(context: context)
                    entity.amt = data.amt
                    entity.ccy = data.ccy
                    entity.rate = data.rate
                    entity.ts = data.ts
                }
                  
                do {
                    try context.save()
                    print("Save successfully")
                } catch let error as NSError {
                    // Handle the error.
                    print("Fail Saving: ", error, " error info: ", error.userInfo)
                }
            }
        }
        private func getApy_API(completion: @escaping ([ApyData]?) -> Void) {
                    completion(nil)
        }

        
        
          
        struct ApyData: Codable {
            var amt: String
            var ccy: String
            var rate: String
            var ts: String
            
            
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

    }


    
    @State private var apiResponse: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                let EveryApy = EveryApy(token: "USDT",unit: [1])
                EveryApy.getApy()
                
            }){
                Text("Saving")
            }
            Button(action: {
             //   self.loadItems()
                
            }){
                Text("Read")
            }
            
//            List(items, id: \.self) { item in
//                HStack(){
//                    Text(item.ccy ?? "-") // 修改为你的实体属性
//                    Text(item.rate ?? "-") // 修改为你的实体属性
//                    Text(item.amt ?? "-") // 修改为你的实体属性
//                    Text(item.ts ?? "-") // 修改为你的实体属性
//                }
//            }
            .onAppear {
              //  self.loadItems()
            }
        }
    }

}



#Preview {
    tab_Testview()
}

