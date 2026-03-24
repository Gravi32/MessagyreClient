import UserNotifications
import CryptoSwift
import Foundation
import Security

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else { 
            bestAttemptContent.title = "DEBUG: Extension partita!" 
            return
        }

        let userInfo = bestAttemptContent.userInfo

        guard let cipherTextBase64 = userInfo["CipherText"] as? String,
              let ivBase64 = userInfo["IV"] as? String,
              let encryptedKeyBase64 = userInfo["EncryptedKey"] as? String else {
            contentHandler(bestAttemptContent)
            return
        }

        do {
            let privateKeyPem = try getPrivateKeyFromKeychain(keyName: "RSAPrivateKey")
            let privateKey = try pemToSecKey(pem: privateKeyPem)

            guard let encryptedKeyData = Data(base64Encoded: encryptedKeyBase64) else {
                throw NSError(domain: "DecryptError", code: 1)
            }

            var error: Unmanaged<CFError>?
            guard let aesKeyData = SecKeyCreateDecryptedData(
                privateKey,
                .rsaEncryptionOAEPSHA1,
                encryptedKeyData as CFData,
                &error
            ) as Data? else {
                throw error!.takeRetainedValue() as Error
            }

            let aesKeyBytes = [UInt8](aesKeyData)

            guard let ivData = Data(base64Encoded: ivBase64) else {
                throw NSError(domain: "DecryptError", code: 2)
            }
            let ivBytes = [UInt8](ivData)

            guard let cipherData = Data(base64Encoded: cipherTextBase64) else {
                throw NSError(domain: "DecryptError", code: 3)
            }
            let cipherBytes = [UInt8](cipherData)

            let gcm = GCM(iv: ivBytes, mode: .combined)
            let aes = try AES(key: aesKeyBytes, blockMode: gcm, padding: .noPadding)
            let decryptedBytes = try aes.decrypt(cipherBytes)

            if let decryptedString = String(bytes: decryptedBytes, encoding: .utf8) {
                bestAttemptContent.body = decryptedString
            }

        } catch {
            bestAttemptContent.body = "Une erreur est survenue: \(error.localizedDescription)"
        }

        contentHandler(bestAttemptContent)
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func pemToSecKey(pem: String) throws -> SecKey {
        let base64 = pem
            .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let derData = Data(base64Encoded: base64) else {
            throw NSError(domain: "KeyError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Impossibile decodificare il PEM in base64"])
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ]

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(derData as CFData, attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return secKey
    }

    private func getPrivateKeyFromKeychain(keyName: String) throws -> String {
        let account = "VGhpcyBpcyB0aGUgcHJlZml4_\(keyName)"
        let service = "flutter_secure_storage_service"
        let accessGroup = "group.com.graviware.messagyre"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            guard let pem = String(data: data, encoding: .utf8), !pem.isEmpty else {
                throw NSError(domain: "KeychainError", code: -1)
            }
            return pem
        }

        throw NSError(domain: "KeychainError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "SecItemCopyMatching fallito con status \(status)"])
    }
}
