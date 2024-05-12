import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CurrencyConverter(),
    );
  }
}

class CurrencyConverter extends StatefulWidget {
  @override
  _CurrencyConverterState createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  late SharedPreferences prefs;
  TextEditingController euroRateController = TextEditingController();
  TextEditingController tlRateController = TextEditingController();
  double inputAmount = 0.0;
  double resultInDZD = 0.0;
  String selectedCurrency = 'TRY';
  String? _exchangeRateError;

  @override
  void initState() {
    super.initState();
    _loadRates();
    fetchAllExchangeRates();
  }
  Future<double> fetchExchangeRate(String currency) async {
    var url = Uri.parse('https://v6.exchangerate-api.com/v6/80787f5bde4917f516075748/latest/$currency');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['conversion_rates']['DZD'];
    } else {
      throw Exception('Failed to load exchange rate');
    }
  }
  Map<String, double> _exchangeRates = {};
  Future<void> fetchAllExchangeRates() async {
    List<String> currencies = ['TRY', 'EUR']; // List of currencies to fetch
    Map<String, double> newRates = {};

    try {
      for (String currency in currencies) {
        double rate = await fetchExchangeRate(currency); // Use your existing method
        newRates[currency] = rate;
      }
      setState(() {
        _exchangeRates = newRates;
        _exchangeRateError = null;  // Clear any previous errors if successful
      });
    } catch (e) {

      setState(() {
        _exchangeRates.clear();  // Clear any existing rates
        _exchangeRateError = 'Failed to load exchange rates'; // Set an appropriate error message
      });
    }
  }

  _loadRates() async {
    prefs = await SharedPreferences.getInstance();
    double? storedEuroRate = prefs.getDouble('euroRate');
    double? storedTLRate = prefs.getDouble('tlRate');
    euroRateController.text = (storedEuroRate ?? 240.0).toString(); // Set default or stored rate
    tlRateController.text = (storedTLRate ?? 34.49).toString(); // Set default or stored rate
  }

  _saveRates() async {
    await prefs.setDouble('euroRate', double.tryParse(euroRateController.text) ?? 240.0);
    await prefs.setDouble('tlRate', double.tryParse(tlRateController.text) ?? 34.49);
  }

  void _convert() {
    _saveRates();
    double euroRate = double.tryParse(euroRateController.text) ?? 240.0;
    double tlRate = double.tryParse(tlRateController.text) ?? 34.49;
    setState(() {
      if (selectedCurrency == 'TRY') {
        resultInDZD = inputAmount * tlRate;
      } else {
        resultInDZD = inputAmount * euroRate;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("Currency Converter (TRY | EUR > DZD)",
            style:  TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.05,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',

            )
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            DropdownButton<String>(
              value: selectedCurrency,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCurrency = newValue!;
                  _convert(); // Perform conversion with new currency
                });
              },
              items: <String>['TRY', 'Euro']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        'assets/images/${value == "TRY" ? "TRY" : "EUR"}.png', // Selects the correct image
                        width: 20, // Set the image size as needed
                        height: 20,
                      ),
                      const SizedBox(width: 10), // Space between the image and text
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Enter amount in $selectedCurrency'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                inputAmount = double.tryParse(value) ?? 0.0;
                _convert(); // Update result as amount changes
              },
            ),
            TextField(
              controller: tlRateController,
              decoration: const InputDecoration(labelText: 'TL Rate in DZD (1 TL = X DZD)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => _convert(), // Update conveconst rsion on rate change
            ),
            TextField(
              controller: euroRateController,
              decoration: const InputDecoration(labelText: 'Euro Rate in DZD (1 Euro = X DZD)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => _convert(), // Update conversion on rate chanconst ge
            ),
            const SizedBox(height: 25),

            Text('Result in DZD from $selectedCurrency: $resultInDZD', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ,
            const SizedBox(height: 40),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (_exchangeRates.isNotEmpty) ...[
                  const Text(
                    "Current Official Bank Rates :",
                    style: TextStyle(
                      fontSize: 16, // Increasing the font size
                      fontWeight: FontWeight.bold, // Making the text bold
                      color: Colors.blue, // Changing the text color to blue

                      decoration: TextDecoration.underline, // Underlining the text
                      decorationColor: Colors.blue, // Color of the underline
                      decorationStyle: TextDecorationStyle.solid, // Style of the underline
                    ),
                  )
                  ,
                  DataTable(
                    columns: const <DataColumn>[
                      DataColumn(label: Text("Currency")),
                      DataColumn(label: Text("Rate in DZD :")),
                    ],
                    rows: _exchangeRates.entries.map((entry) => DataRow(
                      cells: [
                        DataCell(Row(children: [
                          Image.asset('assets/images/${entry.key}.png', width: 18),
                          Text("  1 ${entry.key}"),
                        ])),
                        DataCell(Row(children: [
                          Image.asset('assets/images/DZD.png', width: 20),
                          Text(
                            '${entry.value.toStringAsFixed(2)} DZD',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold
                            ),

                          ),

                        ])),

                      ],
                    )).toList(),
                  ),
                ] else if (_exchangeRateError != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _exchangeRateError!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                ],
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 50,
        width: double.infinity,
        color: Colors.blueGrey[50],  // Optional: for better visibility
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        alignment: Alignment.center,
        child: Text(
          'Copyright © 2024 Djamel Hemch',  // Update the year and your name accordingly
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
