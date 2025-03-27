import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider extends ChangeNotifier {
  User? _user = Supabase.instance.client.auth.currentUser;
  
  User? get user => _user;
  
  void updateUser(User? newUser) {
    _user = newUser;
    notifyListeners();
  }
}
