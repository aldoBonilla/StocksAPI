//
//  File.swift
//  
//
//  Created by Aldo Bonilla on 04/04/23.
//

import Foundation

public struct ErrorResponse: Codable {
    public let code: String
    public let description: String
    
    public init(code: String, description: String) {
        self.code = code
        self.description = description
    }
}
