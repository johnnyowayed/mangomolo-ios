
import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    private init() {}

    func saveSubscriptionStatus(_ subscribed: Bool) {
        let key = "isSubscribed"
        let value = subscribed ? "true" : "false"
        if let data = value.data(using: .utf8) {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: key,
                kSecValueData: data
            ] as CFDictionary
            SecItemDelete(query)
            SecItemAdd(query, nil)
        }
    }

    func loadSubscriptionStatus() -> Bool {
        let key = "isSubscribed"
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary

        var dataTypeRef: AnyObject?
        if SecItemCopyMatching(query, &dataTypeRef) == noErr,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value == "true"
        }
        return false
    }
}
