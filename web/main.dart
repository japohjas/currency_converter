import 'dart:html';
import 'dart:convert';
import 'package:intl/intl.dart'; // päivämäärä

// https://www.frankfurter.app/docs/
// https://pub.dev/packages/intl
// https://stackoverflow.com/questions/16126579/how-do-i-format-a-date-with-dart
// https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html
// 29.9.2020 Jari Pohjasmäki japohjas@gmail.com

void main() {
  kaynnista();
}

void kaynnista() async {
  var sisaltoKurssit =
      await HttpRequest.getString('https://api.frankfurter.app/latest');
  var dataKurssit = jsonDecode(sisaltoKurssit);
  var maalista = dataKurssit['rates'].keys;

  var sisaltoMaat =
      await HttpRequest.getString('https://api.frankfurter.app/currencies');
  var dataMaat = jsonDecode(sisaltoMaat);

  var datePalat = dataKurssit['date'].split('-');
  // print(datePalat);
  querySelector('#paivitetty').text =
      'Refreshed: ${datePalat[2]}.${datePalat[1]}.${datePalat[0]}';

  for (var maakoodi in maalista) {
    OptionElement elementti = Element.option();
    elementti.text = '$maakoodi: ${dataMaat[maakoodi]}';
    elementti.value = maakoodi;
    querySelector('#maavalinta').children.add(elementti);
    elementti.defaultSelected = elementti.value == 'SEK';
  }

  muunna(dataKurssit);

  querySelector('#nappiMuunna').onClick.listen((e) {
    muunna(dataKurssit);
  });
}

void muunna(data) {
  SelectElement kohdemaa = querySelector('#maavalinta');
  var valuutta = kohdemaa.value;
  var muuntokerroin = data['rates'][valuutta];

  InputElement input = querySelector('#syote');

  var syote = double.parse(input.value);
  var tulosKerto = syote * muuntokerroin * 1.0;
  var tulosJako = syote / muuntokerroin * 1.0;

  querySelector('#solu1').text = '${format(syote, syote)} EUR';
  querySelector('#solu3').text = '${format(tulosKerto, syote)} $valuutta';
  querySelector('#solu4').text = '${format(syote, syote)} $valuutta';
  querySelector('#solu6').text = '${format(tulosJako, syote)} EUR';
}

String format(muotoiltava, luku) {
  if (luku == 1) {
    var f = NumberFormat('##0.00###', 'en_US');
    var u = f.format(muotoiltava);
    var palat = u.split('.');
    return '${palat[0]},${palat[1]}';
  }

  var f = NumberFormat('#,##0.00', 'en_US');
  var u = f.format(muotoiltava);
  var palat = u.split('.');
  var palat2 = palat[0].split(',');

  if (palat2.isEmpty) {
    return '${palat[0]},${palat[1]}';
  }

  var mjono = '';
  for (var i = 0; i < palat2.length - 1; i++) {
    mjono += palat2[i] + '.';
  }

  mjono += palat2[palat2.length - 1];
  return '$mjono,${palat[1]}';
}
