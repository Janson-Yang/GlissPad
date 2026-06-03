import Foundation

public struct CommandLineOptions: Sendable {
    public enum Mode: Sendable {
        case gui
        case agent
    }

    public let configPath: String?
    public let debug: Bool
    public let promptForPermissions: Bool
    public let showHelp: Bool
    public let mode: Mode

    public static let helpText = """
    Usage: glisspad [--gui] [--agent] [--config path] [--debug] [--no-permission-prompt]

    Opens the GUI by default. Use --agent to run the listener without the GUI.
    """

    public static func parse(arguments: [String]) throws -> CommandLineOptions {
        var configPath: String?
        var debug = false
        var prompt = true
        var showHelp = false
        var mode: Mode = .gui
        var iterator = arguments.dropFirst().makeIterator()

        while let argument = iterator.next() {
            switch argument {
            case "--config":
                configPath = try nextValue(from: &iterator, after: argument)
            case "--debug":
                debug = true
            case "--agent":
                mode = .agent
            case "--gui":
                mode = .gui
            case "--no-permission-prompt":
                prompt = false
            case "--help", "-h":
                showHelp = true
            case let argument where argument.hasPrefix("-psn_"):
                continue
            default:
                throw CommandLineError.unknownArgument(argument)
            }
        }

        return CommandLineOptions(
            configPath: configPath,
            debug: debug,
            promptForPermissions: prompt,
            showHelp: showHelp,
            mode: mode
        )
    }

    private static func nextValue(
        from iterator: inout IndexingIterator<ArraySlice<String>>,
        after flag: String
    ) throws -> String {
        guard let value = iterator.next(), !value.hasPrefix("--") else {
            throw CommandLineError.missingValue(flag)
        }
        return value
    }
}

enum CommandLineError: Error, CustomStringConvertible, Sendable {
    case missingValue(String)
    case unknownArgument(String)

    var description: String {
        switch self {
        case .missingValue(let flag):
            return "Missing value after \(flag)."
        case .unknownArgument(let argument):
            return "Unknown argument: \(argument)."
        }
    }
}
