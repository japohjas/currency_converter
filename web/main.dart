import 'dart:convert';
import 'package:web/web.dart' as web; // Korvaa vanhan 'dart:html' -kirjaston
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tarvitaan suomenkieliselle päivämäärälle
import 'package:http/http.dart' as http; // Korvaa vanhan HttpRequestin

/* 
  Päivitetty moderniin Dart-web-standardiin (package:web & package:http).
  Käyttää toimivia v2 API -osoitteita (api.frankfurter.dev).
*/

void main() async {
  // Alustetaan suomen kielen tuki ennen sovelluksen käynnistystä
  await initializeDateFormatting('fi_FI', null);

  var tiedot = '''Sovellus seuraa Euroopan keskuspankin julkaisemia valuuttakursseja. Tiedot päivitetään jokaisena työpäivänä noin klo 16:00 CET. (api.frankfurter.dev/v1)''';
  _kaynnista(tiedot);
}

void _kaynnista(String tiedot) async {
  // Etsitään HTML-elementit uuden standardin mukaisesti
  final paivamaaraEl = web.document.querySelector('#date') as web.HTMLParagraphElement?;
  final paivitettyEl = web.document.querySelector('#paivitetty') as web.HTMLParagraphElement?;
  final infoEl = web.document.querySelector('#info') as web.HTMLParagraphElement?;
  final nappiMuunna = web.document.querySelector('#nappiMuunna') as web.HTMLButtonElement?;

  if (paivamaaraEl != null) paivamaaraEl.innerText = _paivamaara();

  // Haetaan tiedot toimivista api.frankfurter.dev -osoitteista (v2-versiot)
  var dataKurssit = await _haeSisalto('https://api.frankfurter.dev/v1/latest');
  var dataMaat = await _haeSisalto('https://api.frankfurter.dev/v1/currencies');

  if (dataKurssit.isNotEmpty && dataMaat.isNotEmpty) {
    var maalista = (dataKurssit['rates'] as Map).keys.toList();
    var datePalat = (dataKurssit['date'] as String).split('-');

    if (datePalat.length == 3 && paivitettyEl != null) {
      // Otetaan palaset oikeilla indekseillä talteen
      var paiva = _poistaEtunolla(datePalat[2]);
      var kk = _poistaEtunolla(datePalat[1]);
      var vuosi = datePalat[0];
      paivitettyEl.innerText = 'Päivitetty: $paiva.$kk.$vuosi';
    }

    _teeValinnat('#kantavalinta', maalista, dataMaat, 'EUR');
    _teeValinnat('#maavalinta', maalista, dataMaat, 'SEK');
    
    if (infoEl != null) infoEl.innerText = tiedot;
    _muunna(dataKurssit);
  } else {
    if (infoEl != null) infoEl.innerText = 'Virhe: Valuuttatietoja ei saatu ladattua palvelimelta.';
  }

  nappiMuunna?.onClick.listen((e) {
    if (dataKurssit.isNotEmpty) {
      _muunna(dataKurssit);
    }
  });
}

void _teeValinnat(String htmlId, List maalista, Map dataMaat, String oletusValuutta) {
  final valintaElementti = web.document.querySelector(htmlId) as web.HTMLSelectElement?;
  if (valintaElementti == null) return;

  final elementti = web.document.createElement('option') as web.HTMLOptionElement;
  elementti.text = 'EUR - Euro';
  elementti.value = 'EUR';
  valintaElementti.appendChild(elementti);

  for (var maakoodi in maalista) {
    final elm = web.document.createElement('option') as web.HTMLOptionElement;
    elm.text = '$maakoodi - ${dataMaat[maakoodi]}';
    elm.value = maakoodi.toString();
    valintaElementti.appendChild(elm);
    elm.defaultSelected = elm.value == oletusValuutta;
  }
}

Future<Map<String, dynamic>> _haeSisalto(String osoite) async {
  try {
    final response = await http.get(Uri.parse(osoite));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  } catch (e) {
    // Nappaa mahdolliset verkkoyhteysvirheet
  }
  return {};
}

String _paivamaara() {
  var nyt = DateTime.now();
  var muotoilija = DateFormat('EEEE, d.M.yyyy', 'fi_FI');
  return muotoilija.format(nyt);
}

String _poistaEtunolla(String mjono) {
  if (mjono.isEmpty) return '';
  mjono = mjono.trim();
  if (mjono.length == 2 && mjono.startsWith('0')) {
    return mjono[1];
  }
  return mjono;
}

void _muunna(Map<String, dynamic> data) async {
  final kanta = web.document.querySelector('#kantavalinta') as web.HTMLSelectElement?;
  final kohde = web.document.querySelector('#maavalinta') as web.HTMLSelectElement?;
  final syoteKentta = web.document.querySelector('#syote') as web.HTMLInputElement?;

  if (kanta == null || kohde == null || syoteKentta == null) return;

  var kantavaluutta = kanta.value;
  var kantaKurssi = 1.0;
  if (kantavaluutta != 'EUR') {
    kantaKurssi = (data['rates'][kantavaluutta] as num).toDouble();
  }

  var valuutta = kohde.value;
  var kurssi = 1.0;
  if (valuutta != 'EUR') {
    kurssi = (data['rates'][valuutta] as num).toDouble();
  }

  if (kantaKurssi == 0 || kurssi == 0) {
    kantaKurssi = 1;
    kantavaluutta = 'nan';
    kurssi = 1;
    valuutta = 'nan';
  }

  var muuntokerroin = kurssi / kantaKurssi;
  var syote = 0.0;

  if (syoteKentta.value.isEmpty) {
    syote = -1.0;
  } else {
    syote = double.tryParse(syoteKentta.value) ?? -1.0;
  }

  if (syote < 0 || syote > 99999999999.99) {
    syoteKentta.style.color = 'red';
    await Future.delayed(const Duration(milliseconds: 600));
    syoteKentta.style.color = 'black';
    syoteKentta.value = '1';
    syote = 1.0;
  }

  var tulosKerto = syote * muuntokerroin;
  var tulosJako = syote / muuntokerroin;
  var tarkka = syote == 1;

  // Haetaan taulukon solut tekstin tulostusta varten
  final s1 = web.document.querySelector('#solu1') as web.HTMLTableCellElement?;
  final s2 = web.document.querySelector('#solu2') as web.HTMLTableCellElement?;
  final s3 = web.document.querySelector('#solu3') as web.HTMLTableCellElement?;
  final s4 = web.document.querySelector('#solu4') as web.HTMLTableCellElement?;
  final s5 = web.document.querySelector('#solu5') as web.HTMLTableCellElement?;
  final s6 = web.document.querySelector('#solu6') as web.HTMLTableCellElement?;

  if (s1 != null) s1.innerText = '${_format(syote, tarkka)} $kantavaluutta';
  if (s2 != null) s2.innerText = '=';
  if (s3 != null) s3.innerText = '${_format(tulosKerto, tarkka)} $valuutta';
  if (s4 != null) s4.innerText = '${_format(syote, tarkka)} $valuutta';
  if (s5 != null) s5.innerText = '=';
  if (s6 != null) s6.innerText = '${_format(tulosJako, tarkka)} $kantavaluutta';
}

String _format(double luku, bool tarkkaArvo) {
  if (tarkkaArvo) {
    var f = NumberFormat('##0.00###', 'fi_FI');
    return f.format(luku);
  }
  var f = NumberFormat('#,##0.00', 'fi_FI');
  return f.format(luku);
}
