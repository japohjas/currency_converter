import 'dart:html';
import 'dart:convert';
import 'package:intl/intl.dart'; // päivämäärä

/*
29.9.2020 Jari Pohjasmäki japohjas@gmail.com
This app built with Frankfurter API
https://www.frankfurter.app/docs/
https://pub.dev/packages/intl
https://stackoverflow.com/questions/16126579/how-do-i-format-a-date-with-dart
https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html
https://dart.dev/codelabs/async-await      // Future.delayed
18.10.2020 lisätty: try catch
21.10.2020 lisätty vaihdettava kantavaluutta
*/

void main() {
  var info = '''This app tracks the exchange rates published by the 
  European Central Bank through the Frankfurter API.
  The data is updated around 16:00 CET every working day.''';
  kaynnista(info);
}

void kaynnista(info) async {
  querySelector('#date').text = paivamaara();

  var dataKurssit = await haeSisalto('https://api.frankfurter.app/latest');
  var dataMaat = await haeSisalto('https://api.frankfurter.app/currencies');

  if (dataKurssit.isNotEmpty && dataMaat.isNotEmpty) {
    var maalista = dataKurssit['rates'].keys.toList();

    var datePalat = dataKurssit['date'].split('-');
    // print(datePalat);
    if (datePalat.length == 3) {
      var paiva = poistaEtunolla(datePalat[2]);
      var kk = poistaEtunolla(datePalat[1]);
      var vuosi = datePalat[0];
      querySelector('#paivitetty').text = 'Updated: $paiva.$kk.$vuosi';
    }

    OptionElement kanta = Element.option();
    kanta.text = 'EUR - Euro';
    kanta.value = 'EUR';
    querySelector('#kantavalinta').children.add(kanta);

    for (var maakoodi in maalista) {
      OptionElement elementti = Element.option();
      elementti.text = '$maakoodi - ${dataMaat[maakoodi]}';
      elementti.value = maakoodi;
      querySelector('#kantavalinta').children.add(elementti);
      elementti.defaultSelected = elementti.value == 'EUR';
    }

    OptionElement maa = Element.option();
    maa.text = 'EUR - Euro';
    maa.value = 'EUR';
    querySelector('#maavalinta').children.add(maa);

    for (var maakoodi in maalista) {
      OptionElement elementti = Element.option();
      elementti.text = '$maakoodi - ${dataMaat[maakoodi]}';
      elementti.value = maakoodi;
      querySelector('#maavalinta').children.add(elementti);
      elementti.defaultSelected = elementti.value == 'SEK';
    }

    querySelector('#info').text = info;
    muunna(dataKurssit);
  } else {
    dataKurssit.clear();
  }

  querySelector('#nappiMuunna').onClick.listen((e) {
    if (dataKurssit.isNotEmpty) {
      muunna(dataKurssit);
    }
  });
}

Future haeSisalto(osoite) async {
  var sisalto = {};
  try {
    // Make the GET request
    var jsonString = await HttpRequest.getString(osoite);
    sisalto = jsonDecode(jsonString);
  } catch (e) {
    // The GET request failed. Handle the error.
    querySelector('#info').text = 'Request failed. Couldn\'t open $osoite';
  }
  return sisalto;
}

String paivamaara() {
  var now = DateTime.now();
  var formatter = DateFormat('EEEE, d.M.yyyy');
  return formatter.format(now);
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
  SelectElement kanta = querySelector('#kantavalinta');
  var kantavaluutta = kanta.value;
  var kantaKurssi = 1.0;
  if (kantavaluutta != 'EUR') {
    kantaKurssi = data['rates'][kantavaluutta];
    // kantaKurssi = 0;
  }
  // print(kantaKurssi);

  SelectElement kohde = querySelector('#maavalinta');
  var valuutta = kohde.value;
  var kurssi = 1.0;
  if (valuutta != 'EUR') {
    kurssi = data['rates'][valuutta];
  }
  // print(kurssi);
  if (kantaKurssi == 0) {
    kantaKurssi = -1;
    kantavaluutta = 'nan';
    valuutta = 'nan';
  }

  var muuntokerroin = kurssi / kantaKurssi;

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

  querySelector('#solu1').text = '${format(syote, tarkka)} $kantavaluutta';
  querySelector('#solu2').text = '=';
  querySelector('#solu3').text = '${format(tulosKerto, tarkka)} $valuutta';
  querySelector('#solu4').text = '${format(syote, tarkka)} $valuutta';
  querySelector('#solu5').text = '=';
  querySelector('#solu6').text = '${format(tulosJako, tarkka)} $kantavaluutta';
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
