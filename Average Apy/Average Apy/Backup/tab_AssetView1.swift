//
//  tab_AssetView.swift
//  Average Apy
//
//  Created by ChatGPT on 4/5/24.
//


import SwiftUI
import Security


struct tab_AssetView1 {
    // 账户类型枚举
    enum AccountType: String, CaseIterable {
        case funds = "资金账户"
        case loan = "借贷账户"
        case trade = "交易账户"
        case earn = "赚币账户"
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
    struct AccountAsset: Identifiable, Codable {
        var id: String
        var category: AccountCategory
        var exchange: Exchange
        private var apiKey: String = ""
        private var secretKey: String
        private var passphrase: String = ""
        private var mnemonic: String = ""
        //助记词
        
        var totalAsset: Double
        var assets: [CurrencyAsset]
        
        
        init(id: String, category: AccountCategory, exchange: Exchange? = nil, apiKey: String? = nil, secretKey: String? = nil, passphrase: String? = nil, mnemonic: String? = nil, totalAsset: Double? = nil, assets: [CurrencyAsset]? = nil) {
            self.id = id
            self.category = category
            self.exchange = exchange ?? .OKX
            self.apiKey = apiKey ?? ""
            self.secretKey = secretKey ?? ""
            self.passphrase = passphrase ?? ""
            self.mnemonic = mnemonic ?? ""
            self.totalAsset = totalAsset ?? 0
            self.assets = assets ?? []
            
            // 使用 Keychain 保存账号信息
            let service = "com.example.app"
            let account = "example_account"
            let tokenData = "your_token".data(using: .utf8)!
            
            saveToKeychain(service: service, account: account, data: tokenData)
            
            // 从 Keychain 中读取账号信息
            if let retrievedData = readFromKeychain(service: service, account: account) {
                let token = String(data: retrievedData, encoding: .utf8)
                print("Retrieved token:", token ?? "")
            }
        }
        
        
        
    }
    

    
    func okx(){
        let apiManager = OKXAPIManager(apiKey: "your_api_key", secretKey: "your_secret_key", passphrase: "your_passphrase")
        apiManager.fetchFundingAssets { assets, error in
            if let assets = assets {
                // 更新UI或处理数据
            } else if let error = error {
                print("Error fetching assets: \(error)")
            }
        }
    }
    
    // 币种资产模型
    struct CurrencyAsset: Codable {
        var currency: String  // 币种
        var amount: Double  // 数量
        
        let balance: String
        let available: String
        let frozen: String
        
        init(currency: String?, balance: String?, available: String?, frozen: String?) {
            self.currency = ""
            self.amount = 0
            self.balance = balance ?? ""
            self.available = available ?? ""
            self.frozen = frozen ?? ""
        }
        
        
        init(currency: String?, amount: Double?) {
            self.currency = currency ?? ""
            self.amount = amount ?? 0
            self.balance = ""
            self.available = ""
            self.frozen = ""
        }
        
    }
    
    // 视图模型
    class AssetViewModel: ObservableObject {
        @Published var accounts: [AccountAsset] = []
        @Published var isIdDuplicate: Bool = false
        
        var totalAssetsSum: Double {
            accounts.reduce(0) { $0 + $1.totalAsset }
        }
        
        init() {
            loadAccounts()
        }
        
        func fetchAssets() {
            print("Start to update")
            // 异步获取数据的模拟
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {  // 模拟网络延时
                let sampleData = [
                    AccountAsset(id: "OKX1", category: .exchange, exchange: .OKX, totalAsset: 10000, assets: [CurrencyAsset(currency: "BTC", amount: 1.5), CurrencyAsset(currency: "ETH", amount: 10)]),
                    AccountAsset(id: "Wallet1", category: .wallet, exchange: .OKX, totalAsset: 20000, assets: [CurrencyAsset(currency: "BTC", amount: 2), CurrencyAsset(currency: "ETH", amount: 20)])
                    ,
                    AccountAsset(id: "Wallet2", category: .wallet, exchange: .OKX, totalAsset: 30000, assets: [CurrencyAsset(currency: "BTC", amount: 2), CurrencyAsset(currency: "ETH", amount: 20)])
                ]
                self.accounts = sampleData
            }
            saveAccounts()
        }
        
        
        // 方法来处理列表项的移动
        func moveAccount(from source: IndexSet, to destination: Int) {
            accounts.move(fromOffsets: source, toOffset: destination)
            saveAccounts()
        }
        
        func addAccount(account: AccountAsset) {
            if !isIdUnique(id: account.id) {
                isIdDuplicate = true
            } else {
                accounts.append(account)
                isIdDuplicate = false
            }
        }
        
        private func isIdUnique(id: String) -> Bool {
            !accounts.contains { $0.id == id }
        }
        
        func removeAccount(at offsets: IndexSet) {
            accounts.remove(atOffsets: offsets)
        }
        
        func saveAccounts() {
            // 将账号数据保存到 UserDefaults 或其他持久化存储
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(accounts) {
                UserDefaults.standard.set(encoded, forKey: "SavedAccounts")
            }
        }
        
        func loadAccounts() {
            // 从 UserDefaults 或其他持久化存储加载账号数据
            if let savedAccounts = UserDefaults.standard.object(forKey: "SavedAccounts") as? Data {
                let decoder = JSONDecoder()
                if let loadedAccounts = try? decoder.decode([AccountAsset].self, from: savedAccounts) {
                    accounts = loadedAccounts
                }
            }
        }
    }
    
    
    // 主视图，展示账号列表
    struct tab_AssetView1: View {
        @ObservedObject var viewModel = AssetViewModel()
        @State private var showingAddAccount = false
        
        var body: some View {
            NavigationView {
                List {
                    Section {
                        HStack {
                            Text("所有账号总资产合计")
                            Spacer()
                            Text("\(viewModel.totalAssetsSum, specifier: "%.2f")")
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                    
                    ForEach(viewModel.accounts) { account in
                        NavigationLink(destination: CurrencyDetailView(account: account)) {
                            VStack(alignment: .leading) {
                                Text("\(account.category == .exchange ? "交易所账号" : "钱包") \(account.id)")
                                Text("总资产: \(account.totalAsset, specifier: "%.2f")")
                            }
                        }
                    }
                    .onDelete(perform: viewModel.removeAccount)
                    .onMove(perform: viewModel.moveAccount)
                }
                .refreshable {
                    viewModel.fetchAssets()  // 刷新数据
                }
                .navigationTitle("账号资产")
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
                    viewModel.fetchAssets()
                }
            }
        }
    }
    
    // 详细视图，根据账号类型显示不同内容
    struct CurrencyDetailView: View {
        var account: AccountAsset
        
        var body: some View {
            List {
                if account.category == .exchange {
                    Section(header: Text("账户类型")) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            NavigationLink(destination: AccountCurrencyView(account: account, accountType: type)) {
                                Text(type.rawValue)
                            }
                        }
                    }
                }
                ForEach(account.assets, id: \.currency) { asset in
                    HStack {
                        Text(asset.currency)
                        Spacer()
                        Text("\(asset.amount)")
                    }
                }
            }
            .navigationTitle("\(account.category == .exchange ? "交易所账号" : "钱包") \(account.id) 详情")
        }
    }
    
    // 子账户币种详情视图
    struct AccountCurrencyView: View {
        var account: AccountAsset
        var accountType: AccountType
        
        var body: some View {
            List {
                Text("显示 \(accountType.rawValue) 的币种数据")
                ForEach(account.assets, id: \.currency) { asset in
                    HStack {
                        Text(asset.currency)
                        Spacer()
                        Text("\(asset.amount)")
                    }
                }
            }
            .navigationTitle("\(accountType.rawValue) 币种详情")
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
        @State private var showingAlert = false
        
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
                        TextField("Passphrase 密码", text: $passphrase)
                        TextField("API Key", text: $apiKey)
                        TextField("Secret key 密钥", text: $secretKey)
                        
                    } else {
                        TextField("助记词", text: $mnemonic)
                    }
                    
                    Button("保存") {
                        let newAccount = AccountAsset(id: id, category: category, exchange: selectedExchange, apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, mnemonic: mnemonic)
                        
                        //Save to Keychain
                        let encoder = JSONEncoder()
                        if let encoded = try? encoder.encode(newAccount) {
                            let status = KeychainHelper.save(account: newAccount.id, data: encoded)
                            if status == errSecSuccess {
                                viewModel.addAccount(account: newAccount)
                                print("Account saved successfully.")
                            } else if status == errSecDuplicateItem {
                                print("Error: Duplicate ID. \(status)")
                                showingAlert = true
                            } else {
                                print("An error occurred: \(status)")
                                showingAlert = true
                            }
                        }
                        
                        
                        if viewModel.isIdDuplicate {
                            showingAlert = true
                        } else {
                            showingAddAccount = false  // 保存后关闭弹窗
                        }
                        
                        
                        
                        
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("错误"), message: Text("账号名称重复，请使用其他名称。"), dismissButton: .default(Text("好")))
                    }
                }
                .navigationBarTitle("添加账号", displayMode: .inline)
            }
        }
    }
}


