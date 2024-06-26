class User {
  int? id;
  String name;
  String pass;
  String? photo;

  User({this.id, required this.name, required this.pass, this.photo});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': name,
      'password': pass,
      'photo': photo,
    };
  }
}
