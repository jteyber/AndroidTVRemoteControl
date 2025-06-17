//
//  CertManager.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

public class CertManager : NSObject {
    
    public func cert(_ url: URL, _ password: String) -> Result<CFArray?> {
        let p12Data: Data
        do {
            p12Data = try Data(contentsOf: url)
            
        } catch let error {
            return .Error(.loadCertFromURLError(error))
        }
        
        let importOptions = [kSecImportExportPassphrase as String: password]
        var rawItems: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, importOptions as CFDictionary, &rawItems)
        
        guard status == errSecSuccess else {
            return .Error(.secPKCS12ImportNotSuccess)
        }
        
        let clientIdentity = CertManager().getSecIdentity()
        
        if clientIdentity == nil {
            
            let dictionaryItems = rawItems as? Array<Dictionary<String, Any>>
            
            let secIdentity: SecIdentity = dictionaryItems![0][kSecImportItemIdentity as String] as! SecIdentity
            
            //        // Notice that kSecClass as String: kSecClassIdentity isn't used here as this is inferred from kSecValueRef.
            let identityAddition = [
                kSecValueRef: secIdentity,
                kSecAttrLabel: "ListenerIdentityLabel"
            ] as NSDictionary
            
            
            let identityStatus = SecItemAdd(identityAddition as CFDictionary, nil)
            
            guard identityStatus == errSecSuccess else {
                return .Error(.secIdentityCreateError)
            }
        }
        
        return .Result(rawItems)
    }
    
    public func getSecIdentity() -> SecIdentity? {
        // On the query, use kSecClassIdentity to make sure a SecIdentity is extracted.
        let identityQuery = [
            kSecClass: kSecClassIdentity,
            kSecReturnRef: true,
            kSecAttrLabel: "ListenerIdentityLabel"
        ] as NSDictionary
        var identityItem: CFTypeRef?
        let getIdentityStatus = SecItemCopyMatching(identityQuery as CFDictionary, &identityItem)

        guard getIdentityStatus == errSecSuccess else {
            return nil
        }
        
        let secIdentity = identityItem as! SecIdentity
        return secIdentity
    }
    
    public func deleteSecIdentity() {
        // On the query, use kSecClassIdentity to make sure a SecIdentity is extracted.
        let identityQuery = [
            kSecClass: kSecClassIdentity,
            kSecReturnRef: true,
            kSecAttrLabel: "ListenerIdentityLabel"
        ] as NSDictionary
        
        let status = SecItemDelete(identityQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound
        else {
            return
        }
    }
    
    public func getSecKey(_ url: URL) -> Result<SecKey> {
        
        guard let certificateData = NSData(contentsOf:url),
              let certificate = SecCertificateCreateWithData(nil, certificateData) else {
            return .Error(.createCertFromDataError)
        }
        
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        let status = SecTrustCreateWithCertificates(certificate, policy, &trust)
        
        guard status == errSecSuccess else {
            return .Error(.secTrustCreateWithCertificatesNotSuccess(status))
        }
 
        guard let secTrust = trust else {
            return (.Error(.createTrustObjectError))
        }
        
        if #available(iOS 14.0, macOS 11.0, *) {
            guard let key = SecTrustCopyKey(secTrust) else {
                return .Error(.secTrustCopyKeyError)
            }
            
            return .Result(key)
        } else {
            return .Error(.deprecatedFunctions)
        }
    }
    
}
