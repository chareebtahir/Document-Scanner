import 'package:flutter/material.dart';

import '../services/document_store.dart';

/// Asks for a document name and checks it before closing.
/// Returns the trimmed name, or null when the user cancels.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String initial,
  String confirmLabel = 'Save',
  String? exceptId,
}) {
  final controller = TextEditingController(text: initial);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (context) {
      void submit() {
        if (formKey.currentState!.validate()) {
          Navigator.pop(context, controller.text.trim());
        }
      }

      return AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Document name',
              prefixIcon: Icon(Icons.description_outlined),
            ),
            validator: (v) =>
                DocumentStore.instance.validateName(v, exceptId: exceptId),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: (_) => submit(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(onPressed: submit, child: Text(confirmLabel)),
        ],
      );
    },
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shows a blocking progress dialog while [task] runs.
Future<T?> runWithProgress<T>(
  BuildContext context,
  String message,
  Future<T> Function() task,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  try {
    return await task();
  } catch (e) {
    if (context.mounted) showError(context, e);
    return null;
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showError(BuildContext context, Object error) {
  final text = error.toString().replaceFirst('Exception: ', '');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
}
