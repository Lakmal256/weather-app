part of 'weather_bloc.dart';

class WeatherEvent {
  List<Object> get props => [];
}

class FetchWeather extends WeatherEvent{
  final Position position;

  FetchWeather(this.position);
  @override
  List<Object> get props => [position];
}