class OpenLicenseItem {
  const OpenLicenseItem({
    required this.packageName,
    required this.version,
    required this.licenseType,
    required this.licenseText,
  });

  final String packageName;
  final String version;
  final OpenLicenseType licenseType;
  final String licenseText;
}

enum OpenLicenseType {
  mit,
  apache2,
  bsd3,
  bsd2,
  mpl2,
  gpl,
  lgpl,
  isc,
  unknown,
}
