import Foundation

extension ThreeFingerGestureRecognizer {
    func processDrawing(_ frame: TouchFrame) -> RecognizedGesture? {
        switch phase {
        case .idle, .collecting:
            startTrackingIfPossible(frame, region: rule.common.startRegion ?? rule.common.region)
        case .tracking(var state):
            return updateDrawingTracking(frame, state: &state)
        case .releasing(var state):
            return updateDrawingRelease(frame, state: &state)
        case .cancellingUntilRelease:
            resetIfReleased(frame)
        default:
            phase = .idle
        }
        return nil
    }

    private func updateDrawingTracking(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let active = frame.activeTouches
        if active.count < 3 { return finishDrawingDuringRelease(frame, state: &state) }
        guard active.count == 3 else {
            phase = .cancellingUntilRelease
            return nil
        }
        guard let sample = drawingSample(from: active, state: state) else {
            phase = .cancellingUntilRelease
            return nil
        }
        state.appendSample(sample, touches: active)
        phase = .tracking(state)
        return nil
    }

    private func drawingSample(
        from touches: [TouchPoint],
        state: ThreeFingerTrackingState
    ) -> NormalizedPoint? {
        switch rule.drawing.pathSource {
        case .centroid:
            return NormalizedPoint.centroid(of: touches)
        case .allFingersAverage:
            return averageTrackedFingerMovement(touches, state: state)
        }
    }

    private func averageTrackedFingerMovement(
        _ touches: [TouchPoint],
        state: ThreeFingerTrackingState
    ) -> NormalizedPoint? {
        let deltas = touches.compactMap { touch -> (dx: Double, dy: Double)? in
            guard let anchor = state.anchors[touch.id] else { return nil }
            return (dx: touch.position.x - anchor.x, dy: touch.position.y - anchor.y)
        }
        guard !deltas.isEmpty, let origin = state.centroidAnchor else {
            return NormalizedPoint.centroid(of: touches)
        }
        let count = Double(deltas.count)
        let dx = deltas.map(\.dx).reduce(0, +) / count
        let dy = deltas.map(\.dy).reduce(0, +) / count
        return NormalizedPoint(x: origin.x + dx, y: origin.y + dy)
    }

    private func updateDrawingRelease(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        guard frame.activeTouches.count != 3 else {
            return updateDrawingTracking(frame, state: &state)
        }
        return finishDrawingDuringRelease(frame, state: &state)
    }

    private func finishDrawingDuringRelease(
        _ frame: TouchFrame,
        state: inout ThreeFingerTrackingState
    ) -> RecognizedGesture? {
        let gesture = finishDrawing(frame, state: &state)
        phase = frame.activeTouches.isEmpty ? .idle : .releasing(state)
        return gesture
    }

    func finishDrawing(_ frame: TouchFrame, state: ThreeFingerTrackingState) -> RecognizedGesture? {
        var state = state
        return finishDrawing(frame, state: &state)
    }

    private func finishDrawing(_ frame: TouchFrame, state: inout ThreeFingerTrackingState) -> RecognizedGesture? {
        guard !state.triggered else { return nil }
        guard drawingCompleted(frame: frame, state: state),
              canTrigger(at: frame.timestamp) else { return nil }
        state.triggered = true
        return recognizedGesture(frame)
    }

    private func drawingCompleted(frame: TouchFrame, state: ThreeFingerTrackingState) -> Bool {
        return frame.timestamp - state.startedAt <= TimeInterval(rule.drawing.maximumDurationMilliseconds) / 1000
            && pathLength(state.samples) >= rule.drawing.minimumPathLength
            && regionContains(rule.common.endRegion, touches: state.lastTouches)
            && drawingTemplateMatches(state.samples)
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
