import CoreFoundation
import Foundation

typealias MTDeviceRef = UnsafeMutableRawPointer

struct MTPoint {
    var x: Float
    var y: Float
}

struct MTVector {
    var position: MTPoint
    var velocity: MTPoint
}

struct MTTouch {
    var frame: Int32
    var timestamp: Double
    var pathIndex: Int32
    var state: Int32
    var fingerID: Int32
    var handID: Int32
    var normalizedVector: MTVector
    var zTotal: Float
    var field9: Int32
    var angle: Float
    var majorAxis: Float
    var minorAxis: Float
    var absoluteVector: MTVector
    var field14: Int32
    var field15: Int32
    var zDensity: Float
}

typealias MTFrameCallback = @convention(c) (
    MTDeviceRef?,
    UnsafeMutableRawPointer?,
    Int32,
    Double,
    Int32,
    UnsafeMutableRawPointer?
) -> Void

@_silgen_name("MTDeviceCreateList")
func MTDeviceCreateList() -> Unmanaged<CFArray>?

@_silgen_name("MTRegisterContactFrameCallbackWithRefcon")
func MTRegisterContactFrameCallbackWithRefcon(
    _ device: MTDeviceRef?,
    _ callback: MTFrameCallback?,
    _ refcon: UnsafeMutableRawPointer?
)

@_silgen_name("MTUnregisterContactFrameCallback")
func MTUnregisterContactFrameCallback(_ device: MTDeviceRef?, _ callback: MTFrameCallback?)

@_silgen_name("MTDeviceStart")
@discardableResult
func MTDeviceStart(_ device: MTDeviceRef?, _ options: Int32) -> Int32

@_silgen_name("MTDeviceStop")
@discardableResult
func MTDeviceStop(_ device: MTDeviceRef?) -> Int32
