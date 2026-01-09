import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../domain/open_license_item.dart';

class OpenLicenseService {
  OpenLicenseService();

  Future<List<OpenLicenseItem>> loadLicenses() async {
    if (kDebugMode) {
      debugPrint('[OpenLicense] load:start');
    }

    final entries = await LicenseRegistry.licenses.toList();
    if (kDebugMode) {
      debugPrint('[OpenLicense] licenseRegistry: entries=${entries.length}');
    }

    final licenseMap = <String, String>{};
    for (final entry in entries) {
      final text = entry.paragraphs.map((p) => p.text).join('\n\n');
      for (final package in entry.packages) {
        if (licenseMap.containsKey(package)) {
          licenseMap[package] = '${licenseMap[package]}\n\n$text';
        } else {
          licenseMap[package] = text;
        }
      }
    }

    if (kDebugMode) {
      debugPrint('[OpenLicense] packages: uniqueCount=${licenseMap.length}');
    }

    final versions = await _loadPubspecLockVersions();

    var missingVersionCount = 0;
    var unknownLicenseCount = 0;

    final items = licenseMap.entries.map((entry) {
      final version = versions[entry.key] ?? '';
      if (version.isEmpty) {
        missingVersionCount += 1;
      }
      final licenseType = _inferLicenseType(entry.value);
      if (licenseType == OpenLicenseType.unknown) {
        unknownLicenseCount += 1;
      }
      return OpenLicenseItem(
        packageName: entry.key,
        version: version,
        licenseType: licenseType,
        licenseText: entry.value,
      );
    }).toList()
      ..sort((a, b) => a.packageName.compareTo(b.packageName));

    if (kDebugMode) {
      debugPrint(
        '[OpenLicense] map: itemCount=${items.length}, missingVersionCount=$missingVersionCount, unknownLicenseCount=$unknownLicenseCount',
      );
    }

    return items;
  }

  Future<Map<String, String>> _loadPubspecLockVersions() async {
    try {
      final raw = await rootBundle.loadString('assets/meta/pubspec.lock');
      final doc = loadYaml(raw);
      if (doc is! YamlMap) {
        return {};
      }
      final packages = doc['packages'];
      if (packages is! YamlMap) {
        return {};
      }
      final result = <String, String>{};
      for (final entry in packages.entries) {
        if (entry.value is YamlMap) {
          final value = entry.value as YamlMap;
          final version = value['version'];
          if (version is String) {
            result[entry.key.toString()] = version;
          }
        }
      }
      if (kDebugMode) {
        debugPrint('[OpenLicense] pubspecLock: loaded=true, count=${result.length}');
      }
      return result;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[OpenLicense] pubspecLock: loaded=false, error=$error');
      }
      return {};
    }
  }

  OpenLicenseType _inferLicenseType(String text) {
    final normalized = text.toLowerCase();
    if (normalized.contains('mit license')) {
      return OpenLicenseType.mit;
    }
    if (normalized.contains('apache license') && normalized.contains('version 2')) {
      return OpenLicenseType.apache2;
    }
    if (normalized.contains('bsd 3-clause') ||
        normalized.contains('redistribution and use in source and binary forms') &&
            normalized.contains('neither the name')) {
      return OpenLicenseType.bsd3;
    }
    if (normalized.contains('bsd 2-clause')) {
      return OpenLicenseType.bsd2;
    }
    if (normalized.contains('mozilla public license') && normalized.contains('2.0')) {
      return OpenLicenseType.mpl2;
    }
    if (normalized.contains('gnu general public license')) {
      return OpenLicenseType.gpl;
    }
    if (normalized.contains('gnu lesser general public license')) {
      return OpenLicenseType.lgpl;
    }
    if (normalized.contains('isc license')) {
      return OpenLicenseType.isc;
    }
    return OpenLicenseType.unknown;
  }
}
