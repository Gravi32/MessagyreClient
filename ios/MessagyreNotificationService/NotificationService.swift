import UserNotifications
import Intents
import CryptoSwift
import Foundation
import Security

/// Runs before iOS shows a push ("mutable-content": 1): decrypts the message and turns the notification into a
/// communication notification (the sender's photo, with the app's icon at the bottom right).
class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    private var delivered = false
    private let lock = NSLock()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        bestAttemptContent = content

        let userInfo = content.userInfo

        if let text = decryptedBody(userInfo) {
            content.body = text
        }

        // The server writes "💬 Name": the name alone, iOS shows that it is a message
        let senderName = Self.senderName(from: userInfo["Title"] as? String ?? content.title)
        let senderUsername = userInfo["SenderUsername"] as? String
        // A class chat (apps from 4.94): grouped under the class, with who wrote
        let group = (userInfo["Group"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        content.title = group.map { "Classe \($0)" } ?? senderName
        if group != nil { content.subtitle = senderName }
        if let thread = group.map({ "#\($0)" }) ?? senderUsername { content.threadIdentifier = thread }

        let pictureURL = (userInfo["ProfilePictureURL"] as? String).flatMap { URL(string: $0) }

        loadImage(pictureURL) { imageData in
            if #available(iOSApplicationExtension 15.0, *) {
                self.deliverAsCommunication(content, senderName: senderName, senderUsername: senderUsername, group: group, imageData: imageData)
            } else {
                self.deliver(content)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let content = bestAttemptContent { deliver(content) }
    }

    /// Calls iOS back once only (the time limit can come while the photo is still loading)
    private func deliver(_ content: UNNotificationContent) {
        lock.lock()
        defer { lock.unlock() }
        guard !delivered else { return }
        delivered = true
        contentHandler?(content)
    }

    // MARK: - Communication notification

    @available(iOSApplicationExtension 15.0, *)
    private func deliverAsCommunication(_ content: UNMutableNotificationContent, senderName: String, senderUsername: String?, group: String?, imageData: Data?) {
        let identifier = senderUsername ?? senderName
        let image = imageData.map { INImage(imageData: $0) }

        let sender = INPerson(
            personHandle: INPersonHandle(value: identifier, type: .unknown),
            nameComponents: nil,
            displayName: senderName,
            image: image,
            contactIdentifier: nil,
            customIdentifier: identifier
        )

        // iOS shows a group conversation (its name, then who wrote) when it has a name and several recipients
        let me = INPerson(personHandle: INPersonHandle(value: "me", type: .unknown), nameComponents: nil, displayName: nil, image: nil, contactIdentifier: nil, customIdentifier: "me", isMe: true)
        let intent = INSendMessageIntent(
            recipients: group == nil ? nil : [me, sender],
            outgoingMessageType: .outgoingMessageText,
            content: content.body,
            speakableGroupName: group.map { INSpeakableString(spokenPhrase: "Classe \($0)") },
            conversationIdentifier: group.map { "#\($0)" } ?? identifier,
            serviceName: nil,
            sender: sender,
            attachments: nil
        )
        if let image = image { intent.setImage(image, forParameterNamed: \.sender) }

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.donate { _ in
            // Without the "Communication Notifications" capability iOS refuses: the normal notification is shown
            if let updated = try? content.updating(from: intent) {
                self.deliver(updated)
            } else {
                self.deliver(content)
            }
        }
    }

    private func loadImage(_ url: URL?, completion: @escaping (Data?) -> Void) {
        guard let url = url else { return completion(nil) }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        URLSession.shared.dataTask(with: request) { data, response, _ in
            let ok = (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            completion(ok ? data : nil)
        }.resume()
    }

    private static func senderName(from title: String) -> String {
        var name = title.trimmingCharacters(in: .whitespaces)
        if name.hasPrefix("💬") { name = String(name.dropFirst()).trimmingCharacters(in: .whitespaces) }
        return name.isEmpty ? "Messagyre" : name
    }

    // MARK: - Decryption (same format as the app: RSA-OAEP SHA-1 for the key, AES-256-GCM for the text)

    private func decryptedBody(_ userInfo: [AnyHashable: Any]) -> String? {
        guard let cipherTextBase64 = userInfo["CipherText"] as? String,
              let ivBase64 = (userInfo["IV"] ?? userInfo["Iv"]) as? String,
              let encryptedKeyBase64 = userInfo["EncryptedKey"] as? String,
              let encryptedKeyData = Data(base64Encoded: encryptedKeyBase64),
              let ivData = Data(base64Encoded: ivBase64),
              let cipherData = Data(base64Encoded: cipherTextBase64) else {
            return nil
        }

        do {
            let privateKey = try pemToSecKey(pem: try getPrivateKeyFromKeychain())

            var error: Unmanaged<CFError>?
            guard let aesKeyData = SecKeyCreateDecryptedData(privateKey, .rsaEncryptionOAEPSHA1, encryptedKeyData as CFData, &error) as Data? else {
                throw error!.takeRetainedValue() as Error
            }

            let gcm = GCM(iv: [UInt8](ivData), mode: .combined)
            let aes = try AES(key: [UInt8](aesKeyData), blockMode: gcm, padding: .noPadding)
            let decryptedBytes = try aes.decrypt([UInt8](cipherData))

            return String(bytes: decryptedBytes, encoding: .utf8)
        } catch {
            NSLog("[Messagyre] Notification not decrypted: \(error.localizedDescription)")
            return nil
        }
    }

    /// The app saves a PKCS#8 PEM ("BEGIN PRIVATE KEY"), iOS wants the PKCS#1 key inside it
    private func pemToSecKey(pem: String) throws -> SecKey {
        let base64 = pem
            .components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("-----") }
            .joined()
            .trimmingCharacters(in: .whitespaces)

        guard let derData = Data(base64Encoded: base64) else {
            throw NSError(domain: "KeyError", code: 1, userInfo: [NSLocalizedDescriptionKey: "The PEM isn't valid base64"])
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ]

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(Self.pkcs1(fromPKCS8: derData) as CFData, attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return secKey
    }

    /// PrivateKeyInfo ::= SEQUENCE { version INTEGER, algorithm SEQUENCE, privateKey OCTET STRING }.
    /// A PKCS#1 key (SEQUENCE { INTEGER, INTEGER... }) is returned as it is.
    static func pkcs1(fromPKCS8 der: Data) -> Data {
        let bytes = [UInt8](der)
        var index = 0

        func readLength() -> Int? {
            guard index < bytes.count else { return nil }
            var length = Int(bytes[index])
            index += 1
            if length & 0x80 != 0 {
                let count = length & 0x7f
                guard count <= 4 else { return nil }
                length = 0
                for _ in 0..<count {
                    guard index < bytes.count else { return nil }
                    length = (length << 8) | Int(bytes[index])
                    index += 1
                }
            }
            return length
        }

        func expect(_ tag: UInt8) -> Int? {
            guard index < bytes.count, bytes[index] == tag else { return nil }
            index += 1
            return readLength()
        }

        guard expect(0x30) != nil,
              let versionLength = expect(0x02) else { return der }
        index += versionLength
        guard let algorithmLength = expect(0x30) else { return der }
        index += algorithmLength
        guard let keyLength = expect(0x04), index + keyLength <= bytes.count else { return der }

        return Data(bytes[index..<(index + keyLength)])
    }

    /// The key saved by flutter_secure_storage (account = the key's name), shared through the app group
    private func getPrivateKeyFromKeychain() throws -> String {
        // The older name is the one the Android version of the plugin used: kept in case a beta wrote it on iOS too
        let accounts = ["RSAPrivateKey", "VGhpcyBpcyB0aGUgcHJlZml4_RSAPrivateKey"]
        var lastStatus: OSStatus = errSecItemNotFound

        for account in accounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
                kSecAttrService as String: "flutter_secure_storage_service",
                kSecAttrAccessGroup as String: "group.com.graviware.messagyre",
                kSecReturnData as String: kCFBooleanTrue!,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]

            var dataTypeRef: AnyObject?
            lastStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

            if lastStatus == errSecSuccess, let data = dataTypeRef as? Data, let pem = String(data: data, encoding: .utf8), !pem.isEmpty {
                return pem
            }
        }

        throw NSError(domain: "KeychainError", code: Int(lastStatus), userInfo: [NSLocalizedDescriptionKey: "SecItemCopyMatching failed with status \(lastStatus)"])
    }
}
