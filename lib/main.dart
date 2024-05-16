import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

Map<String, Color> palette = {
  'darkGray': const Color(0xFF2a2929),
  'cyan': const Color(0xFF01d8ff),
  'blue': const Color(0xFF7185ff),
  'pink': const Color(0xFFE9399E),
  'darkBackground': const Color(0xFF121212),
  'darkSurface': const Color(0xFF1E1E1E),
  'darkAccent': const Color(0xFFBB86FC),
  'darkText': const Color(0xFFE0E0E0),
  'footer': const Color(0xFF393432)
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define the palette


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const CurrencyConverter(),
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Tomorrow'),
          bodyMedium: TextStyle(fontFamily: 'Tomorrow'),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: palette['darkAccent'],
        scaffoldBackgroundColor: palette['darkBackground'],
        cardColor: palette['darkSurface'],
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Tomorrow',
            color: palette['darkText'],
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Tomorrow',
            color: palette['darkText'],
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: palette['darkText']),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: palette['darkText']!),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: palette['darkAccent']!),
          ),
        ),
        appBarTheme: AppBarTheme(
          color: palette['darkSurface'],
          iconTheme: IconThemeData(color: palette['darkText']),
          titleTextStyle: TextStyle(
            color: palette['darkText'],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(palette['darkAccent']),
          trackColor: WidgetStateProperty.all(palette['darkAccent']!.withOpacity(0.5)),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: TextStyle(color: palette['darkText']),
        ),
        iconTheme: IconThemeData(color: palette['darkText']),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(palette['darkAccent']),
          ),
        ),
      ),
      themeMode: ThemeMode.system, // Use system theme by default, can be changed to ThemeMode.dark for permanent dark mode
    );
  }
}


class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({super.key});

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
  bool _useBankRates = false;  // State to track whether to use bank rates or not

  @override
  void initState() {
    super.initState();
    _loadRates();
    fetchAllExchangeRates();
  }

  Future<Map<String, double>> fetchExchangeRate(String baseCurrency) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('No internet connection (Error Code: 101)');
    }

    var url = Uri.parse('https://v6.exchangerate-api.com/v6/80787f5bde4917f516075748/latest/$baseCurrency');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        Map<String, double> rates = {};
        double dzdRate = data['conversion_rates']['DZD'].toDouble(); // Get only DZD rate
        rates[baseCurrency] = dzdRate;  // Store the rate using the base currency as key

        return rates;
      } else {
        throw Exception('Failed to load exchange rate (Error Code: 102)');
      }
    } catch (e) {
      throw Exception('Failed to call API (Error Code: 103)');
    }
  }


  Map<String, double> _exchangeRates = {};
  // Assuming _exchangeRates already holds EUR rates for each currency
// This method updates your existing rate fetching logic

  Future<void> fetchAllExchangeRates() async {
    List<String> baseCurrencies = ['EUR', 'TRY']; // Currencies for which you need rates to DZD
    Map<String, double> newRates = {};
    try {
      for (String base in baseCurrencies) {
        Map<String, double> rate = await fetchExchangeRate(base);
        newRates.addAll(rate); // This will add both EUR and TRY rates to DZD
      }
      setState(() {
        _exchangeRates = newRates;
        _exchangeRateError = null;
      });
    } catch (e) {
      setState(() {
        _exchangeRates.clear();
        _exchangeRateError = 'Failed to load exchange rates: $e';
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
    await prefs.setDouble('euroRate', double.tryParse(euroRateController.text) ?? 242.0);
    await prefs.setDouble('tlRate', double.tryParse(tlRateController.text) ?? 14.49);
  }
  void _convert() {
    setState(() {
      double rate = 1.0;
      String currencyKey = selectedCurrency == 'Euro' ? 'EUR' : selectedCurrency; // Adjust key name for "Euro"

      if (_useBankRates && _exchangeRates.isNotEmpty) {

        if (_exchangeRates.containsKey(currencyKey)) {
          rate = _exchangeRates[currencyKey]!;
        } else {
          rate = 0.0; // Set to 0 or some default value if the key is not found

        }
      } else {
        // Use manually entered rates
        rate = selectedCurrency == 'TRY' ? double.tryParse(tlRateController.text) ?? 0.0 :
        double.tryParse(euroRateController.text) ?? 0.0;
      }
      resultInDZD = inputAmount * rate;
      resultInDZD = double.parse(resultInDZD.toStringAsFixed(3));

    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title:  Text("TurkDinar Converter",
            style:  Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,

      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<String>(
                  value: selectedCurrency,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCurrency = newValue!;
                      if (_useBankRates) {
                        fetchAllExchangeRates();  // Optionally fetch new rates whenever currency changes
                      }
                      _convert();  // Always recalculate when currency changes
                    });
                  },
                  items: <String>['TRY', 'Euro']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: <Widget>[
                          Image.asset(
                            'assets/images/${value == "TRY" ? "TRY" : "EUR"}.png',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),

                ),
                const SizedBox(width: 10),
                Switch(
                  value: _useBankRates,
                  onChanged: (bool value) {
                    setState(() {
                      _useBankRates = value;
                      if (_useBankRates) {
                        fetchAllExchangeRates();  // Fetch new rates for the current currency
                      }
                      _convert();  // Recalculate using the new rate source
                    });

                  },
                ),
                Text(_useBankRates ? "Using Bank Rates" : "Set Rates Manually"),
              ],
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Enter amount in $selectedCurrency'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                inputAmount = double.tryParse(value) ?? 0.0;
                _convert(); // Update result as amount changes
              },
              style: TextStyle(color: palette['darkText']),
            ),
            TextField(
              enabled: !_useBankRates,
              controller: tlRateController,
              decoration: const InputDecoration(labelText: 'TL Rate in DZD (1 TL = X DZD)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                _convert();
                _saveRates();
              },
              style: TextStyle(color: palette['darkText']),
            ),
            TextField(
              enabled: !_useBankRates,
              controller: euroRateController,
              decoration: const InputDecoration(labelText: 'Euro Rate in DZD (1 Euro = X DZD)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                _convert();
                _saveRates();
              },
              style: TextStyle(color: palette['darkText']),
            ),
            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(8), // Adds padding inside the container
              decoration: BoxDecoration(
                border: Border.all(color: palette['darkAccent']!, width: 2),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, 3), // Position of the shadow
                  ),
                ],
              ),
              child: RichText(
                text: TextSpan(
                  style:  TextStyle(fontSize: 18, color: palette['darkText']), // Default text style
                  children: <TextSpan>[
                    TextSpan(text: 'Amount in DZD from $selectedCurrency: ',
                      style: TextStyle(
                      color: palette['pink'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '$resultInDZD DZD', // Numerical value
                      style:  TextStyle(
                        fontSize: 20, // Larger font size for numerical value
                        fontWeight: FontWeight.bold,
                        color: palette['blue'], // Red color to make the number stand out
                      ),
                    ),
                  ],
                ),
              ),
            )
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
                      )).toList()

                  ),

                  // Add this DataTable widget where it fits in your UI
                  // New DataTable for displaying rates against EUR

                  DataTable(
                    columns: const <DataColumn>[
                      DataColumn(label: Text("Conversion")),
                      DataColumn(label: Text("Rate")),
                    ],
                    rows: [
                      DataRow(
                        cells: [
                          DataCell(Row(
                            children: [
                              Image.asset('assets/images/EUR.png', width: 18),
                              const SizedBox(width: 5),  // Adds space between the image and the text
                              const Text("1 EUR to TRY"),
                            ],
                          )),
                          DataCell(Row(
                            children: [
                              Image.asset('assets/images/TRY.png', width: 18),
                              const SizedBox(width: 5),  // Adds space between the image and the text
                              Text(
                                '${(_exchangeRates['EUR']! / _exchangeRates['TRY']!).toStringAsFixed(4)} TRY',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          )),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Row(
                            children: [
                              Image.asset('assets/images/TRY.png', width: 18),
                              const SizedBox(width: 5),  // Adds space between the image and the text
                              const Text("1 TRY to EUR"),
                            ],
                          )),
                          DataCell(Row(
                            children: [
                              Image.asset('assets/images/EUR.png', width: 18),
                              const SizedBox(width: 5),  // Adds space between the image and the text
                              Text(
                                '${(_exchangeRates['TRY']! / _exchangeRates['EUR']!).toStringAsFixed(4)} EUR',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          )),
                        ],
                      ),
                    ],
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
        color: palette['footer'],  // Optional: for better visibility
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        alignment: Alignment.center,
        child: Text(
          'Copyright © 2024 Djamel Hemch',  // Update the year and your name accordingly
          style: TextStyle(
            fontSize: 12,
            color: palette['darkText'],
          ),
        ),
      ),
    );
  }
}