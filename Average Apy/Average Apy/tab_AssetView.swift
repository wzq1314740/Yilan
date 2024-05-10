//
//  tab_AssetView.swift
//  Average Apy
//
//  Created by ChatGPT on 4/26/24.
//


import SwiftUI
import Security

// 账户类型枚举
enum AccountType: String, CaseIterable, Codable {
    case funding = "资金账户"
    case loan = "借贷账户"
    case trading = "交易账户"
    case finance = "金融账户"
    case spot = "现货账户"
    case crossMargin = "全仓杠杆"
    case isolatedMargin = "逐仓杠杆"
    case USDFutures = "U本位合约"
    case coinFutures = "币本位合约"
    case options = "期权账户"
    case tradingBots = "交易机器人"
    
}

// 账户类型枚举，区分交易所账号和钱包
enum AccountCategory: String, Codable {
    case exchange
    case wallet
}

// 交易所名称
enum Exchange: String, Codable, CaseIterable {
    case OKX
    case Binance
    case Bybit
    case Kucoin
    case Huobi
    case Gateio
    // 确保枚举遵循 Encodable
}


// 账户资产模型
struct Account: Identifiable, Codable {
    var id: String
    var category: AccountCategory
    var exchange: Exchange
    
    var totalAsset: Double
    var assets: [CurrencyAsset]
    var accountAsset: [AccountType: String] = [:]
    var accountCurrency: [AccountType: [CurrencyAsset]] = [:]
    
    init(id: String, category: AccountCategory, exchange: Exchange? = nil, apiKey: String? = nil, secretKey: String? = nil, passphrase: String? = nil, mnemonic: String? = nil, mnemonicOrder: String? = nil) throws {
        self.id = id
        self.category = category
        self.exchange = exchange ?? .OKX
        self.totalAsset = 0
        self.assets = []
        
        
        // 使用 Keychain 保存账号信息
        let accountToken = AccountToken(account: self, apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, mnemonic: mnemonic, mnemonicOrder: mnemonicOrder)
        print("try to Save to Keychain")
        //Save to Keychain
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(accountToken) {
            let status = KeychainHelper.save(account: accountToken.id, data: encoded)
            if status == errSecSuccess {
                print("Account Token saved successfully.")
            } else if status == errSecDuplicateItem {
                print("账号名称重复，请使用其他名称。 \(status)")
                throw MyError.textError(message: "账号名称重复，请使用其他名称。 \(status)")
            } else {
                print("An error occurred: \(status)")
                throw MyError.textError(message: "An error occurred: \(status)")
            }
        }
        
    }
    
    
    
    init(id: String, category: AccountCategory, exchange: Exchange? = nil, totalAsset: Double, assets: [CurrencyAsset]) throws {
        self.id = id
        self.category = category
        self.exchange = exchange ?? .OKX
        self.totalAsset = totalAsset
        self.assets = assets
    }
    
    
//    // 使用 Keychain 保存账号信息(未使用）
//    func saveInfo () throws -> (String) {
//        print("try to Save to Keychain")
//        //Save to Keychain
//        let encoder = JSONEncoder()
//        if let encoded = try? encoder.encode(self) {
//            let status = KeychainHelper.save(account: id, data: encoded)
//            if status == errSecSuccess {
//                print("Account saved successfully.")
//                return("Account saved successfully.")
//            } else if status == errSecDuplicateItem {
//                print("账号名称重复，请使用其他名称。 \(status)")
//                throw(MyError.textError(message: "账号名称重复，请使用其他名称。 \(status)"))
//            } else {
//                print("An error occurred: \(status)")
//                throw(MyError.textError(message: "An error occurred: \(status)"))
//            }
//        }
//        throw(MyError.textError(message: "An unknow error occurred"))
//    }
    

    // 使用 Keychain 保存账号信息
    mutating func updateInfo (newAccountID: String) throws -> (String) {
        print("try to Save to Keychain")
        //Save to Keychain
        let status = KeychainHelper.update(originalID: id, newAccountID: newAccountID)
            if status == errSecSuccess {
                print("Account ID saved successfully: ", status, status.description)
                id = newAccountID
                return("Account ID saved successfully.")
            } else if status == errSecItemNotFound {
                print("账号不存在: \(status)")
                throw(MyError.textError(message: "账号不存在. \(status)"))
            } else if status == errSecDuplicateItem {
                print("账号名称重复，请使用其他名称。 \(status)")
                throw(MyError.textError(message: "账号名称重复，请使用其他名称。 \(status)"))
            } else {
                print("An error occurred: \(status)")
                throw(MyError.textError(message: "An error occurred: \(status)"))
            }
    }
    
    
    // 使用 Keychain 删除账号信息
    func deleteInfo () throws -> (String) {
        print("try to deleteto Keychain")
        //Save to Keychain
        let status = KeychainHelper.delete(accountID: id)
            if status == errSecSuccess {
                print("Account delete successfully.")
                return("Account delete successfully.")
            } else if status == errSecItemNotFound {
                print("账号不存在: \(status)")
                return("账号不存在. \(status)")
            } else {
                print("An error occurred: \(status)")
                throw(MyError.textError(message: "An error occurred: \(status)"))
            }
            throw(MyError.textError(message: "An unknow error occurred"))
    }
    

}



// 账户凭证信息单独保存（For safe）
struct AccountToken: Identifiable, Codable {
    var id: String
    var category: AccountCategory
    var exchange: Exchange
    private var apiKey: String = ""
    private var secretKey: String = ""
    private var passphrase: String = ""
    private var mnemonic: String = ""
    private var mnemonicOrder: String = ""
    //助记词

    
    
    init(account: Account, apiKey: String? = nil, secretKey: String? = nil, passphrase: String? = nil, mnemonic: String? = nil, mnemonicOrder: String? = nil) {
        self.id = account.id
        self.category = account.category
        self.exchange = account.exchange
        self.apiKey = apiKey ?? ""
        self.secretKey = secretKey ?? ""
        self.passphrase = passphrase ?? ""
        self.mnemonic = mnemonic ?? ""
        self.mnemonicOrder = mnemonicOrder ?? ""
    }
    
    
    init(account: Account) {
        self.id = account.id
        self.category = account.category
        self.exchange = account.exchange

        // 从 Keychain 中读取账号信息
        if let retrievedData = KeychainHelper.load(accountID: id).0 {
            let decoder = JSONDecoder()
            if let token = try? decoder.decode(AccountToken.self, from: retrievedData) {
                self.apiKey = token.apiKey
                self.secretKey = token.secretKey
                self.passphrase = token.passphrase
                self.mnemonic = token.mnemonic
                self.mnemonicOrder = token.mnemonicOrder
                print("从 Keychain 中读取账号 \(id) 的token")
            }
        }
    }
    
    
    func updateAssets(completion: @escaping (String, [AccountType: String], [CurrencyAsset]) -> Void) {
        var totalAsset: Double = 0
        var assets: [CurrencyAsset] = []
        
        print("开始更新 \(category) \(exchange) 账号：\(id) 总资产")
        
        switch category {
            case .exchange:
                switch exchange {
                case .OKX:
                    let apiManager = OKXAPIManager(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
                    
                    apiManager.fetchAccountValuation {totalAsset, accountAsset, error in
                        if let totalAsset = totalAsset, let accountAsset = accountAsset {
                            // 更新UI或处理数据
                            completion (totalAsset, accountAsset, assets)
                        } else if let error = error {
                            print("Error fetching assets: \(error)")
                        }
                    }
                case .Binance:
                    let apiManager = BinanceAPIManager(apiKey: apiKey, secretKey: secretKey)
                    
                    apiManager.fetchAccountValuation {totalAsset, accountAsset, error in
                        if let totalAsset = totalAsset, let accountAsset = accountAsset {
                            // 更新UI或处理数据
                            completion (totalAsset, accountAsset, assets)
                        } else if let error = error {
                            print("Error fetching assets: \(error)")
                        }
                    }
                case .Bybit:
                    totalAsset = 234
                case .Kucoin:
                    totalAsset = 345
                case .Huobi:
                    totalAsset = 456
                case .Gateio:
                    totalAsset = 567
                }
            case .wallet:
                totalAsset = 999
        }
    }
    
    func updateAccountAssets(accountType: AccountType, completion: @escaping ([CurrencyAsset]) -> Void) {
        
        var assets: [CurrencyAsset] = []
        
        print("开始更新 \(category) \(exchange) 账号：\(id) 的 \(accountType)")
        
        switch exchange {
        case .OKX:
            
            let apiManager = OKXAPIManager(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
            
            switch accountType {
            case .funding:
                apiManager.fetchFundingAssets {assets, error in
                    if let assets = assets {
                        // 更新UI或处理数据
                        completion (assets)
                    } else if let error = error {
                        print("Error fetching assets: \(error)")
                    }
                }

            case .trading:
                apiManager.fetchTradingAssets {assets, error in
                    if let assets = assets {
                        // 更新UI或处理数据
                        completion (assets)
                    } else if let error = error {
                        print("Error fetching assets: \(error)")
                    }
                }
            case .finance:
                apiManager.fetchSavingAssets {assets, error in
                    if let assets = assets {
                        // 更新UI或处理数据
                        completion (assets)
                    } else if let error = error {
                        print("Error fetching assets: \(error)")
                    }
                }
            default: 
                break
            }
            

        case .Binance:
            let apiManager = BinanceAPIManager(apiKey: apiKey, secretKey: secretKey)
            
            switch accountType {
            case .funding:
                apiManager.fetchFundingAssets {assets, error in
                    if let assets = assets {
                        // 更新UI或处理数据
                        completion (assets)
                    } else if let error = error {
                        print("Error fetching assets: \(error)")
                    }
                }

            case .spot:
                apiManager.fetchSpotAssets {assets, error in
                    if let assets = assets {
                        // 更新UI或处理数据
                        completion (assets)
                    } else if let error = error {
                        print("Error fetching assets: \(error)")
                    }
                }
            case .finance:
                apiManager.fetchSavingAssets {assets, error in
                    if let assets = assets {
                        // 更新UI或处理数据
                        completion (assets)
                    } else if let error = error {
                        print("Error fetching assets: \(error)")
                    }
                }
            default:
                break
            }
            

        case .Bybit:
            assets = []
        case .Kucoin:
            assets = []
        case .Huobi:
            assets = []
        case .Gateio:
            assets = []
        }

        
        
        
        
        
    }
    
    
    
    
    
    
    
}


// 币种数量模型
struct CurrencyAsset: Codable {
    var currency: String  // 币种
    //var amount: Double  // 数量

    let balance: String
    let available: String
    let frozen: String
    let liability: String //负债

    init(currency: String, balance: String, available: String? = nil, frozen: String? = nil, liability: String? = nil) {
        self.currency = currency
        //self.amount = 0
        self.balance = balance
        self.available = available ?? ""
        self.frozen = frozen ?? ""
        self.liability = liability ?? ""
    }
    
    
    init(currency: String?, balance: Double?) {
    //模拟数据初始化
        self.currency = currency ?? ""
        //self.amount = amount ?? 0
        self.balance = ""
        self.available = ""
        self.frozen = ""
        self.liability = ""
    }
    
}

// 主视图模型
class AssetViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var isIdDuplicate: Bool = false
    
    var totalAssetsSum: Double {
        accounts.reduce(0) { $0 + $1.totalAsset }
    }
    
    init() {
        loadAccounts()
    }

    func fetchAssets() {
        print("Start to update assets")
        // 异步获取数据的模拟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {  // 模拟网络延时
            if self.accounts.isEmpty {
                print("填充假数据到数组")
                do {
                    let sampleData = try [
                        Account(id: "OKX1", category: .exchange, exchange: .OKX, totalAsset: 10000, assets: [CurrencyAsset(currency: "BTC", balance: 1.5), CurrencyAsset(currency: "ETH", balance: 10)]),
                        Account(id: "Wallet1", category: .wallet, exchange: .OKX, totalAsset: 20000, assets: [CurrencyAsset(currency: "BTC", balance: 2), CurrencyAsset(currency: "ETH", balance: 20)]),
                        Account(id: "Wallet2", category: .wallet, exchange: .OKX, totalAsset: 30000, assets: [CurrencyAsset(currency: "BTC", balance: 2), CurrencyAsset(currency: "ETH", balance: 20)])
                    ]
                    self.accounts.append(contentsOf: sampleData)
                } catch{
                    print("填充假数据到数组")
                }
            }
            self.saveAccounts()
        }
        
        
        for index in accounts.indices {
            let accountToken = AccountToken(account: accounts[index])
            accountToken.updateAssets { totalAsset, accountAsset, assets in
                // 使用 DispatchQueue.main.sync 确保更新发布到 @Published 属性的操作在主线程上执行
                DispatchQueue.main.sync {
                    self.accounts[index].totalAsset = Double(totalAsset) ?? 0.0
                    self.accounts[index].accountAsset = accountAsset
                    self.accounts[index].assets = assets
                }
                self.saveAccounts()
            }
        }

        

    }
    

    func updateAsset() {
        print("开始更新账号资产：资产+1")
        self.accounts[0].totalAsset += 1
        
        
    
    }
    
    
    // 方法来处理列表项的移动
    func moveAccount(from source: IndexSet, to destination: Int) {
        accounts.move(fromOffsets: source, toOffset: destination)
        saveAccounts()
    }

    func addAccount(account: Account) {
        if !isIdUnique(id: account.id) {
            isIdDuplicate = true
        } else {
            accounts.append(account)
            saveAccounts()
            isIdDuplicate = false
        }
    }

    private func isIdUnique(id: String) -> Bool {
        !accounts.contains { $0.id == id }
    }

    func removeAccount(at offsets: IndexSet) {
        // 遍历要删除的索引集合
        for index in offsets {
            // 检查索引是否有效
            if index < accounts.count {
                // 获取要删除的账户对象
                let accountToDelete = accounts[index]
                // 调用账户对象的删除方法
                do {
                    let resultMessage = try accountToDelete.deleteInfo()
                    // 从数组中移除对应的元素
                    print("\(#function)resultMessage: ", resultMessage)
                    accounts.remove(at: index)
                    saveAccounts()
                } catch {
                    // 处理错误，比如打印错误信息或者进行其他的错误处理
                    print("An error occurred: \(error)")
                }


            }
        }
    }
    
    func saveAccounts() {
        // 将账号数据保存到 UserDefaults 或其他持久化存储
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: "SavedAccounts")
            //print("保存账号到UserDefaults：\(accounts)")
        }
    }

    func loadAccounts() {
        // 从 UserDefaults 或其他持久化存储加载账号数据
        if let savedAccounts = UserDefaults.standard.object(forKey: "SavedAccounts") as? Data {
            let decoder = JSONDecoder()
            if let loadedAccounts = try? decoder.decode([Account].self, from: savedAccounts) {
                accounts = loadedAccounts
                print("加载保存的账号：\(accounts)")
            }
        }
    }
}


// 主视图，展示账号列表
struct tab_AssetView: View {
    @ObservedObject var viewModel = AssetViewModel()
    @State private var showingAddAccount = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("总资产合计")
                        Spacer()
                        Text("$\(viewModel.totalAssetsSum, specifier: "%.2f")")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }

                ForEach(Array(viewModel.accounts.enumerated()), id: \.element.id) { index, account in
                    NavigationLink(destination: AccountDetailView(account: account, index: index, viewModel: viewModel)) {
                       VStack(alignment: .leading) {
                            HStack {
                                Text("\(account.id)")
                                Text("\(account.category == .exchange ? " \(account.exchange)" : "钱包") ")
                                    .font(.caption)
                                    .foregroundColor(Color.gray)
                            }

                            Text("总资产: $\(account.totalAsset, specifier: "%.2f")")
                        }
                    }
                }
                .onDelete(perform: viewModel.removeAccount)
                .onMove(perform: viewModel.moveAccount)
            }
            .refreshable {
                viewModel.fetchAssets()  // 刷新数据
                //viewModel.updateAsset()
                
            }
            .navigationTitle("我的账号")
            .toolbar {
                EditButton()  // SwiftUI 提供的编辑按钮，用于切换列表的编辑模式
            }
            .navigationBarItems(trailing: Button(action: {
                showingAddAccount = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView(viewModel: viewModel, showingAddAccount: $showingAddAccount)
            }
            .onAppear {
                viewModel.loadAccounts()
            }
        }
    }
}

// 详细视图，根据账号类型显示不同内容
struct AccountDetailView: View {
    var account: Account
    let index: Int
    @State private var showingModifyAccount = false
    @State private var newId: String = "" // 假设 account.id 是 String 类型
    @ObservedObject var viewModel: AssetViewModel
    
    var body: some View {
        List {
            if account.category == .exchange {
                Section(header: Text("账户类型")) {
                    ForEach(account.accountAsset.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { key, value in
                        NavigationLink(destination: AccountCurrencyView(account: account, accountType: key, viewModel: AccountCurrencyViewModel(account: account, accountType: key))) {
                            HStack {
                                Text(key.rawValue)
                                Spacer()
                                Text(value)
                            }
                        }
                    }
                }
            }
            ForEach(account.assets, id: \.currency) { asset in
                HStack {
                    Text(asset.currency)
                    Spacer()
                    Text("\(asset.balance)")
                }
            }
        }
        .navigationTitle("\(account.category == .exchange ? " \(account.exchange)" : "钱包") \(account.id) ")
        
        .navigationBarItems(trailing: Button(action: {
            showingModifyAccount = true
        }) {
            Image(systemName: "square.and.pencil")
        })
        .sheet(isPresented: $showingModifyAccount) {
            modifyAccountView(account:account,index: index, viewModel: viewModel, showingModifyAccount: $showingModifyAccount, id: account.id)
        }
        
        
        
        
        
        
    }
}


// 子账号视图模型，根据交易所账号类型显示不同内容
class AccountCurrencyViewModel: ObservableObject {
    @Published var CurrencyAsset: [CurrencyAsset] = []
    @Published var isLoading: Bool = true
    let account:Account
    let accountType: AccountType
    
    init(account: Account, accountType: AccountType) {
        self.account = account
        self.accountType = accountType
        print("初始化子账号视图模型AccountCurrencyViewModel", accountType)
    }
    
    func fetchAccountAssets() {
        print("Start to update account assets")
        // 异步获取数据的模拟
        
        let accountToken = AccountToken(account: account)
        accountToken.updateAccountAssets(accountType: accountType) { assets in
            // 使用 DispatchQueue.main.sync 确保更新发布到 @Published 属性的操作在主线程上执行
            DispatchQueue.main.sync {
                self.CurrencyAsset = assets
                self.isLoading = false
            }
        }
    }
    
}

// 子账户币种详情视图
struct AccountCurrencyView: View {
    var account: Account
    var accountType: AccountType
    @ObservedObject var viewModel: AccountCurrencyViewModel


    var body: some View {

        List {
            Text("币种数量")
                if viewModel.isLoading {
                    ProgressView() // 显示加载指示器
                        .progressViewStyle(.circular) // 设置为圆形进度条
                        .frame(width: 100, height: 100)// 设置大小
                        .padding(.horizontal, 300.0)

                        
                }
                ForEach(viewModel.CurrencyAsset, id: \.currency) { asset in
                    HStack {
                        Text(asset.currency)
                        Spacer()
                        Text("\(asset.balance)")
                    }
                }
            
        }
        .navigationTitle("\(accountType.rawValue)")
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("onAppear事件启动")
                viewModel.fetchAccountAssets()
            }
        }
        .refreshable {
            viewModel.CurrencyAsset = []
            viewModel.isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                //延迟0.3秒加载
                viewModel.fetchAccountAssets()  // 刷新数据
                
            }
            
        }
    }
}
 

//添加保存新账号的资料
struct AddAccountView: View {
    @ObservedObject var viewModel: AssetViewModel   // 接收外部传入的AssetViewModel实例
    @Binding var showingAddAccount: Bool   // 接收外部传入的绑定状态
    @State private var id: String = ""
    @State private var category: AccountCategory = .exchange
    @State private var selectedExchange: Exchange = .OKX  // 默认选择
    @State private var apiKey: String = ""
    @State private var secretKey: String = ""
    @State private var passphrase: String = ""
    @State private var mnemonic: String = ""
    @State private var mnemonicOrder: String = ""
    @State private var showingAlert = false
    @State private var errorText: String = ""

    var body: some View {
        
        NavigationView {
            Form {
                TextField("账号名称（不可重复）", text: $id)
                Picker("账号类型", selection: $category) {
                    Text("交易所账号").tag(AccountCategory.exchange)
                    Text("线上钱包").tag(AccountCategory.wallet)
                }
                .pickerStyle(SegmentedPickerStyle())

                if category == .exchange {
                    Picker("选择交易所", selection: $selectedExchange) {
                        ForEach(Exchange.allCases, id: \.self) { exchange in
                            Text(exchange.rawValue).tag(exchange)
                        }
                    }
                    if  selectedExchange == .OKX {
                        TextField("Passphrase 密码", text: $passphrase)
                    }
                    TextField("API Key", text: $apiKey)
                    TextField("Secret key 密钥", text: $secretKey)

                } else {
                    TextField("助记词", text: $mnemonic)
                    TextField("钱包顺序", text: $mnemonicOrder)
                        .keyboardType(.numberPad)
                }

                Button("保存") {
                    if  category == .exchange {
                        if id == "" {
                            errorText = "请填写账号名称ID"
                            showingAlert = true
                        } else if passphrase == "" && selectedExchange == .OKX {
                            errorText = "请填写passphrase"
                            showingAlert = true
                        } else if apiKey == "" {
                            errorText = "请填写API Key"
                            showingAlert = true
                        } else if secretKey == "" {
                            errorText = "请填写Secret key 密钥"
                            showingAlert = true
                        } else {
                            do {
                                let newAccount = try Account(id: id, category: category, exchange: selectedExchange, totalAsset: 0, assets: [])
                                viewModel.addAccount(account: newAccount)
                            } catch{
                                print("初始化数据")
                            }
                            
                            
                            do {
                                let newAccount = try Account(id: id, category: category, exchange: selectedExchange, apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
                                // Save to Keychain
                                //try AccountAsset.save(accountAsset: newAccount) // 假设这个方法现在抛出了异常
                                // 保存成功后的操作（无需错误处理和赋值，因为 save 方法不返回任何东西或错误）
                                showingAddAccount = false
                                viewModel.fetchAssets()
                            } catch MyError.textError(let errorMessage) {
                                // 处理 AccountAsset 初始化时的异常
                                errorText = errorMessage
                                showingAlert = true
                            } catch {
                                // 处理其他可能的异常（来自 save 方法或其他地方）
                                errorText = "添加交易所账号时发生未知错误"
                                showingAlert = true
                            }
                            
                            
                            
                        }
                        
                    } else {
                        if id == "" {
                            errorText = "请填写ID"
                            showingAlert = true
                        } else if mnemonic == "" {
                            errorText = "请填写助记词"
                            showingAlert = true
                        } else if mnemonicOrder == "" {
                            errorText = "请填写钱包顺序"
                            showingAlert = true
                        } else {
                            do {
                                let newAccount = try Account(id: id, category: category, exchange: selectedExchange, totalAsset: 0, assets: [])
                                viewModel.addAccount(account: newAccount)
                            } catch{
                                print("初始化数据")
                            }

                            
                            do {
                                let newAccount = try Account(id: id, category: category, mnemonic: mnemonic, mnemonicOrder: mnemonicOrder)
                                // Save to Keychain
                                //try AccountAsset.save(accountAsset: newAccount) // 假设这个方法现在抛出了异常
                                // 保存成功后的操作（无需错误处理和赋值，因为 save 方法不返回任何东西或错误）
                                showingAddAccount = false
                                //viewModel.fetchAssets()
                            } catch MyError.textError(let errorMessage) {
                                // 处理 AccountAsset 初始化时的异常
                                errorText = errorMessage
                                showingAlert = true
                            } catch {
                                // 处理其他可能的异常（来自 save 方法或其他地方）
                                errorText = "添加钱包时发生未知错误"
                                showingAlert = true
                            }
                        }
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("错误"), message: Text(errorText), dismissButton: .default(Text("好")))
                }
            }
            .navigationBarTitle("添加账号", displayMode: .inline)
        }
    }
}

//修改账号id
struct modifyAccountView: View {
    var account: Account
    let index: Int
    @ObservedObject var viewModel: AssetViewModel   // 接收外部传入的AssetViewModel实例
    @Binding var showingModifyAccount: Bool   // 接收外部传入的绑定状态
    @State var id: String
    @State private var showingAlert = false
    @State private var errorText: String = ""

    var body: some View {
        
        NavigationView {
            Form {
                TextField("账号名称（不可重复）", text: $id)
                

                Button("保存") {
                        if id == "" {
                            errorText = "请填写账号名称ID"
                            showingAlert = true
                        } else {
                            do {
                                let state = try viewModel.accounts[index].updateInfo(newAccountID: id)
                                print("更新账号id: ", state)
                                showingModifyAccount = false
                                viewModel.saveAccounts()
                                
                            } catch MyError.textError(let errorMessage) {
                                // 处理 AccountAsset 初始化时的异常
                                errorText = errorMessage
                                showingAlert = true
                            } catch {
                                // 处理其他可能的异常（来自 save 方法或其他地方）
                                errorText = "添加交易所账号时发生未知错误"
                                showingAlert = true
                            }
                           
                            

                        }
   
                    
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("错误"), message: Text(errorText), dismissButton: .default(Text("好")))
                }
            }
            .navigationBarTitle("添加账号", displayMode: .inline)
        }
    }
}

#Preview {
    tab_AssetView()
}


