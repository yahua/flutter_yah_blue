import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'upwear.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<ScanResult> list = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  Future<void> _onRefresh() async {
    flutterBlue.stopScan();

    print('开始扫描外设');
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    flutterBlue.scanResults.listen((scanResult) {
      // do something with scan result
//      var device = scanResult[0].device;
//      print('${device.name} found! id: ${device.id}');

      setState(() {
        scanResult.sort((left,right)=>right.rssi.compareTo(left.rssi));
        list.clear();
        for (ScanResult result in scanResult) {
          if (result.rssi > 0)
            continue;
          list.add(result);
        }
      });
    });
  }
  void _connect(int index) async {
      BluetoothDevice device = list[index].device;
      AdvertisementData advertisementData = list[index].advertisementData;
      Fluttertoast.showToast(msg:'正在连接设备');
      await device.connect(timeout:Duration(seconds: 10), autoConnect: true);
      Fluttertoast.cancel();
      Fluttertoast.showToast(msg:'连接成功');
      //跳转
      Navigator.push(context, MaterialPageRoute(builder: (context) =>
          DeviceDetail(device: device, advertisementData: advertisementData)));
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '动态表格',
      home: new Scaffold(
        appBar: new AppBar(
          title: Text('外设列表'),
        ),
        body: RefreshIndicator(
          color: Colors.deepOrangeAccent,
          backgroundColor: Colors.white,
          child: new ListView.separated(
            itemBuilder: (BuildContext context, int index) {
              String title = list[index].device.name;
              String uuid = list[index].device.id.id;
              int rssi = list[index].rssi;
              return GestureDetector(
                child: ListTile(
                  leading: Text("$rssi"),
                  title: Text("name:$title"),
                  subtitle: Text("$uuid"),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
                onTap: () {
                  _connect(index);
                },
              );
            },
            itemCount: list.length,
            separatorBuilder: (BuildContext context, int index) {
              return Divider(color: Colors.black38);
            },
          ),
          onRefresh: _onRefresh,
        )
      ),
    );
  }
}
