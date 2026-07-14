import 'package:flutter/material.dart';

import 'basicTextField.dart';

class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const EmailTextField({
    super.key,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: 'Email',
      hintText: 'example@diu.edu.bd',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.endsWith('@student.diu.edu.bd') &&
            !value.endsWith('@diu.edu.bd')) {
          return 'Please use your university email';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}