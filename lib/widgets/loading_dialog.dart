import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog(this.future, {super.key});
  final Future future;

  Future<T?> show<T>(BuildContext context) async {
    return await showDialog<T>(
      barrierDismissible: false,
      context: context,
      builder: (context) => this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop(snapshot.data);
          });
        }
        return const AlertDialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          content: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
        );
      },
    );
  }
}
