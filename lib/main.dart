
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map/presentation/cubit/map_cubit.dart';
import 'package:map/presentation/map/map.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => MapCubit()..getCurrentLocation(),
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 830),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return MaterialApp(
          home:  MapPage(),
          title: 'MiniPay Wallet',
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
