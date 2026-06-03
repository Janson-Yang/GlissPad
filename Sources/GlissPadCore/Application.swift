import Foundation

public final class Application {
    private let runtime: GestureRuntime
    private let logger: Logger
    private var signalSources: [DispatchSourceSignal] = []

    init(runtime: GestureRuntime, logger: Logger) {
        self.runtime = runtime
        self.logger = logger
    }

    public static func bootstrap(arguments: [String]) throws -> Application {
        let options = try CommandLineOptions.parse(arguments: arguments)
        if options.showHelp {
            throw AppError.helpRequested(CommandLineOptions.helpText)
        }

        let configuration = try loadConfiguration(path: options.configPath)
        let logger = Logger(debugEnabled: options.debug || configuration.debugLogging)
        AccessibilityPermission.requestIfNeeded(prompt: options.promptForPermissions, logger: logger)

        let runtime = GestureRuntime(configuration: configuration, logger: logger)
        return Application(runtime: runtime, logger: logger)
    }

    public func run() {
        installSignalHandlers()

        do {
            try runtime.start()
            logger.info("glisspad is listening. Press Control-C to stop.")
            RunLoop.main.run()
        } catch {
            logger.error("Failed to start: \(error)")
            Foundation.exit(EXIT_FAILURE)
        }
    }

    private func installSignalHandlers() {
        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)
        signalSources = [makeSignalSource(SIGINT), makeSignalSource(SIGTERM)]
        signalSources.forEach { $0.resume() }
    }

    private static func loadConfiguration(path: String?) throws -> AppConfiguration {
        guard let path else {
            return try ConfigurationStore().loadOrCreate()
        }
        return try AppConfiguration.load(path: path)
    }

    private func makeSignalSource(_ signalNumber: Int32) -> DispatchSourceSignal {
        let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
        source.setEventHandler { [runtime, logger] in
            logger.info("Stopping glisspad.")
            runtime.stop()
            Foundation.exit(EXIT_SUCCESS)
        }
        return source
    }
}

public enum AppError: Error, CustomStringConvertible {
    case helpRequested(String)

    public var description: String {
        switch self {
        case .helpRequested(let helpText):
            return helpText
        }
    }
}
