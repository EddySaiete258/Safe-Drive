class UserAuth {
  String name;
  String phone;

  UserAuth(this.name, this.phone);

  static toMap(UserAuth user) {
    return {'name': user.name, 'phone': user.phone};
  }

  factory UserAuth.fromMap(Map<String, dynamic> map){
    return UserAuth(map['name'], map['phone']);
  }
}
