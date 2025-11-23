/// Full-screen category management interface for creating, editing, and deleting custom task categories.
/// Displays real-time category list with Firestore persistence and automatic task synchronization.
/// Users can add unlimited custom categories while default categories are protected.
library;

import 'package:flutter/material.dart';

import '../dialogs/app_dialogs.dart';
import '../Service/category_service.dart';
import '../Widgets/Responsive_widget.dart';

/// Full-screen StatefulWidget for managing custom task categories.
class CategoryManagementScreen extends StatefulWidget {
  final CategoryService categoryService;

  const CategoryManagementScreen({super.key, required this.categoryService});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

/// State managing category form input and list display.
class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final TextEditingController _categoryController = TextEditingController();
  String? _editingCategoryName;

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  /// Add a new custom category with validation
  Future<void> _addCategory() async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) {
      await showFloatingBottomDialog(
        context,
        message: 'Category name cannot be empty',
        type: AppMessageType.error,
      );
      return;
    }

    try {
      await widget.categoryService.addCategory(name);
      _categoryController.clear();
      if (mounted) {
        setState(() {});
        await showFloatingBottomDialog(
          context,
          message: 'Category "$name" added successfully',
          type: AppMessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        await showFloatingBottomDialog(
          context,
          message: 'Error: $e',
          type: AppMessageType.error,
        );
      }
    }
  }

  /// Update an existing category name
  Future<void> _updateCategory(String oldName) async {
    final newName = _categoryController.text.trim();
    if (newName.isEmpty) {
      await showFloatingBottomDialog(
        context,
        message: 'Category name cannot be empty',
        type: AppMessageType.error,
      );
      return;
    }

    try {
      await widget.categoryService.updateCategory(oldName, newName);
      _categoryController.clear();
      if (mounted) {
        setState(() => _editingCategoryName = null);
        await showFloatingBottomDialog(
          context,
          message: 'Category updated to "$newName"',
          type: AppMessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        await showFloatingBottomDialog(
          context,
          message: 'Error: $e',
          type: AppMessageType.error,
        );
      }
    }
  }

  /// Delete a category with confirmation dialog
  Future<void> _deleteCategory(String name) async {
    await showConfirmationDialog(
      context,
      title: 'Delete Category',
      message: 'Are you sure you want to delete "$name"? '
          'Tasks using this category will be set to "No Category".',
      confirmButtonLabel: 'Delete',
      cancelButtonLabel: 'Cancel',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          await widget.categoryService.deleteCategory(name);
          if (mounted) {
            setState(() {});
            await showFloatingBottomDialog(
              context,
              message: 'Category "$name" deleted',
              type: AppMessageType.success,
            );
          }
        } catch (e) {
          if (mounted) {
            await showFloatingBottomDialog(
              context,
              message: 'Error: $e',
              type: AppMessageType.error,
            );
          }
        }
      },
    );
  }

  /// Clear all custom categories with confirmation
  Future<void> _clearAllCategories() async {
    await showConfirmationDialog(
      context,
      title: 'Clear All Categories',
      message: 'This will delete all custom categories you have created. '
          'Tasks using these categories will be set to "No Category". '
          'Are you sure?',
      confirmButtonLabel: 'Clear All',
      cancelButtonLabel: 'Cancel',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        try {
          await widget.categoryService.clearAllCategories();
          if (mounted) {
            setState(() {});
            await showFloatingBottomDialog(
              context,
              message: 'All custom categories cleared',
              type: AppMessageType.success,
            );
          }
        } catch (e) {
          if (mounted) {
            await showFloatingBottomDialog(
              context,
              message: 'Error: $e',
              type: AppMessageType.error,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = ResponsiveUtils.getDefaultPadding(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final bodyFontSize = ResponsiveUtils.getBodyFontSize(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Categories',
          style: TextStyle(
            fontSize: titleFontSize,
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: padding.toDouble(),
          vertical: padding.toDouble() * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input section card
            _buildInputCard(theme, bodyFontSize, onSurface, isDark),
            SizedBox(height: padding.toDouble() * 1.5),

            // Categories list section
            _buildCategoriesSection(theme, bodyFontSize, onSurface, isDark),
          ],
        ),
      ),
    );
  }

  /// Build the input card for adding/editing categories
  Widget _buildInputCard(
      ThemeData theme, double bodyFontSize, Color onSurface, bool isDark) {
    final padding = ResponsiveUtils.getCardPadding(context);

    return Container(
      padding: EdgeInsets.all(padding.toDouble()),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getCardBorderRadius(context).toDouble(),
        ),
        border: Border.all(
          color: onSurface.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editingCategoryName != null ? 'Edit Category' : 'Add New Category',
            style: TextStyle(
              fontSize: bodyFontSize * 1.1,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          SizedBox(height: padding.toDouble() * 0.75),
          TextField(
            controller: _categoryController,
            style: TextStyle(color: onSurface, fontSize: bodyFontSize),
            decoration: InputDecoration(
              hintText: 'Enter category name',
              hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.5)),
              filled: true,
              fillColor: isDark
                  ? Colors.grey.shade800.withValues(alpha: 0.5)
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: onSurface.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: onSurface.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
              suffixIcon: _categoryController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _categoryController.clear();
                        setState(() => _editingCategoryName = null);
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: padding.toDouble() * 0.75),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _categoryController.text.isEmpty
                      ? null
                      : () => _editingCategoryName != null
                          ? _updateCategory(_editingCategoryName!)
                          : _addCategory(),
                  icon: Icon(_editingCategoryName != null
                      ? Icons.edit_rounded
                      : Icons.add_rounded),
                  label: Text(
                    _editingCategoryName != null
                        ? 'Update Category'
                        : 'Add Category',
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (_editingCategoryName != null) ...[
                SizedBox(width: padding.toDouble() * 0.5),
                ElevatedButton.icon(
                  onPressed: () {
                    _categoryController.clear();
                    setState(() => _editingCategoryName = null);
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build the categories list section
  Widget _buildCategoriesSection(
      ThemeData theme, double bodyFontSize, Color onSurface, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Categories',
          style: TextStyle(
            fontSize: bodyFontSize * 1.1,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getColumnSpacing(context) * 0.5),
        StreamBuilder<List<String>>(
          stream: widget.categoryService.getUserCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            }

            final allCategories = snapshot.data ?? [];
            final customCategories = allCategories
                .where((cat) => CategoryService.isCustomCategory(cat))
                .toList();

            // Show default categories as info
            final defaultCategories = allCategories
                .where((cat) => !CategoryService.isCustomCategory(cat))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom categories
                if (customCategories.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    alignment: Alignment.center,
                    child: Text(
                      'No custom categories yet. Add one to get started!',
                      style: TextStyle(
                        fontSize: bodyFontSize * 0.9,
                        color: onSurface.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: customCategories.length,
                        itemBuilder: (context, index) {
                          final category = customCategories[index];
                          return _buildCategoryTile(
                            category,
                            theme,
                            bodyFontSize,
                            onSurface,
                            isDark,
                          );
                        },
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getColumnSpacing(context) * 0.5),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _clearAllCategories,
                          icon: const Icon(Icons.delete_sweep_rounded),
                          label: const Text('Clear All Categories'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: ResponsiveUtils.getColumnSpacing(context)),
                Divider(color: onSurface.withValues(alpha: 0.2)),
                SizedBox(
                    height: ResponsiveUtils.getColumnSpacing(context) * 0.75),
                // Default categories info
                Text(
                  'Default Categories (Protected)',
                  style: TextStyle(
                    fontSize: bodyFontSize * 0.95,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(
                    height: ResponsiveUtils.getColumnSpacing(context) * 0.5),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: defaultCategories
                      .map(
                        (cat) => Chip(
                          label: Text(
                            cat,
                            style: TextStyle(fontSize: bodyFontSize * 0.9),
                          ),
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Build a single category list tile with edit/delete options
  Widget _buildCategoryTile(
    String category,
    ThemeData theme,
    double bodyFontSize,
    Color onSurface,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.grey.shade800.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        title: Text(
          category,
          style: TextStyle(
            fontSize: bodyFontSize,
            fontWeight: FontWeight.w500,
            color: onSurface,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: theme.colorScheme.primary,
                size: ResponsiveUtils.getIconSize(context) * 0.9,
              ),
              onPressed: () {
                _categoryController.text = category;
                setState(() => _editingCategoryName = category);
              },
              tooltip: 'Edit category',
            ),
            IconButton(
              icon: Icon(
                Icons.delete_rounded,
                color: Colors.red.shade400,
                size: ResponsiveUtils.getIconSize(context) * 0.9,
              ),
              onPressed: () => _deleteCategory(category),
              tooltip: 'Delete category',
            ),
          ],
        ),
      ),
    );
  }
}
