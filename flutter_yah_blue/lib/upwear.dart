import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:convert/convert.dart';
import 'package:sprintf/sprintf.dart';
import 'package:crclib/crclib.dart';
import 'package:flutter_section_table_view/flutter_section_table_view.dart';

import 'gattpacket.dart';
import 'utils.dart';

class DeviceDetail extends StatefulWidget {
  DeviceDetail({Key key, this.device, this.advertisementData}) : super(key:key);
  final BluetoothDevice device;
  final AdvertisementData advertisementData;
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _DeviceDetailState(device, advertisementData);
  }
}

class _DeviceDetailState extends State<DeviceDetail> {

  _DeviceDetailState(this.device, this.advertisementData);
  final BluetoothDevice device;
  final AdvertisementData advertisementData;
  List<BluetoothService> services = [];
  BluetoothCharacteristic readCharacteristic;
  BluetoothCharacteristic writeCharacteristic;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    device.disconnect();
    Fluttertoast.showToast(msg:'设备断开连接');
  }
  @override
  void initState()  {
    // TODO: implement initState
    super.initState();
    findServices();
    device.state.listen((state){
      if (state == BluetoothDeviceState.disconnected) {
        print('设备断开了连接了');
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
      body: SafeArea(
//        child:tableWidget()
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
                constraints: BoxConstraints(maxWidth: double.infinity),
                height: 180,
                color: Colors.white,
              child: tableHeaderView(),
            ),
            Expanded(
                flex: 1,
                child: tableWidget()
            )
          ],
        ),
      ),
    );
  }
  Widget tableHeaderView(){
    var deviceId = device.id.id;
      return Stack(
        children: <Widget>[
          Positioned(
            left: 15,
            top: 15,
            child: Text(device.name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xff1a1a1a))),
          ),
          Positioned(
            left: 15,
            top: 43,
            child: Text('UUID:$deviceId', style: TextStyle(fontSize: 14, color: Color(0xff1a1a1a))),
          ),
          Positioned(
            left: 15,
            top: 70,
            child: Text('Advertisement Data', style: TextStyle(fontSize: 14, color: Color(0xff1a1a1a))),
          ),
          Positioned(
            left: 15,
            top: 93,
            child: Text(advertisementData.manufacturerData.toString(), style: TextStyle(fontSize: 14, color: Color(0xff1a1a1a))),
    )
        ],
      );
  }
  Widget tableWidget() {
    return Container (
      color: Color(0xffECECF0),
      child: SectionTableView(
        sectionCount: this.services.length,
        numOfRowInSection: (section){
          return this.services[section].characteristics.length;
        },
        cellAtIndexPath: (section, row) {
          return tableCell(section, row);
        },
        headerInSection: (section) {
          return tableSectionHeader(section);
        },
        divider: Container(
          color: Colors.black38,
          height: 0.5,
        ),
      ),
    );
  }
  Widget tableCell(section, row) {
    BluetoothCharacteristic c = this.services[section].characteristics[row];
    String uuid = c.uuid.toString();
    String property = '';
    if (c.properties.read) {
      property += 'Read,';
    }
    if (c.properties.write) {
      property += 'Write,';
    }
    if (c.properties.writeWithoutResponse) {
      property += 'WriteWithoutResponse,';
    }
    if (c.properties.notify) {
      property += 'Notify,';
    }
    if (c.properties.indicate) {
      property += 'Indicate';
    }
    return Container(
      color: Colors.white,
      height: 70,
      child: Stack(
        children: <Widget>[
          Container(
          ),
          Positioned(
            left: 15,
            top: 15,
            child: Text(uuid, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xff666666))),
          ),
          Positioned(
            left: 15,
            top: 40,
            child: Text('Properties: $property', style: TextStyle(fontSize: 14,  color: Color(0xff666666))),
          ),
        ],
      ),
    );
  }
  Widget tableSectionHeader(section){
    BluetoothService service = this.services[section];
    String uuid = service.uuid.toString();
    return Container(
      height: 80.0,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 15,
            bottom: 15,
            width: 360,
            child: Container(
              constraints: BoxConstraints(maxWidth: double.infinity),
              child: Text('UUID:$uuid',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: Color(0xff1a1a1a), fontWeight: FontWeight.bold)),
            ) ,
          ),
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            child: Container(
              color: Colors.black38,
              height: 0.5,
            ),
          )
        ],
      ),
    );
  }

  void findServices() async {
    services = await device.discoverServices();
    services.forEach((service) {
      // do something with service
      var characteristics = service.characteristics;
      for(BluetoothCharacteristic c in characteristics) {
        if(c.properties.notify) {
          setCharacteristicNotify(c, true);
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