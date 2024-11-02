class NetSpeedValue{
  String unitName;
  double value;

  NetSpeedValue({required this.unitName, required this.value});
}

NetSpeedValue netSpeedFmt(BigInt bytesNum){
  String unitName = '';
  double value = 0;
  if (bytesNum < BigInt.from(1024)) {
    unitName = 'B';
    value = bytesNum.toDouble() / 8;
  }else if (bytesNum >= BigInt.from(1024) && bytesNum < BigInt.from(1024*1024)){
    unitName = 'K';
    value = bytesNum / BigInt.from(1024) / 8;
  }else if (bytesNum >= BigInt.from(1024*1024) && bytesNum <= BigInt.from(1024*1024*1024)){
    unitName = 'M';
    value = bytesNum / BigInt.from(1024*1024) / 8;
  }
  return NetSpeedValue(unitName: unitName, value: value);
}

String formatDouble(double d, int n) {
  return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : n);
}