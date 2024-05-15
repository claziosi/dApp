import 'dart:convert';

import 'package:dart_web3/dart_web3.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web_socket_channel/io.dart';

class ContractLinking extends ChangeNotifier {
  final String _rpcURl = "http://127.0.0.1:7545";
  final String _wsURl = "ws://127.0.0.1:7545/";
  final String _privateKey =
      "6b6258db960438ac59fc0b377a194d0ab0ca5a9bf9d6a3a684b5f33929f8e5dd";

  late Web3Client _client;
  late String _abiCode;

  late EthereumAddress _contractAddress;
  late Credentials _credentials;

  late DeployedContract _contract;
  late ContractFunction _yourName;
  late ContractFunction _setName;

  bool isLoading = true;
  String deployedName = "";

  ContractLinking() {
    initialSetup();
  }

  initialSetup() async {
    // establish a connection to the ethereum rpc node. The socketConnector
    // property allows more efficient event streams over websocket instead of
    // http-polls. However, the socketConnector property is experimental.
    _client = Web3Client(_rpcURl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsURl).cast<String>();
    });

    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    // Reading the contract abi
    String abiStringFile =
        await rootBundle.loadString("src/artifacts/StoreLocation.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    // print(_abiCode);

    _contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
    // print(_contractAddress);
  }

  Future<void> getCredentials() async {
    _credentials = EthPrivateKey.fromHex(_privateKey);
    // print(_credentials);
  }

  Future<void> getDeployedContract() async {
    // Telling Web3dart where our contract is declared.
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode, "HelloWorld"), _contractAddress);

    // Extracting the functions, declared in contract.
    _yourName = _contract.function("yourName");
    _setName = _contract.function("setName");
    getName();
  }

  Future<void> getName() async {
    // Getting the current name declared in the smart contract.
    var currentName = await _client
        .call(contract: _contract, function: _yourName, params: []);
    // print(currentName);
    deployedName = currentName[0];
    isLoading = false;
    notifyListeners();
  }

  Future<void> setName(String nameToSet) async {
    // Setting the name to nameToSet(name defined by user)
    isLoading = true;
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _setName,
          parameters: [nameToSet],
          // gasPrice: EtherAmount.inWei(BigInt.one),
          // maxGas: 100000,
          // value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 1),
        ));
    getName();
  }
}
