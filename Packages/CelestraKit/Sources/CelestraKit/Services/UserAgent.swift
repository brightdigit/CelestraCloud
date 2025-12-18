//
//  UserAgent.swift
//  CelestraKit
//
//  Created by Leo Dion on 12/18/25.
//

import Foundation

public struct UserAgent {
  
  private enum Names {
    static let cloud = "CelestraCloud"
    static let app = "Celestra"
  }
  
  private init(name: String, build: Int, url: URL) {
    self.name = name
    self.build = build
    self.url = url
  }
  
  public let name: String
  let build: Int
  let url: URL
  
  public static func cloud (build: Int) -> UserAgent {
    .init(name: Names.cloud, build: build, url: .Agent.cloud)
  }
  
  public static func app (build: Int) -> UserAgent {
    .init(name: Names.app, build: build, url: .Agent.app)
  }
  
  public var string: String {
    "\(name)/\(build) (\(url))"
  }
}

private extension URL {
  enum Agent {
    static let cloud : URL = URL(string: "https://github.com/brightdigit/CelestraCloud")!
    static let app : URL = URL(string: "https://celestr.app")!
  }
}
