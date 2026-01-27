//
//  TextInput.swift
//
//
//  Created by Joël TEYBER on 27/01/2026.
//

import Foundation

public struct TextInput {
    let string: String
    
    public init(_ s: String) {
        self.string = s
    }
}

extension TextInput: RequestDataProtocol {
    public var data: Data {
        let stringCount: UInt = UInt(self.string.count)
        
        // @ https://github.com/Aymkdn/assistant-freebox-cloud/issues/148#issuecomment-3193843165
        
        var data = Data()
        data.append(contentsOf: [0xaa, 0x1])
        data.append(contentsOf: Encoder.encodeVarint(stringCount + 16))
        data.append(contentsOf: [0x08, 0x00, 0x10, 0x00, 0x1a])
        data.append(contentsOf: Encoder.encodeVarint(stringCount + 10))
        data.append(contentsOf: [0x08, 0x00, 0x12])
        data.append(contentsOf: Encoder.encodeVarint(stringCount + 6))
        data.append(contentsOf: [0x08, 0xb, 0x10, 0xb, 0x1a])
        data.append(contentsOf: Encoder.encodeVarint(stringCount))
        data.append(contentsOf: self.string.utf8)
        return data
    }
}
