import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:weather_app/bloc/weather_bloc.dart';
import 'package:weather_app/screens/dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LocationServiceChecker(),
    );
  }
}

class LocationServiceChecker extends StatefulWidget {
  const LocationServiceChecker({super.key});

  @override
  _LocationServiceCheckerState createState() => _LocationServiceCheckerState();
}

class _LocationServiceCheckerState extends State<LocationServiceChecker> {
  late StreamSubscription<bool> _locationServiceStream;
  late StreamSubscription<ConnectivityResult> _connectivityStream;
  bool _isLocationServiceEnabled = false;
  bool _isConnected = false; // Track internet connectivity
  String _error = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Listen for location service changes
    _locationServiceStream = Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => Geolocator.isLocationServiceEnabled())
        .listen((enabled) {
      if (enabled != _isLocationServiceEnabled) {
        setState(() {
          _isLocationServiceEnabled = enabled;
          _error = '';
        });
      }
    });

    // Listen for connectivity changes
    _connectivityStream = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none; // Check if there's any connectivity
      });
    });

    // Initially check for permissions, location service, and internet connectivity
    _checkLocationPermissions();
    _checkInternetConnectivity();
  }

  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled) {
      setState(() {
        _isLocationServiceEnabled = false;
        _error = 'Location services are disabled.';
        _isLoading = false;
      });
    } else if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permissions are denied';
          _isLoading = false;
        });
      } else if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLocationServiceEnabled = true;
          _error = '';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLocationServiceEnabled = true;
        _error = '';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkInternetConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = result != ConnectivityResult.none; // Check initial connectivity
    });
  }

  @override
  void dispose() {
    _locationServiceStream.cancel();
    _connectivityStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isConnected) {
      return Container(
        constraints: const BoxConstraints.expand(),
        color: Colors.black.withOpacity(0.5),
        child: const Material(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                "No Internet Connection",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Please Check Your Connectivity",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isLocationServiceEnabled
        ? FutureBuilder<Position>(
      future: Geolocator.getCurrentPosition(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snap.hasError) {
          return Container(
            constraints: const BoxConstraints.expand(),
            color: Colors.black.withOpacity(0.5),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                      'Error: ${snap.error}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (snap.hasData) {
          return BlocProvider(
            create: (context) => WeatherBloc()..add(FetchWeather(snap.data!)),
            child: const Dashboard(),
          );
        } else {
          return Container(
            constraints: const BoxConstraints.expand(),
            color: Colors.black.withOpacity(0.5),
            child: const Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Unexpected error Occurred!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    )
        : Container(
      constraints: const BoxConstraints.expand(),
      color: Colors.black.withOpacity(0.5),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              _error.isNotEmpty
                  ? 'Please Enable Location Service.'
                  : 'Location Service Is Off.\nPlease Enable It.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}