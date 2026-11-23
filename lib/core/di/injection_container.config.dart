// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../data/repositories/auth_repository_impl.dart' as _i895;
import '../../data/repositories/repair_repository.dart' as _i15;
import '../../domain/repositories/auth_repository.dart' as _i1073;
import '../../domain/usecases/auth/get_current_user_usecase.dart' as _i408;
import '../../domain/usecases/auth/login_usecase.dart' as _i461;
import '../../domain/usecases/auth/logout_usecase.dart' as _i320;
import '../../domain/usecases/auth/register_usecase.dart' as _i659;
import '../../presentation/blocs/auth/auth_bloc.dart' as _i141;
import '../../presentation/blocs/repair/repair_bloc.dart' as _i249;
import '../network/api_client.dart' as _i557;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
        () => registerModule.secureStorage);
    gh.lazySingleton<_i557.ApiClient>(() => registerModule.apiClient);
    gh.lazySingleton<_i1073.AuthRepository>(
        () => _i895.AuthRepositoryImpl(gh<_i557.ApiClient>()));
    gh.lazySingleton<_i15.RepairRepository>(
        () => _i15.RepairRepository(gh<_i557.ApiClient>()));
    gh.lazySingleton<_i408.GetCurrentUserUseCase>(
        () => _i408.GetCurrentUserUseCase(gh<_i1073.AuthRepository>()));
    gh.lazySingleton<_i461.LoginUseCase>(
        () => _i461.LoginUseCase(gh<_i1073.AuthRepository>()));
    gh.lazySingleton<_i320.LogoutUseCase>(
        () => _i320.LogoutUseCase(gh<_i1073.AuthRepository>()));
    gh.lazySingleton<_i659.RegisterUseCase>(
        () => _i659.RegisterUseCase(gh<_i1073.AuthRepository>()));
    gh.factory<_i249.RepairBloc>(
        () => _i249.RepairBloc(gh<_i15.RepairRepository>()));
    gh.factory<_i141.AuthBloc>(() => _i141.AuthBloc(
          gh<_i461.LoginUseCase>(),
          gh<_i659.RegisterUseCase>(),
          gh<_i320.LogoutUseCase>(),
          gh<_i408.GetCurrentUserUseCase>(),
          gh<_i1073.AuthRepository>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
