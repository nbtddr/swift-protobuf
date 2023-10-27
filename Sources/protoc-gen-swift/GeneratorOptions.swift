// Sources/protoc-gen-swift/GeneratorOptions.swift - Wrapper for generator options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

import SwiftProtobufPluginLibrary

class GeneratorOptions {
  enum OutputNaming {
    case fullPath
    case pathToUnderscores
    case dropPath

    init?(flag: String) {
      switch flag.lowercased() {
      case "fullpath", "full_path":
        self = .fullPath
      case "pathtounderscores", "path_to_underscores":
        self = .pathToUnderscores
      case "droppath", "drop_path":
        self = .dropPath
      default:
        return nil
      }
    }
  }

  enum Visibility {
    case `internal`
    case `public`
    case `package`

    init?(flag: String) {
      switch flag.lowercased() {
      case "internal":
        self = .internal
      case "public":
        self = .public
      case "package":
        self = .package
      default:
        return nil
      }
    }
  }
  
  enum CustomExtension {
    case testProtocol
    
    init?(_ value: String) {
      switch value.lowercased() {
      case "testprotocol":
        self = .testProtocol
      default:
        return nil
      }
    }
    
    var name: String {
      switch self {
      case .testProtocol:
        return "TestProtocol"
      }
    }
  }

  let outputNaming: OutputNaming
  let protoToModuleMappings: ProtoFileToModuleMappings
  let visibility: Visibility
  let implementationOnlyImports: Bool
  let customExtensions: [CustomExtension]

  /// A string snippet to insert for the visibility
  let visibilitySourceSnippet: String

  init(parameter: String?) throws {
    var outputNaming: OutputNaming = .fullPath
    var moduleMapPath: String?
    var visibility: Visibility = .internal
    var swiftProtobufModuleName: String? = nil
    var implementationOnlyImports: Bool = false
    var customExtensions: [CustomExtension] = []

    for pair in parseParameter(string:parameter) {
      switch pair.key {
      case "FileNaming":
        if let naming = OutputNaming(flag: pair.value) {
          outputNaming = naming
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key,
                                                      value: pair.value)
        }
      case "ProtoPathModuleMappings":
        if !pair.value.isEmpty {
          moduleMapPath = pair.value
        }
      case "Visibility":
        if let value = Visibility(flag: pair.value) {
          visibility = value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key,
                                                      value: pair.value)
        }
      case "SwiftProtobufModuleName":
        // This option is not documented in PLUGIN.md, because it's a feature
        // that would ordinarily not be required for a given adopter.
        if isValidSwiftIdentifier(pair.value) {
          swiftProtobufModuleName = pair.value
        } else {
          throw GenerationError.invalidParameterValue(name: pair.key,
                                                      value: pair.value)
        }
      case "ImplementationOnlyImports":
        if let value = Bool(pair.value) {
          implementationOnlyImports = value
        }
      case "Extensions":
        let values = pair.value.components(separatedBy: ",")
        customExtensions = values.compactMap { CustomExtension($0) }
      default:
        throw GenerationError.unknownParameter(name: pair.key)
      }
    }

    if let moduleMapPath = moduleMapPath {
      do {
        self.protoToModuleMappings = try ProtoFileToModuleMappings(path: moduleMapPath, swiftProtobufModuleName: swiftProtobufModuleName)
      } catch let e {
        throw GenerationError.wrappedError(
          message: "Parameter 'ProtoPathModuleMappings=\(moduleMapPath)'",
          error: e)
      }
    } else {
      self.protoToModuleMappings = ProtoFileToModuleMappings(swiftProtobufModuleName: swiftProtobufModuleName)
    }

    self.outputNaming = outputNaming
    self.visibility = visibility

    switch visibility {
    case .internal:
      visibilitySourceSnippet = ""
    case .public:
      visibilitySourceSnippet = "public "
    case .package:
      visibilitySourceSnippet = "package "
    }

    self.implementationOnlyImports = implementationOnlyImports
    self.customExtensions = customExtensions
  }
}
