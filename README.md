## iOSPC60F

- ##### 1.1 Change log

  ##### [Change log](https://github.com/viatom-dev/iOSPC60F/blob/main/ChangeLog.md)

- ##### 1.2 Functions

  iOSPC60F is iOS framework for a part of Viatom's Product. Currently, PC_60F is mainly supported.

  There are two parts in this lib.

  1.Communicate function.

  Through this, you can make iOS app communicate with PC_60F. And you can get data from it. 

  2.Data analysis function.

  Parse the acquired data and make it available to developers.

## Environment

  iOS 9.0 or later.

## Installation

Drag the SDK file into the project, and it includes 4 files:

CRAP20SDK.h, CRBleDevice.h, CRBlueToothManager.h, libSpO2SDK.a

## Quick start

### CRBlueToothManager

**Handling the Bluetooth connection class of the central and peripherals, it is a singleton.**

It conforms to：<CRBlueToothManagerDelegate>.

- The current Bluetooth status of your iOS device

  Callback：- (void)bleManager:(CRBlueToothManager *)manager didUpdateState:(CBManagerState)state

- Scan for Bluetooth devices.

  Through the callback **- (void)bleManager:(CRBlueToothManager *)manager didSearchCompleteWithResult:(NSArray<CRBleDevice *> *)deviceList**, filter out what you need from the scanned device list.

```objective-c
- (void)startSearchDevicesForSeconds:(NSUInteger)seconds;
```

- Stop searching for Bluetooth devices

```objective-c
- (void)stopSearch;
```

- Connect to a Bluetooth device. This method is invoked if the device is scanned.

  Callback for successful connection：- (void)bleManager:(CRBlueToothManager *)manager didConnectDevice:(CRBleDevice *)device

  Callback for successful connection：- (void)bleManager:(CRBlueToothManager *)manager didFailToConnectDevice:(CRBleDevice *)device Error:(NSError *)error

```objective-c
- (void)connectDevice:(CRBleDevice *)device;
```

- Disconnect the Bluetooth connection with the device. The premise of this method call is that a Bluetooth connection has been established with the device.

  Callback for successful disconnection：- (void)bleManager:(CRBlueToothManager *)manager didDisconnectDevice:(CRBleDevice *)device Error:(NSError *)error

```objective-c
- (void)disconnectDevice:(CRBleDevice *)device;
```

### CRBleDevice

**Connected device model**。

### CRAP20SDK

**It is a singleton method that the SDK exposes the data processing logic of Bluetooth communication internally.**

It conforms to：<CRAP20SDKDelegate>

- Receive blood oxygen parameters.

  Implement the corresponding delegate method in the controller that wants to receive the data：

  -(void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSpo2Value:(int)spo2 PulseRate:(int)pr PI:(int)pi State:(CRAP_20Spo2State)state Mode:(CRAP_20Spo2Mode)mode BattaryLevel:(int)battaryLevel FromDevice:(CRBleDevice *)device

- Query device serial number.

  Callback for successful query：- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSerialNumber:(NSString *)serialNumber FromDevice:(CRBleDevice *)device

```objective-c
- (void)queryForSerialNumberForDevice:(CRBleDevice *)device;
```

## For more

See the corresponding protocol and header file.

Bluetooth connection related：[CRBlueToothManager.h](https://github.com/viatom-dev/iOSPC60F/blob/main/PC-60F/PC-60F_zh/PC_60FDemo/PC_60ESDK/PC_60ESDK/CRBlueToothManager.h)

Device model：[CRBleDevice.h](https://github.com/viatom-dev/iOSPC60F/blob/main/PC-60F/PC-60F_zh/PC_60FDemo/PC_60ESDK/PC_60ESDK/CRBleDevice.h)

Data communication between App and Bluetooth device：[CRAP20SDK.h](https://github.com/viatom-dev/iOSPC60F/blob/main/PC-60F/PC-60F_zh/PC_60FDemo/PC_60ESDK/PC_60ESDK/CRAP20SDK.h)

Protocol：《[FingerClipOximeter.doc](https://github.com/viatom-dev/iOSPC60F/blob/main/PC-60F/PC-60F_en/FingerClipOximeter.doc)》



