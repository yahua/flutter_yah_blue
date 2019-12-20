//import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:convert/convert.dart';

final String GATT_BUSINESS_HEAD = '0052';
final String GATT_BUSINESS_BACK = "00a2";  //返回参数
final String GATT_BUSINESS_SET_DATE = '0701'; //设置时间
final String GATT_BUSINESS_GET_STEP ="0300"; //步数


class CCTGattPacket {

  int status;   //0:success
  String errorMsg; //错误提示
  String head;
  String type;
  String content;

  CCTGattPacket(String hexStr) {
    if (!checkIsValid(hexStr)) {
      errorMsg = "无法解析返回值：$hexStr";
      return;
    }
    head = hexStr.substring(0, 4);
    type = hexStr.substring(4, 8);
    status = hex.decode(hexStr.substring(hexStr.length-8, hexStr.length-4)).last;
    content = hexStr.substring(12, hexStr.length-8);
  }





    bool checkIsValid(String hexStr) {
    if (hexStr.length < 20) {
        return false;
    }
    //
    return true;
  }

}