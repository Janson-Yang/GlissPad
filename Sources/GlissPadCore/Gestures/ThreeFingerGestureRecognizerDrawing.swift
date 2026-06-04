import Foundation

extension ThreeFingerGestureRecognizer {
    func finishDrawing(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> RecognizedGesture? {
        phase = .idle
        guard frame.timestamp - state.startedAt <= TimeInterval(rule.drawing.maximumDurationMilliseconds) / 1000,
              pathLength(state.samples) >= rule.drawing.minimumPathLength,
              regionContains(rule.common.endRegion, touches: state.lastTouches),
              drawingTemplateMatches(state.samples),
              canTrigger(at: frame.timestamp) else {
            return nil
        }
        return recognizedGesture(frame)
    }

    private func drawingTemplateMatches(_ samples: [NormalizedPoint]) -> Bool {
        switch rule.drawing.recognitionMode {
        case .templateMatch:
            return templateMatch(samples)
        case .directionSequence:
            return directionSequenceMatches(samples)
        }
    }

    private func templateMatch(_ samples: [NormalizedPoint]) -> Bool {
        let tolerance = max(0.02, (1 - rule.drawing.scoreThreshold) * 0.32)
        let observed = rule.drawing.normalizeRotation
            ? rotationAligned(samples, template: rule.drawing.template.points)
            : samples
        guard rule.drawing.normalizeScale else {
            return FreeformPathMatcher(
                template: rule.drawing.template.points,
                tolerance: tolerance,
                sampleCount: rule.drawing.resamplePointCount
            ).matches(observed)
        }
        return RelativePathMatcher(
            template: rule.drawing.template.points,
            tolerance: tolerance,
            sampleCount: rule.drawing.resamplePointCount
        ).matches(observed)
    }

    private func rotationAligned(_ samples: [NormalizedPoint], template: [NormalizedPoint]) -> [NormalizedPoint] {
        guard let sampleAngle = endpointAngle(samples), let templateAngle = endpointAngle(template) else { return samples }
        let delta = templateAngle - sampleAngle
        let origin = samples[0]
        return samples.map { rotate($0, around: origin, radians: delta) }
    }

    private func endpointAngle(_ points: [NormalizedPoint]) -> Double? {
        guard let first = points.first, let last = points.last else { return nil }
        let dx = last.x - first.x
        let dy = last.y - first.y
        guard hypot(dx, dy) >= 0.03 else { return nil }
        return atan2(dy, dx)
    }

    private func rotate(_ point: NormalizedPoint, around origin: NormalizedPoint, radians: Double) -> NormalizedPoint {
        let dx = point.x - origin.x
        let dy = point.y - origin.y
        return NormalizedPoint(
            x: origin.x + dx * cos(radians) - dy * sin(radians),
            y: origin.y + dx * sin(radians) + dy * cos(radians)
        )
    }

    private func directionSequenceMatches(_ samples: [NormalizedPoint]) -> Bool {
        let templateDirections = directionSequence(rule.drawing.template.points)
        let sampleDirections = directionSequence(samples)
        guard templateDirections.count == sampleDirections.count, !templateDirections.isEmpty else { return false }
        return zip(templateDirections, sampleDirections).allSatisfy { $0 == $1 }
    }

    private func directionSequence(_ points: [NormalizedPoint]) -> [ThreeFingerDirection] {
        guard points.count > 1 else { return [] }
        let rawDirections = zip(points, points.dropFirst()).compactMap { segmentDirection(from: $0, to: $1) }
        return rawDirections.reduce(into: []) { result, direction in
            if result.last != direction {
                result.append(direction)
            }
        }
    }

    private func segmentDirection(from start: NormalizedPoint, to end: NormalizedPoint) -> ThreeFingerDirection? {
        let dx = end.x - start.x
        let dy = end.y - start.y
        guard hypot(dx, dy) >= 0.03 else { return nil }
        if abs(dx) >= abs(dy) {
            return dx >= 0 ? .right : .left
        }
        return dy >= 0 ? .down : .up
    }
}
