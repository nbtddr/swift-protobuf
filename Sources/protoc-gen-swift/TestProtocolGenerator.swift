import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

class TestProtocolGenerator {
  static func generateTestProtocol(printer p: inout CodePrinter) {
    p.print("public protocol TestProtocol {}")
  }
}
