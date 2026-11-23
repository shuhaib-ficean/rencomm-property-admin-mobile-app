import 'package:fpdart/fpdart.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> register(String name, String email, String password, String? phone);
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User>> getCurrentUser();
  Future<bool> isAuthenticated();
}
