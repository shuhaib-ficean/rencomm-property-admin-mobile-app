import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class RegisterParams {
  final String name;
  final String email;
  final String password;
  final String? phone;

  RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });
}

@lazySingleton
class RegisterUseCase implements UseCase<User, RegisterParams> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    return await _repository.register(
      params.name,
      params.email,
      params.password,
      params.phone,
    );
  }
}
