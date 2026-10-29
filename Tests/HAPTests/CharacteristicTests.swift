// swiftlint:disable force_try
@testable import HAP
import XCTest

class CharacteristicTests: XCTestCase {
    func testReadOptionalValueType() {
        let characteristic = GenericCharacteristic<Bool?>(type: .identify, value: false)
        guard let value = characteristic.getValue() as? Bool? else {
            XCTFail("Could not get value")
            return
        }
        XCTAssert(value == false)
    }

    func testWriteOptionalValueType() {
        let characteristic = GenericCharacteristic<Bool?>(type: .identify, permissions: [.write])
        do {
            try characteristic.setValue(true, fromChannel: nil)
        } catch {
            XCTFail("Could not set value: \(error)")
        }
    }

    func testReadWriteOptionalValueType() {
        let characteristic = GenericCharacteristic<Bool?>(type: .identify, value: false)
        do {
            try characteristic.setValue(true, fromChannel: nil)
        } catch {
            XCTFail("Could not set value: \(error)")
        }
        guard let value = characteristic.getValue() as? Bool? else {
            XCTFail("Could not get value")
            return
        }
        XCTAssertTrue(value == true)
    }

    func testInitFloatValueType() {
        // This used to trap, as `value` would be a `Float` and `minValue` a `Double`, and
        // `Double(Float(0.0001)) < Double(0.0001)`, so: the initial value would be smaller
        // than the minimum value.
        let characteristic = GenericCharacteristic<Float>(type: .batteryLevel, value: 0.0001, minValue: 0.0001)
        XCTAssertEqual(characteristic.value, 0.0001)
    }

    func testValueClippingToBounds() {
        // clip to bounds using `init()`
        let characteristic = GenericCharacteristic<Float>(type: .batteryLevel, value: 2, maxValue: 1, minValue: 0)
        XCTAssertEqual(characteristic.value, 1)

        // clip to bounds using `value.setter`
        characteristic.value = -1
        XCTAssertEqual(characteristic.value, 0)

        // clip to bounds using `setValue`
        try! characteristic.setValue(2, fromChannel: nil)
        XCTAssertEqual(characteristic.value, 1)
    }

    func testDataValueType() {
        let type = CharacteristicType(UUID(uuidString: "E863F116-079E-48FF-8F27-9C2605A29F52")!)
        let characteristic = GenericCharacteristic<Data>(type: type, value: Data([0x01, 0x02, 0xFF]))
        XCTAssertEqual(characteristic.format, .data)
        XCTAssertEqual(characteristic.getValue() as? String, "AQL/")
        try! characteristic.setValue("AA==", fromChannel: nil)
        XCTAssertEqual(characteristic.value, Data([0x00]))
        XCTAssertThrowsError(try characteristic.setValue("not base64", fromChannel: nil))
    }

    func testWillReadValue() {
        final class Counter: Service {
            let count = GenericCharacteristic<UInt8>(type: .batteryLevel, value: 0, permissions: [.read])
            init() {
                super.init(type: .battery, characteristics: [AnyCharacteristic(count)])
            }
            override func characteristicWillReadValue<T>(_ characteristic: GenericCharacteristic<T>) {
                count.value = (count.value ?? 0) + 1
            }
        }
        let service = Counter()
        let characteristic = service.characteristics.first!
        characteristic.service = service // set by the accessory
        characteristic.willReadValue(fromChannel: nil)
        characteristic.willReadValue(fromChannel: nil)
        XCTAssertEqual(characteristic.getValue() as? UInt8, 2)
    }
}
