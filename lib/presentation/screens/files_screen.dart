import 'package:ai_chat/core/extensions/build_context_extension.dart';
import 'package:ai_chat/core/utils/formatters.dart';
import 'package:ai_chat/core/widgets/app_scaffold.dart';
import 'package:ai_chat/core/widgets/empty_state.dart';
import 'package:ai_chat/core/widgets/error_view.dart';
import 'package:ai_chat/core/widgets/loaders/loading_indicator.dart';
import 'package:ai_chat/presentation/blocs/data_sources.dart';
import 'package:ai_chat/presentation/blocs/files_cubit.dart';
import 'package:ai_chat/presentation/widgets/localized_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// File management screen.
///
/// Self-contained route providing its own [FilesCubit]. Picking a file
/// goes through `file_picker`; upload and deletion are delegated to the
/// cubit, so this widget performs no network or storage work itself.
class FilesScreen extends StatelessWidget {
  /// Creates a [FilesScreen].
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FilesCubit>(
      create: (context) =>
          FilesCubit(repository: buildFileRepository())..load(),
      child: const _FilesView(),
    );
  }
}

class _FilesView extends StatelessWidget {
  const _FilesView();

  Future<void> _pickAndUpload(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    final path = file.path;
    if (path == null || path.isEmpty) {
      if (context.mounted) {
        context.showErrorSnackBar(
          localizedTextRead(
            context,
            'Could not read the selected file.',
            'تعذّرت قراءة الملف المحدد.',
          ),
        );
      }
      return;
    }
    if (context.mounted) {
      context.read<FilesCubit>().upload(filePath: path, fileName: file.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<FilesCubit>();
    final state = cubit.state;

    return AppScaffold(
      appBar: AppBar(title: Text(localizedText(context, 'Files', 'الملفات'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isUploading ? null : () => _pickAndUpload(context),
        icon: state.isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file),
        label: Text(localizedText(context, 'Upload', 'رفع')),
      ),
      body: _buildContent(context, cubit, state),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FilesCubit cubit,
    FilesState state,
  ) {
    if (state.isLoading && state.files.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null && state.files.isEmpty) {
      return ErrorView(description: state.error, onRetry: cubit.load);
    }

    if (state.files.isEmpty) {
      return EmptyState(
        variant: EmptyStateVariant.custom,
        icon: Icons.folder_open,
        title: localizedText(context, 'No files yet', 'لا توجد ملفات بعد'),
        description: localizedText(
          context,
          'Upload a file to make it available in your chats.',
          'ارفع ملفاً ليتوفر في محادثاتك.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.files.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final file = state.files[index];
        return ListTile(
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(
            file.name.isEmpty
                ? localizedText(context, 'File', 'ملف')
                : file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(Formatters.formatFileSize(file.size)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: localizedText(context, 'Delete', 'حذف'),
            onPressed: file.id.isEmpty ? null : () => cubit.delete(file.id),
          ),
        );
      },
    );
  }
}
