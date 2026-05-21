class Supplier {
  final String id;
  final String name;
  final String email;

  Supplier({
    required this.id,
    required this.name,
    required this.email,
  });

  static List<Supplier> get defaultSuppliers => [
    Supplier(id: 'sup1', name: 'Meyve Dünyası', email: 'meyve@tedarikci.com'),
    Supplier(id: 'sup2', name: 'Et ve Süt Kurumu', email: 'et-sut@tedarikci.com'),
    Supplier(id: 'sup3', name: 'Unlu Mamüller A.Ş.', email: 'unlu@tedarikci.com'),
  ];
}
