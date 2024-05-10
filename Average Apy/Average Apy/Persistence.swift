//
//  Persistence.swift
//  test
//
//  Created by water on 4/26/24.
//

import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CacheApy")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    
    func newPrivateContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = container.viewContext
        return context
    }
}





class PublicPlist{
    public func saveCodableDic<T: Codable>(objects: [String: T], fileName: String = "LocalCache.plist") {
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(objects)
              
            let fileManager = FileManager.default
            let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            let filePath = urls.first!.appendingPathComponent(fileName)
              
            try data.write(to: filePath)
            print("Objects saved successfully: LocalCache.plist")
        } catch {
            print("Error encoding and saving objects:", error)
        }
    }

    public func readCodableDic<T: Codable>(fileName: String = "LocalCache.plist") -> [String: T]? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
          
        guard let directoryURL = urls.first else {
            print("Document directory not found.")
            return nil
        }
          
        let filePath = directoryURL.appendingPathComponent(fileName).path
          
        if !fileManager.fileExists(atPath: filePath) {
            print("File not found at path: \(filePath)")
            return nil
        }
          
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let decoder = PropertyListDecoder()
            let objects = try decoder.decode([String: T].self, from: data)
            return objects
        } catch {
            print("Error decoding objects from file:", error)
            return nil
        }
    }
    public func saveCodable<T: Codable>(objects: [T], fileName: String = "LocalCache.plist") {
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(objects)
              
            let fileManager = FileManager.default
            let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            let filePath = urls.first!.appendingPathComponent(fileName)
              
            try data.write(to: filePath)
            print("Objects saved successfully: LocalCache.plist")
        } catch {
            print("Error encoding and saving objects:", error)
        }
    }

    public func readCodable<T: Codable>(fileName: String = "LocalCache.plist") -> [T]? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
          
        guard let directoryURL = urls.first else {
            print("Document directory not found.")
            return nil
        }
          
        let filePath = directoryURL.appendingPathComponent(fileName).path
          
        if !fileManager.fileExists(atPath: filePath) {
            print("File not found at path: \(filePath)")
            return nil
        }
          
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let decoder = PropertyListDecoder()
            let objects = try decoder.decode([T].self, from: data)
            return objects
        } catch {
            print("Error decoding objects from file:", error)
            return nil
        }
    }
    
    public func clearPlistData(fileName: String = "LocalCache.plist") -> Bool {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        
        guard let directoryURL = urls.first else {
            print("Document directory not found.")
            return false
        }
        
        let filePath = directoryURL.appendingPathComponent(fileName).path
        
        if !fileManager.fileExists(atPath: filePath) {
            print("File not found at path: \(filePath)")
            return false
        }
        
        do {
            try fileManager.removeItem(atPath: filePath)
            print("File removed successfully.")
            return true
        } catch {
            print("Error removing file:", error)
            return false
        }
    }
}




import Security

// 保存数据到 Keychain
func saveToKeychain(service: String, account: String, data: Data) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        //指定Keychain项的类型，如kSecClassGenericPassword表示通用密码。
        kSecAttrService as String: service,
        //一个服务标识符（通常是您的应用程序的bundle标识符或自定义标识符）
        kSecAttrAccount as String: account,
        //一个字符串，用于标识特定服务中的Keychain项，如用户名或电子邮件地址
        kSecValueData as String: data
        //要保存的数据，通常是一个包含密码或其他敏感信息的Data对象。
    ]
    // 调用 SecItemAdd 来保存数据
    let status: OSStatus = SecItemAdd(query as CFDictionary, nil)
    
    // 检查状态并处理可能的错误
    switch status {
    case errSecSuccess:
        print("数据：\(kSecAttrAccount) 已成功保存到Keychain")
    case let error:
        print("保存数据：\(kSecAttrAccount) 到Keychain时出错: \(error)")
        // 在这里可以添加额外的错误处理逻辑
    }
}

// 从 Keychain 中读取数据
func readFromKeychain(service: String, account: String) -> Data? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecReturnData as String: true
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    if status == errSecSuccess {
        return item as? Data
    }
    
    return nil
}


class KeychainHelper {
    
    static func save(account: String, data: Data) -> OSStatus {
        // 首先检查是否已存在相同的 key
        let checkQuery = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : account,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ] as [String : Any]

        var item: CFTypeRef?
        let checkStatus = SecItemCopyMatching(checkQuery as CFDictionary, &item)
        
        // 如果已存在，返回一个错误状态
//        if checkStatus == errSecSuccess {
//            return errSecDuplicateItem
//        }

        // 如果不存在，添加新条目
        let addQuery = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : account,
            kSecValueData as String   : data
        ] as [String : Any]

        //SecItemDelete(addQuery as CFDictionary) // 确保删除任何旧条目
        return SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func load(accountID: String) -> (Data?, OSStatus) {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : accountID,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ] as [String : Any]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        print("Keychain加载结果: ", status)
        if status == noErr {
            return (item as? Data, errSecSuccess)
        } else if status == errSecItemNotFound {
            
        }
        return (nil, errSecItemNotFound)
    }
    
    
    static func update(originalID: String, newAccountID: String) -> OSStatus {
        // 首先检查是否已存在相同的 key
        let checkQuery = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : newAccountID
        ] as [String : Any]
        
        var item: CFTypeRef?
        let checkStatus = SecItemCopyMatching(checkQuery as CFDictionary, &item)
        print("checkStatus查询: ", checkStatus)
        // 如果新id已存在，返回一个已存在错误状态
        if checkStatus == errSecSuccess {
            print("新id已存在: ", checkStatus)
            return errSecDuplicateItem
        }
        if checkStatus == errSecItemNotFound {
            // 如果新id不存在，先读出旧id数据，
            let (data, status) = load(accountID: originalID)
            if status == errSecSuccess {
                //再删除旧的条目
                let deleteStatus = delete(accountID: originalID)
                guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
                    print("删除旧id失败:" ,deleteStatus)
                        return deleteStatus // 删除失败，返回错误状态
                    }
                
                //保存数据
                let addQuery = [
                    kSecClass as String       : kSecClassGenericPassword as String,
                    kSecAttrAccount as String : newAccountID,
                    kSecValueData as String   : data!
                ] as [String : Any]

                return SecItemAdd(addQuery as CFDictionary, nil)
            }
            return status
        }
        return checkStatus
    }
    
    
    static func delete(accountID: String) -> OSStatus {

        // 如果存在，添加新条目
        let removeQuery = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : accountID
        ] as [String : Any]

        // 确保删除条目
        return SecItemDelete(removeQuery as CFDictionary)
    }
    
    
}

    


    
// 定义一个遵循 Error 协议的枚举
enum MyError: Error {
    case textError(message: String)
    // 还可以定义其他类型的错误
    case textCoreError(message: String, coda: Int)
    case textCoreBoolError(message: String, coda: Int, bool: Bool)
}

