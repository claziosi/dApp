import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart'; // Utilisé par web3dart
import 'package:web3dart/web3dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GeoCoordinates DApp')),
        body: const GeoCoordinatesScreen(),
      ),
    );
  }
}

class GeoCoordinatesScreen extends StatefulWidget {
  const GeoCoordinatesScreen({Key? key}) : super(key: key);

  @override
  _GeoCoordinatesScreenState createState() => _GeoCoordinatesScreenState();
}

class _GeoCoordinatesScreenState extends State<GeoCoordinatesScreen> {
  final storage = const FlutterSecureStorage();
  late Web3Client ethClient;
  late String privateKey;

  final String rpcUrl =
      "http://127.0.0.1:7545"; // URL Ganache ou autre node Ethereum

  @override
  void initState() {
    super.initState();
    ethClient = Web3Client(rpcUrl, Client());
    getPrivateKey();
  }

  Future<void> getPrivateKey() async {
    privateKey = await storage.read(key: "private_key") ?? "";

    if (privateKey.isEmpty) {
      // Stocker la clé privée sécurisée via une interface utilisateur ou autre mécanisme sécurisé.
      // Pour cette démonstration, nous allons simuler le stockage d'une clé privée.
      await storage.write(
          key: "private_key",
          value:
              "6b6258db960438ac59fc0b377a194d0ab0ca5a9bf9d6a3a684b5f33929f8e5dd");
      privateKey = await storage.read(key: "private_key") ?? "";
    }
  }

  Future<void> addCoordinate(int latitude, int longitude) async {
    final credentials = EthPrivateKey.fromHex(privateKey);

    // Correctly load and decode the ABI JSON
    String abiStringFile =
        await rootBundle.loadString("src/artifacts/GeoCoordinates.json");
    var jsonAbi = jsonDecode(abiStringFile);
    var abiCode = jsonEncode(jsonAbi["abi"]);

    final contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);

    final contract = DeployedContract(
        ContractAbi.fromJson(abiCode, "GeoCoordinates"), contractAddress);

    final storeFunction = contract.function('addCoordinate');

    await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: storeFunction,
        parameters: [BigInt.from(latitude), BigInt.from(longitude)],
      ),
      chainId: null,
      fetchChainIdFromNetworkId: true,
    );

    print("Coordinate added successfully!");
  }

  Future<List<Map<String, int>>> getAllCoordinates() async {
    // Correctly load and decode the ABI JSON
    String abiStringFile =
        await rootBundle.loadString("src/artifacts/GeoCoordinates.json");
    var jsonAbi = jsonDecode(abiStringFile);
    var abiCode = jsonEncode(jsonAbi["abi"]);

    final contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);

    final contract = DeployedContract(
        ContractAbi.fromJson(abiCode, "GeoCoordinates"), contractAddress);

    final coordinateCountFunction = contract.function('getCoordinatesCount');

    List<dynamic> countResult = await ethClient.call(
      contract: contract,
      function: coordinateCountFunction,
      params: [],
    );

    int count = countResult.first.toInt();

    List<Map<String, int>> coordinatesList = [];

    for (int i = 0; i < count; i++) {
      final coordinateFunction = contract.function('getCoordinate');

      var result = await ethClient.call(
          contract: contract,
          function: coordinateFunction,
          params: [BigInt.from(i)]);

      coordinatesList.add({
        'latitude': result[0].toInt(),
        'longitude': result[1].toInt(),
      });

      // Print the retrieved data
      print(
          "Retrieved Data Index $i : Latitude ${result[0]}, Longitude ${result[1]}");
    }

    return coordinatesList;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(
            onPressed: () async {
              await addCoordinate(67, -167);
            },
            child: const Text('Add Coordinate'),
          ),
          ElevatedButton(
            onPressed: () async {
              List<Map<String, int>> coordinates = await getAllCoordinates();
              print(coordinates);
            },
            child: const Text('Get All Coordinates'),
          ),
        ],
      ),
    );
  }
}
