import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:io' show Platform;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'BLE Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_isScanning) {
            await FlutterBluePlus.stopScan();
          } else {
            await FlutterBluePlus.startScan();
          }
        },
        tooltip: 'Increment',
        child: StreamBuilder(
            stream: FlutterBluePlus.isScanning,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                throw snapshot.error!;
              }

              if (snapshot.hasData) {
                final isScanning = snapshot.data as bool;
                _isScanning = isScanning;
                return Icon(isScanning ? Icons.stop : Icons.play_arrow);
              }

              return const Icon(Icons.play_arrow);
            }),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget content(BuildContext context) {
    return FutureBuilder(future: Future(() async {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }

      await FlutterBluePlus.adapterState.firstWhere((state) {
        return state == BluetoothAdapterState.on;
      });

      await FlutterBluePlus.startScan();
    }), builder: (context, snapshot) {
      if (snapshot.hasError) {
        throw snapshot.error!;
      }
      return deviceList(context);
    });
  }

  /// List of devices
  Widget deviceList(BuildContext context) {
    return StreamBuilder(
        stream: FlutterBluePlus.scanResults,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            throw snapshot.error!;
          }

          if (snapshot.hasData) {
            final results = snapshot.data as List<ScanResult>;
            if (results.isEmpty) {
              return _noDevicesState(context);
            }
            return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return ListTile(
                    title: Text(result.device.advName),
                    subtitle: Text(result.device.remoteId.str),
                    trailing: Text(result.rssi.toString()),
                  );
                });
          }

          return _noDevicesState(context);
        });
  }

  /// No devices found
  Widget _noDevicesState(BuildContext context) {
    return StreamBuilder(
        stream: FlutterBluePlus.isScanning,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            throw snapshot.error!;
          }

          if (snapshot.hasData) {
            final isScanning = snapshot.data as bool;
            if (isScanning) {
              return const Center(child: CircularProgressIndicator());
            }
          }

          return const Center(child: Text('No devices found'));
        });
  }
}
