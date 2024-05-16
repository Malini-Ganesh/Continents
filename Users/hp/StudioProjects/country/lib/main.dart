import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Continent Overview',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CountryExplorer(),
    );
  }
}

class CountryExplorer extends StatefulWidget {
  @override
  _CountryExplorerState createState() => _CountryExplorerState();
}

class _CountryExplorerState extends State<CountryExplorer> {
  late Future<List<Map<String, dynamic>>> countriesData;
  String? selectedSubregion;
  String? selectedSortingOption;
  TextEditingController searchController = TextEditingController(); // Add this line

  @override
  void initState() {
    super.initState();
    countriesData = fetchCountriesData();
  }

  Future<List<Map<String, dynamic>>> fetchCountriesData() async {
    try {
      final response = await http.get(Uri.parse('https://restcountries.com/v3.1/all'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((country) => country as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load country data: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to load country data: $e');
    }
  }

  Map<String, List<Map<String, dynamic>>> categorizeByContinent(List<Map<String, dynamic>> countries) {
    Map<String, List<Map<String, dynamic>>> categorized = {};

    for (var country in countries) {
      String continent = country['region'];
      if (!categorized.containsKey(continent)) {
        categorized[continent] = [];
      }
      categorized[continent]!.add(country);
    }

    return categorized;
  }

  List<Map<String, dynamic>> filterBySubregion(List<Map<String, dynamic>> countries, String? subregion) {
    if (subregion == null || subregion.isEmpty) {
      return countries;
    }
    return countries.where((country) => country['subregion'] == subregion).toList();
  }

  List<Map<String, dynamic>> sortCountries(List<Map<String, dynamic>> countries, String? sortingOption) {
    if (sortingOption == null || sortingOption.isEmpty) {
      return countries;
    }
    switch (sortingOption) {
      case 'name':
        countries.sort((a, b) => a['name']['common'].compareTo(b['name']['common']));
        break;
      case 'population':
        countries.sort((a, b) => b['population'].compareTo(a['population']));
        break;
    }
    return countries;
  }

  void _navigateToCountryDetail(BuildContext context, Map<String, dynamic> country) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CountryDetailScreen(country: country),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:   Color(0xFFDE7E5D),
        title: Text('Country Overview',style: TextStyle(fontWeight: FontWeight.w300,color: Colors.white),),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh,color: Colors.white,),
            onPressed: () {
              setState(() {
                countriesData = fetchCountriesData();
              });
            },
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Sort by Name'),
                value: 'name',
              ),
              PopupMenuItem(
                child: Text('Sort by Population'),
                value: 'population',
              ),
            ],
            onSelected: (value) {
              setState(() {
                selectedSortingOption = value as String?;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by country name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild on text change
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: countriesData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  Map<String, List<Map<String, dynamic>>> categorizedCountries = categorizeByContinent(snapshot.data!);
                  return ListView.builder(
                    itemCount: categorizedCountries.length,
                    itemBuilder: (context, index) {
                      String continent = categorizedCountries.keys.elementAt(index);
                      List<Map<String, dynamic>> countries = filterBySubregion(categorizedCountries[continent]!, selectedSubregion);
                      countries = sortCountries(countries, selectedSortingOption);
                      // Apply search filter
                      String searchText = searchController.text.toLowerCase();
                      if (searchText.isNotEmpty) {
                        countries = countries.where((country) => country['name']['common'].toLowerCase().contains(searchText)).toList();
                      }
                      return ExpansionTile(
                        title: Text(continent),
                        children: countries.map((country) {
                          return ListTile(
                            onTap: () => _navigateToCountryDetail(context, country),
                            leading: Image.network(
                              country['flags']['png'],
                              width: 50,
                              height: 30,
                              fit: BoxFit.cover,
                            ),
                            title: Text(country['name']['common']),
                            subtitle: country['capital'] != null
                                ? Text('Capital: ${country['capital'].join(', ')}\nPopulation: ${country['population']}')
                                : Text('Population: ${country['population']}'),
                          );
                        }).toList(),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CountryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> country;

  const CountryDetailScreen({Key? key, required this.country}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, // Change the color of the leading icon
          ),
        backgroundColor:   const Color(0xFFDE7E5D),
        title: Text(country['name']['common'],style: TextStyle(color: Colors.white),),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Image.network(
                country['flags']['png'],
                width: 100,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capital: ${country['capital'].join(', ')}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Population: ${country['population']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Region: ${country['region']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Subregion: ${country['subregion']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Languages: ${country['languages'].values.join(', ')}',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}