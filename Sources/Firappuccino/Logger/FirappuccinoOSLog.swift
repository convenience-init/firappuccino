import Foundation
import Logging
import struct Logging.Logger
import class Foundation.NSLock
import os


/// A custom Unified LogHandler with an optional global override
public struct FirappuccinoOSLog: LogHandler {
	
	// the static properties hold the globally overridden log level (if overridden)
	internal static let overrideLock = NSLock()
	internal static var overrideLogLevel: Logger.Level? = nil
	
	// this holds the log level if not overridden
	internal var _logLevel: Logger.Level = .error
	
	public var logLevel: Logger.Level {
		// when we get asked for the log level, we check if it was globally overridden or not
		get {
			FirappuccinoOSLog.overrideLock.lock()
			defer { FirappuccinoOSLog.overrideLock.unlock() }
			return FirappuccinoOSLog.overrideLogLevel ?? self._logLevel
		}
		// we set the log level whenever we're asked (note: this might not have an effect if globally
		// overridden)
		set {
			self._logLevel = newValue
		}
	}
	
	// globally overrides the logger's log level
	public static func overrideGlobalLogLevel(_ logLevel: Logger.Level) {
		FirappuccinoOSLog.overrideLock.lock()
		defer { FirappuccinoOSLog.overrideLock.unlock() }
		FirappuccinoOSLog.overrideLogLevel = logLevel
	}
	
	public let label: String
	
	/// Additional OSLogger
	private let oslogger: OSLog
	
	public init(label: String) {
		self.label = label
		self.oslogger = OSLog(subsystem: label, category: "")
	}
	
	
	/// Sends a unified logging message to the console
	/// - Parameters:
	///   - level: The `LogLevel` value for the log message
	///   - message: The message as a `Logger.Message`, easily expressed as any `StringLiteral` Type.
	///   - metadata: Optional Metadata to include
	///   - file: The fileName that the method was called from
	///   - function: The name of the function from which the call to this method originated.
	///   - line: The line number at which this method was called.
	public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
		var combinedPrettyMetadata = self.prettyMetadata
		if let metadataOverride = metadata, !metadataOverride.isEmpty {
			combinedPrettyMetadata = self.prettify(
				self.metadata.merging(metadataOverride) {
					return $1
				}
			)
		}
		
		var formedMessage = message.description
		if combinedPrettyMetadata != nil {
			formedMessage += " -- " + combinedPrettyMetadata!
		}
		os_log("%{public}@", log: self.oslogger, type: OSLogType.from(loggerLevel: level), formedMessage as NSString)
	}
	
	private var prettyMetadata: String?
	public var metadata = Logger.Metadata() {
		didSet {
			self.prettyMetadata = self.prettify(self.metadata)
		}
	}
	
	/// Add, remove, or change the logging metadata.
	/// - parameters:
	///    - metadataKey: the key for the metadata item.
	public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
		get {
			return self.metadata[metadataKey]
		}
		set {
			self.metadata[metadataKey] = newValue
		}
	}
	
	
	/// "Pretty" formats the `Logger.Metadata`
	/// - Parameter metadata: The `Logger.Metadata` to format.
	/// - Returns: A "Prettified" `String`representation of the passed `Logger.Metadata`
	private func prettify(_ metadata: Logger.Metadata) -> String? {
		if metadata.isEmpty {
			return nil
		}
		return metadata.map {
			"\($0)=\($1)"
		}.joined(separator: " ")
	}
}


extension OSLogType {
	
	/// Interface for `Logging` -> `OSLog` log level.
	/// - Parameter loggerLevel: The `Logging` log level
	/// - Returns: The corresponding `OSLog` log level to the passed-in `Logging` log level.
	static func from(loggerLevel: Logger.Level) -> Self {
		switch loggerLevel {
			case .trace:
				/// `OSLog` doesn't have `trace`, so use `debug`
				return .debug
			case .debug:
				return .debug
			case .info:
				return .info
			case .notice:
				/// `OSLog` doesn't have `notice`, so use `info`
				return .info
			case .warning:
				/// `OSLog` doesn't have `warning`, so use `info`
				return .info
			case .error:
				return .error
			case .critical:
				return .fault
		}
	}
}

