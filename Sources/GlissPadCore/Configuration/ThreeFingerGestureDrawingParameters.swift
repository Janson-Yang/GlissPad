import Foundation

public struct ThreeFingerScaleOptions: Codable, Equatable, Sendable {
    public var direction: ThreeFingerScaleDirection
    public var minimumScaleDelta: Double
    public var minimumScaleVelocity: Double
    public var triggerTiming: ThreeFingerTriggerTiming
    public var thumbDetectionMode: ThreeFingerThumbDetectionMode

    public init(
        direction: ThreeFingerScaleDirection = .spreadOut,
        minimumScaleDelta: Double = 0.18,
        minimumScaleVelocity: Double = 0,
        triggerTiming: ThreeFingerTriggerTiming = .thresholdReached,
        thumbDetectionMode: ThreeFingerThumbDetectionMode = .disabledFallback
    ) {
        self.direction = direction
        self.minimumScaleDelta = minimumScaleDelta
        self.minimumScaleVelocity = minimumScaleVelocity
        self.triggerTiming = triggerTiming
        self.thumbDetectionMode = thumbDetectionMode
    }

    public func validate(name: String) throws {
        guard (0.02...1.5).contains(minimumScaleDelta) else {
            throw ConfigurationError.invalidValue("\(name).minimumScaleDelta must be 0.02...1.5.")
        }
        guard (0.0...10.0).contains(minimumScaleVelocity) else {
            throw ConfigurationError.invalidValue("\(name).minimumScaleVelocity must be 0.0...10.0.")
        }
    }
}

public struct ThreeFingerDrawingTemplate: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var points: [NormalizedPoint]

    public static let defaultLShape = ThreeFingerDrawingTemplate(
        id: "shape_l",
        name: "L Shape",
        points: [
            NormalizedPoint(x: 0.2, y: 0.1),
            NormalizedPoint(x: 0.2, y: 0.8),
            NormalizedPoint(x: 0.7, y: 0.8)
        ]
    )

    public init(id: String, name: String, points: [NormalizedPoint]) {
        self.id = id
        self.name = name
        self.points = points
    }

    public func validate(name: String) throws {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).id must not be empty.")
        }
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard (2...128).contains(points.count) else {
            throw ConfigurationError.invalidValue("\(name).points must contain 2...128 points.")
        }
    }
}

public struct ThreeFingerDrawingOptions: Codable, Equatable, Sendable {
    public var template: ThreeFingerDrawingTemplate
    public var pathSource: ThreeFingerDrawingPathSource
    public var recognitionMode: ThreeFingerDrawingRecognitionMode
    public var scoreThreshold: Double
    public var minimumPathLength: Double
    public var maximumDurationMilliseconds: Int
    public var normalizeRotation: Bool
    public var normalizeScale: Bool
    public var resamplePointCount: Int

    public init(
        template: ThreeFingerDrawingTemplate = .defaultLShape,
        pathSource: ThreeFingerDrawingPathSource = .centroid,
        recognitionMode: ThreeFingerDrawingRecognitionMode = .templateMatch,
        scoreThreshold: Double = 0.75,
        minimumPathLength: Double = 0.24,
        maximumDurationMilliseconds: Int = 1_800,
        normalizeRotation: Bool = false,
        normalizeScale: Bool = true,
        resamplePointCount: Int = 64
    ) {
        self.template = template
        self.pathSource = pathSource
        self.recognitionMode = recognitionMode
        self.scoreThreshold = scoreThreshold
        self.minimumPathLength = minimumPathLength
        self.maximumDurationMilliseconds = maximumDurationMilliseconds
        self.normalizeRotation = normalizeRotation
        self.normalizeScale = normalizeScale
        self.resamplePointCount = resamplePointCount
    }

    public func validate(name: String) throws {
        try template.validate(name: "\(name).template")
        guard (0.0...1.0).contains(scoreThreshold) else {
            throw ConfigurationError.invalidValue("\(name).scoreThreshold must be 0.0...1.0.")
        }
        try validateDistance(minimumPathLength, name: "\(name).minimumPathLength", max: 2.0)
        try ThreeFingerTouchOptions.validate(
            milliseconds: maximumDurationMilliseconds,
            name: "\(name).maximumDurationMilliseconds",
            lowerBound: 100
        )
        guard (8...256).contains(resamplePointCount) else {
            throw ConfigurationError.invalidValue("\(name).resamplePointCount must be 8...256.")
        }
    }
}

