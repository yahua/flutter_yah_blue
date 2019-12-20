import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:convert/convert.dart';
import 'package:sprintf/sprintf.dart';
import 'package:crclib/crclib.dart';

import 'gattpacket.dart';
import 'utils.dart';

class SecondScreen extends StatefulWidget {
  SecondScreen({Key key, this.device}) : super(key:key);
  final BluetoothDevice device;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SecondScreenState(device);
  }
}

class _SecondScreenState extends State<SecondScreen> {

  _SecondScreenState(this.device);
  final BluetoothDevice device;
  BluetoothService upwearService;
  BluetoothCharacteristic readCharacteristic;
  BluetoothCharacteristic writeCharacteristic;
  final String serviceUUID = '00060000-f8ce-11e4-abf4-0002a5d5c51b';
  final String readUUID = '00060001-f8ce-11e4-abf4-0002a5d5c51b';
  final String writeUUID = '00060001-f8ce-11e4-abf4-0002a5d5c51b';


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    device.disconnect();
    Fluttertoast.showToast(msg:'手环断开连接');
  }
  @override
  void initState()  {
    // TODO: implement initState
    super.initState();
    findServices();
    device.state.listen((state){
      if (state == BluetoothDeviceState.disconnected) {
        print('手环断开了连接了');
        Navigator.pop(context);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: new ListView.separated(
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            child: ListTile(
              title: Text(index==0?"设置日期":"获取步数"),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
            onTap: () {
              clickEvent(index);
            },
          );
        },
        itemCount: 2,
        separatorBuilder: (BuildContext context, int index) {
          return Divider(color: Colors.black38);
        },
      ),
    );
  }

  void findServices() async {
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      // do something with service
      if (service.uuid.toString() == serviceUUID) {
        upwearService = service;
        var characteristics = service.characteristics;
        for(BluetoothCharacteristic c in characteristics) {
          if(c.uuid.toString() == readUUID) {
            readCharacteristic = c;
            setCharacteristicNotify(c, true);
          }
          if(c.uuid.toString() == writeUUID) {
            writeCharacteristic = c;
          }
        }
      }
    });
  }

  void setCharacteristicNotify(BluetoothCharacteristic c, bool notify) async{
     bool result = await c.setNotifyValue(notify);
     if (result) {
       print('set BluetoothCharacteristic Notify success');
       c.value.listen((value) {
         String result = hex.encode(value);
         CCTGattPacket packet = new CCTGattPacket(result);
         print('手环返回数据:$result');
       });
     }else {
       print('set BluetoothCharacteristic Notify fail');
     }
  }

  void writeDataToDevice(List<int> value) async {
    String hexStr = hex.encode(value);
    print('写入手环数据:$hexStr');
      writeCharacteristic.write(value);
  }

  void clickEvent(int index) {

    List<int> data = [];
    switch (index) {
      case 0:{
        var today = DateTime.now();
        String date = sprintf('%d%02d%02d%02d%02d%02d%d', [today.year,today.month, today.day,
            today.hour, today.minute, today.second, today.weekday]);
        String dateHex = hexStringFromString(date);
        String writeHex = GATT_BUSINESS_HEAD + GATT_BUSINESS_SET_DATE + '0017';
        writeHex += dateHex;
        int result = Crc16Usb().convert(hex.decode(writeHex));
        writeHex += '0000';
        data = hex.decode(writeHex);

        break;
      }
      case 1:{

        String writeHex = GATT_BUSINESS_HEAD + GATT_BUSINESS_GET_STEP + '0008';
        int result = Crc16Usb().convert(hex.decode(writeHex));
        writeHex += result.toRadixString(16);
        data = hex.decode(writeHex);
        break;
      }
    }
    writeDataToDevice(data);
  }
}