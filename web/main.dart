import 'dart:html';
import 'dart:convert';
import 'package:intl/intl.dart'; // päivämäärä

// https://www.frankfurter.app/docs/
// https://pub.dev/packages/intl
// https://stackoverflow.com/questions/16126579/how-do-i-format-a-date-with-dart
// https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html
// https://dart.dev/codelabs/async-await      // Future.delayed
// 29.9.2020 Jari Pohjasmäki japohjas@gmail.com

void main() {
  kaynnista();
}

void kaynnista() async {
  haePaivamaara();

  var sisaltoKurssit =
      await HttpRequest.getString('https://api.frankfurter.app/latest');
  var dataKurssit = jsonDecode(sisaltoKurssit);
  var maalista = dataKurssit['rates'].keys;

  var sisaltoMaat =
      await HttpRequest.getString('https://api.frankfurter.app/currencies');
  var dataMaat = jsonDecode(sisaltoMaat);

  var datePalat = dataKurssit['date'].split('-');
  // print(datePalat);
  var paiva = poistaEtunolla(datePalat[2]);
  var kk = poistaEtunolla(datePalat[1]);
  var vuosi = datePalat[0];
  querySelector('#paivitetty').text = 'Refreshed: $paiva.$kk.$vuosi';

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

void haePaivamaara() {
  var now = DateTime.now();
  var formatter = DateFormat('EEEE, d.M.yyyy');
  var formatted = formatter.format(now);
  querySelector('#date').text = formatted;
}

String poistaEtunolla(String mjono) {
  if (mjono.isEmpty) {
    return '';
  }

  mjono = mjono.trim();
  if (int.parse(mjono[0]) == 0 && mjono.length == 2) {
    return mjono[1].toString();
  }

  return mjono;
}

void muunna(data) async {
  SelectElement kohdemaa = querySelector('#maavalinta');
  var valuutta = kohdemaa.value;
  var muuntokerroin = data['rates'][valuutta];
  var perusvaluutta = data['base'];

  InputElement input = querySelector('#syote');
  var syote = 0.0;

  if (input.value.isEmpty) {
    syote = -1.0;
  } else {
    syote = double.parse(input.value);
  }

  if (syote < 0 || syote > 99999999999.99) {
    input.style.color = 'red';
    await Future.delayed(Duration(milliseconds: 600),
        () => {input.style.color = 'black', input.value = '1', syote = 1.0});
  }

  var tulosKerto = syote * muuntokerroin * 1.0;
  var tulosJako = syote / muuntokerroin * 1.0;
  var tarkka = syote == 1;

  querySelector('#solu1').text = '${format(syote, tarkka)} $perusvaluutta';
  querySelector('#solu3').text = '${format(tulosKerto, tarkka)} $valuutta';
  querySelector('#solu4').text = '${format(syote, tarkka)} $valuutta';
  querySelector('#solu6').text = '${format(tulosJako, tarkka)} $perusvaluutta';
}

String format(double luku, bool tarkkaArvo) {
  if (tarkkaArvo) {
    var f = NumberFormat('##0.00###', 'en_US');
    var u = f.format(luku);
    var palat = u.split('.');
    return '${palat[0]},${palat[1]}';
  }

  var f = NumberFormat('#,##0.00', 'en_US');
  var u = f.format(luku);
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
