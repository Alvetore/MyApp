// lib/config.dart
import 'package:flutter/material.dart';

/// Ссылки на опубликованные CSV-фиды из Google Sheets
const String devicesCsvUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSlWTqjeCt7HBF1qZ3ZiU_H1u9C5GCE3d8gDpz6_0xcsm1c2g9Tdd_YHniV1-ebItz6qHNasU8jymA2/pub?gid=1857091905&single=true&output=csv';
const String osCsvUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSlWTqjeCt7HBF1qZ3ZiU_H1u9C5GCE3d8gDpz6_0xcsm1c2g9Tdd_YHniV1-ebItz6qHNasU8jymA2/pub?gid=729893579&single=true&output=csv';
const String profilesCsvUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSlWTqjeCt7HBF1qZ3ZiU_H1u9C5GCE3d8gDpz6_0xcsm1c2g9Tdd_YHniV1-ebItz6qHNasU8jymA2/pub?gid=910936657&single=true&output=csv';
const String measurementsCsvUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSlWTqjeCt7HBF1qZ3ZiU_H1u9C5GCE3d8gDpz6_0xcsm1c2g9Tdd_YHniV1-ebItz6qHNasU8jymA2/pub?gid=2027230485&single=true&output=csv';

/// Уведомитель темы приложения. Изменяя значение, перерисовываем MaterialApp.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);