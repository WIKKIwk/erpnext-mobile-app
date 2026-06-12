import 'dart:async';
import 'dart:io';

import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/customer/customer_priority.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../../werka/presentation/widgets/m3_picker_sheet.dart';
import '../models/production_map_models.dart';
import '../state/calculate_order_store.dart';
import 'calculate_product_picker_loader.dart';
import '../logic/production_map_pechat_rules.dart';
import 'admin_production_map_test_screen.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_navigation_drawer.dart';
import 'widgets/admin_top_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class AdminCalculateScreen extends StatefulWidget {
  const AdminCalculateScreen({
    super.key,
    this.template,
  });

  final CalculateOrderTemplate? template;

  @override
  State<AdminCalculateScreen> createState() => _AdminCalculateScreenState();
}

class _AdminCalculateScreenState extends State<AdminCalculateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _customer = TextEditingController();
  final _product = TextEditingController();
  final _status = TextEditingController();
  final _kg = TextEditingController();
  final _widthMm = TextEditingController();
  final _wastePercent = TextEditingController(text: '5');
  final _rollCount = TextEditingController();
  final _firstMaterial = TextEditingController();
  final _firstMicron = TextEditingController();
  final _secondMaterial = TextEditingController();
  final _secondMicron = TextEditingController();
  final _thirdMaterial = TextEditingController();
  final _thirdMicron = TextEditingController();
  final _note = TextEditingController();

  String _customerRef = '';
  String _itemCode = '';
  String _templateId = '';
  String _orderCode = '';
  String _sourceMapId = '';
  int _productCustomerGeneration = 0;
  bool _openingRoute = false;
  bool _calculating = false;
  bool _openingSavedOrder = false;
  bool _uploadingImage = false;
  bool _editingAllFields = true;
  bool _applyingTemplate = false;
  String _imageId = '';
  String _imageName = '';
  String _imageMime = '';
  String _imageUrl = '';
  String _imageLocalPath = '';
  int _imageSizeBytes = 0;
  CalculateResponse? _result;
  String _lastCalculatedSignature = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _editingAllFields = widget.template == null;
    _applyTemplate(widget.template);
    for (final controller in _calculationInputControllers) {
      controller.addListener(_handleCalculationInputChanged);
    }
    unawaited(_warmQuickOrderTemplates());
  }

  @override
  void dispose() {
    for (final controller in _calculationInputControllers) {
      controller.removeListener(_handleCalculationInputChanged);
    }
    _customer.dispose();
    _product.dispose();
    _status.dispose();
    _kg.dispose();
    _widthMm.dispose();
    _wastePercent.dispose();
    _rollCount.dispose();
    _firstMaterial.dispose();
    _firstMicron.dispose();
    _secondMaterial.dispose();
    _secondMicron.dispose();
    _thirdMaterial.dispose();
    _thirdMicron.dispose();
    _note.dispose();
    super.dispose();
  }

  List<TextEditingController> get _calculationInputControllers => [
        _product,
        _kg,
        _widthMm,
        _wastePercent,
        _rollCount,
        _firstMaterial,
        _firstMicron,
        _secondMaterial,
        _secondMicron,
        _thirdMaterial,
        _thirdMicron,
      ];

  void _handleCalculationInputChanged() {
    if (_applyingTemplate || !mounted) {
      return;
    }
    if (_result == null && _lastCalculatedSignature.isEmpty) {
      return;
    }
    setState(() {});
  }

  void _applyTemplate(CalculateOrderTemplate? template) {
    if (template == null) {
      return;
    }
    _applyingTemplate = true;
    try {
      _templateId = template.id;
      _orderCode = template.code;
      _sourceMapId = template.sourceMapId;
      _customerRef = template.customerRef;
      _customer.text = template.customer;
      _itemCode = template.itemCode;
      _product.text = template.product;
      _status.text = template.status;
      _imageId = template.imageId;
      _imageName = template.imageName;
      _imageMime = template.imageMime;
      _imageSizeBytes = template.imageSizeBytes;
      _imageUrl = template.imageUrl;
      _imageLocalPath = '';
      _kg.clear();
      _widthMm.text = _fmtInput(template.widthMm);
      _wastePercent.text = _fmtInput(template.wastePercent);
      _rollCount.text =
          template.rollCount == null ? '' : _fmtInput(template.rollCount!);
      _firstMaterial.text = template.firstLayerMaterial;
      _firstMicron.text = template.firstLayerMicron;
      _secondMaterial.text = template.secondLayerMaterial;
      _secondMicron.text = template.secondLayerMicron;
      _thirdMaterial.text = template.thirdLayerMaterial;
      _thirdMicron.text = template.thirdLayerMicron;
      _note.text = template.note;
      _result = null;
      _lastCalculatedSignature = '';
    } finally {
      _applyingTemplate = false;
    }
  }

  Future<void> _warmQuickOrderTemplates() async {
    try {
      await CalculateOrderTemplateStore.instance.load();
    } catch (_) {
      return;
    }
  }

  void _openDrawerRoute(String routeName) {
    if (_openingRoute) {
      return;
    }
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) {
      return;
    }
    _openingRoute = true;
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  Future<void> _openOrders() async {
    await Navigator.of(context).pushNamed(AppRoutes.adminCalculateOrders);
  }

  Future<void> _openProductionMap() async {
    if (!_hasFreshCalculation) {
      showAdminTopNotice(context, 'Avval hisoblash tugmasini bosing');
      return;
    }
    final error = _templateValidationError();
    if (error != null) {
      showAdminTopNotice(context, error);
      return;
    }
    if (!mounted) {
      return;
    }
    final orderContext = _buildProductionMapOrderContext();
    final sourceMapId = _sourceMapId.trim();
    ProductionMapDefinition? savedMap;
    if (sourceMapId.isNotEmpty) {
      try {
        final source = await MobileApi.instance.adminProductionMap(sourceMapId);
        final cleanSourceMap = source.map.withoutAlternativeAssignments();
        savedMap = cleanSourceMap.copyWith(
          title: _resolvedOrderName(),
          productCode: _itemCode.trim().isNotEmpty
              ? _itemCode.trim()
              : cleanSourceMap.productCode,
          rollCount: _parseOptionalDouble(_rollCount.text),
          widthMm: _parseOptionalDouble(_widthMm.text),
        );
      } catch (_) {
        if (mounted) {
          showAdminTopNotice(context, 'Tezkor zakaz mapini yuklab bo‘lmadi');
        }
        return;
      }
    }
    if (!mounted) {
      return;
    }
    final saved = await Navigator.of(context).pushNamed(
      AppRoutes.adminProductionMapTest,
      arguments: savedMap == null
          ? orderContext
          : ProductionMapTestArgs(
              orderContext: orderContext,
              savedMap: savedMap,
            ),
    );
    if (!mounted || saved is! CalculateOrderTemplate) {
      return;
    }
    setState(() {
      _applyTemplate(saved);
      _editingAllFields = false;
    });
  }

  ProductionMapOrderContext _buildProductionMapOrderContext() {
    return ProductionMapOrderContext(
      templateId: _templateId,
      orderCode: _orderCode,
      orderName: _resolvedOrderName(),
      productName: _product.text,
      itemCode: _itemCode,
      rollCount: _parseOptionalDouble(_rollCount.text),
      widthMm: _parseOptionalDouble(_widthMm.text),
      templateDraft: _buildTemplateDraft(),
    );
  }

  Future<void> _openOrderFromSavedMap() async {
    if (_openingSavedOrder) {
      return;
    }
    if (!_hasFreshCalculation) {
      showAdminTopNotice(context, 'Avval hisoblash tugmasini bosing');
      return;
    }
    final sourceMapId = _sourceMapId.trim();
    if (sourceMapId.isEmpty) {
      showAdminTopNotice(context, 'Bu tezkor zakazga map ulanmagan');
      return;
    }
    final error = _templateValidationError();
    if (error != null) {
      showAdminTopNotice(context, error);
      return;
    }
    final orderNumber = await showProductionMapOrderNumberSheet(context);
    if (!mounted || orderNumber == null) {
      return;
    }
    setState(() => _openingSavedOrder = true);
    try {
      final source = await MobileApi.instance.adminProductionMap(sourceMapId);
      final sourceMap = source.map.withoutAlternativeAssignments();
      final normalizedOrder = orderNumber.trim();
      final clonedMap = sourceMap.copyWith(
        id: 'zakaz-$normalizedOrder',
        title: _resolvedOrderName(),
        code: normalizedOrder,
        orderNumber: normalizedOrder,
        productCode: _itemCode.trim().isNotEmpty
            ? _itemCode.trim()
            : sourceMap.productCode,
        rollCount: _parseOptionalDouble(_rollCount.text),
        widthMm: _parseOptionalDouble(_widthMm.text),
      );
      final draft = _buildTemplateDraft().copyWith(
        id: '',
        code: normalizedOrder,
        orderNumber: normalizedOrder,
        kg: _parseRequiredDouble(_kg.text),
        sourceMapId: sourceMapId,
      );
      final result = await MobileApi.instance.adminSaveProductionMapWithOrder(
        map: clonedMap,
        template: draft,
      );
      if (!mounted) {
        return;
      }
      final savedTemplate = result.template;
      if (savedTemplate != null) {
        CalculateOrderTemplateStore.instance.remember(savedTemplate);
      }
      showAdminTopNotice(context, 'Zakaz ochildi: $normalizedOrder');
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAdminTopNotice(
        context,
        error is MobileApiException ? error.message : 'Zakaz ochilmadi',
      );
    } finally {
      if (mounted) {
        setState(() => _openingSavedOrder = false);
      }
    }
  }

  bool _hasExistingQuickOrderForProduct(SupplierItem product) {
    final productKeys = {
      product.code,
      product.name,
    }.map(_normalizeProductMapKey).where((key) => key.isNotEmpty).toSet();
    if (productKeys.isEmpty) {
      return false;
    }
    final currentTemplateId = _templateId.trim();
    final templates = CalculateOrderTemplateStore.instance.templates;
    return templates.any((template) {
      if (currentTemplateId.isNotEmpty &&
          template.id.trim() == currentTemplateId) {
        return false;
      }
      final templateKeys = {
        template.itemCode,
        template.product,
        template.name,
        template.code,
      }.map(_normalizeProductMapKey).where((key) => key.isNotEmpty);
      return templateKeys.any(productKeys.contains);
    });
  }

  Future<bool?> _confirmQuickOrderRecreate() {
    return showDialog<bool>(
      context: context,
      builder: (context) => const _QuickOrderRecreateDialog(),
    );
  }

  CalculateOrderTemplate _buildTemplateDraft() {
    return CalculateOrderTemplate(
      id: _templateId,
      code: _orderCode,
      name: _resolvedOrderName(),
      savedAt: DateTime.now().toUtc(),
      orderNumber: '',
      customerRef: _customerRef,
      customer: _customer.text.trim(),
      itemCode: _itemCode,
      product: _product.text.trim(),
      status: _status.text.trim(),
      materialDisplay: '',
      color: '',
      imageId: _imageId,
      imageName: _imageName,
      imageMime: _imageMime,
      imageSizeBytes: _imageSizeBytes,
      imageUrl: _imageUrl,
      widthMm: _parseRequiredDouble(_widthMm.text),
      wastePercent: _parseRequiredDouble(_wastePercent.text),
      rollCount: _parseOptionalDouble(_rollCount.text),
      firstLayerMaterial: _firstMaterial.text.trim(),
      firstLayerMicron: _firstMicron.text.trim(),
      secondLayerMaterial: _secondMaterial.text.trim(),
      secondLayerMicron: _secondMicron.text.trim(),
      thirdLayerMaterial: _thirdMaterial.text.trim(),
      thirdLayerMicron: _thirdMicron.text.trim(),
      note: _note.text.trim(),
      kg: _kg.text.trim().isEmpty ? 0 : _parseRequiredDouble(_kg.text),
      sourceMapId: _sourceMapId,
    );
  }

  Future<void> _openCustomerPicker() async {
    final picked = await showModalBottomSheet<CustomerDirectoryEntry>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3AsyncPickerSheet<CustomerDirectoryEntry>(
          title: 'Mijoz tanlang',
          hintText: 'Mijoz qidiring',
          pageSize: 50,
          cacheKey: 'calculate:customers',
          loadPage: (query, offset, limit) {
            return MobileApi.instance.adminCustomers(
              query: query,
              offset: offset,
              limit: limit,
            );
          },
          itemTitle: (item) => item.name.trim().isEmpty ? item.ref : item.name,
          itemSubtitle: (item) {
            final phone = item.phone.trim();
            return phone.isEmpty ? item.ref : '${item.ref} • $phone';
          },
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _productCustomerGeneration++;
      _customerRef = picked.ref;
      _customer.text =
          picked.name.trim().isEmpty ? picked.ref : picked.name.trim();
      _itemCode = '';
      _product.clear();
    });
  }

  Future<void> _openProductPicker() async {
    final picked = await showModalBottomSheet<SupplierItem>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3AsyncPickerSheet<SupplierItem>(
          title: 'Mahsulot tanlang',
          hintText: 'Mahsulot qidiring',
          pageSize: 80,
          supportingText:
              _customer.text.trim().isEmpty ? null : _customer.text.trim(),
          cacheKey: _customerRef.trim().isEmpty
              ? 'calculate:items'
              : 'calculate:customer-items:${_customerRef.trim()}',
          loadPage: (query, offset, limit) {
            return loadCalculateProductPickerPage(
              customerRef: _customerRef,
              query: query,
              offset: offset,
              limit: limit,
              customerDetail: MobileApi.instance.adminCustomerDetail,
              allItems: MobileApi.instance.gscaleItemsPage,
            );
          },
          itemTitle: (item) => item.name.trim().isEmpty ? item.code : item.name,
          itemSubtitle: (item) => item.code,
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    if (_hasExistingQuickOrderForProduct(picked)) {
      if (!mounted) {
        return;
      }
      final recreate = await _confirmQuickOrderRecreate();
      if (!mounted || recreate != true) {
        return;
      }
    }
    if (!mounted) {
      return;
    }
    final shouldAutoSelectCustomer =
        _customerRef.trim().isEmpty && _customer.text.trim().isEmpty;
    final generation = _productCustomerGeneration + 1;
    setState(() {
      _productCustomerGeneration = generation;
      _itemCode = picked.code;
      _product.text =
          picked.name.trim().isEmpty ? picked.code : picked.name.trim();
    });
    if (shouldAutoSelectCustomer) {
      unawaited(_autoSelectCustomerForProduct(picked, generation));
    }
  }

  Future<void> _autoSelectCustomerForProduct(
    SupplierItem product,
    int generation,
  ) async {
    try {
      final customers = await MobileApi.instance.adminCustomersForItem(
        itemCode: product.code,
        itemName: product.name,
        limit: 200,
        offset: 0,
      );
      final customer = preferPrimaryCustomer<CustomerDirectoryEntry>(
        customers.where((item) => item.ref.trim().isNotEmpty),
        customerName: (item) => item.name,
      );
      if (!mounted ||
          generation != _productCustomerGeneration ||
          customer == null ||
          _customerRef.trim().isNotEmpty ||
          _customer.text.trim().isNotEmpty) {
        return;
      }
      setState(() {
        _customerRef = customer.ref;
        _customer.text =
            customer.name.trim().isEmpty ? customer.ref : customer.name.trim();
      });
    } catch (_) {
      return;
    }
  }

  String _resolvedOrderName() {
    final product = _product.text.trim();
    return product.isEmpty ? 'Zakaz' : product;
  }

  String? _templateValidationError() {
    final checks = <String?>[
      _requiredText(_product.text),
      _requiredPositiveNumber(_widthMm.text),
      _requiredNonNegativeNumber(_wastePercent.text),
      _requiredText(_firstMaterial.text),
      _requiredPositiveNumber(_firstMicron.text),
      _requiredText(_secondMaterial.text),
      _requiredPositiveNumber(_secondMicron.text),
      _optionalPositiveInteger(_rollCount.text),
    ];
    if (checks.any((error) => error != null)) {
      return 'Zakaz ma’lumotlarini to‘ldiring';
    }
    return null;
  }

  Future<void> _calculate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_product.text.trim().isEmpty) {
      showAdminTopNotice(context, 'Mahsulot tanlang');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      showAdminTopNotice(context, 'Majburiy maydonlarni to‘ldiring');
      return;
    }
    setState(() {
      _calculating = true;
      _error = '';
    });
    try {
      final result = await MobileApi.instance.calculate(
        CalculateRequest(
          orderNumber: '',
          customer: _customer.text,
          product: _product.text,
          status: _status.text,
          materialDisplay: '',
          color: '',
          kg: _parseRequiredDouble(_kg.text),
          widthMm: _parseRequiredDouble(_widthMm.text),
          wastePercent: _parseRequiredDouble(_wastePercent.text),
          rollCount: _parseOptionalDouble(_rollCount.text),
          firstLayer: CalculateLayerInput(
            material: _firstMaterial.text,
            micron: _firstMicron.text,
          ),
          secondLayer: CalculateLayerInput(
            material: _secondMaterial.text,
            micron: _secondMicron.text,
          ),
          thirdLayer: CalculateLayerInput(
            material: _thirdMaterial.text,
            micron: _thirdMicron.text,
          ),
          note: _note.text,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _lastCalculatedSignature = _calculationSignature();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error is MobileApiException ? error.message : error.toString();
        _result = null;
        _lastCalculatedSignature = '';
      });
      showAdminTopNotice(context, 'Hisoblashda xatolik');
    } finally {
      if (mounted) {
        setState(() => _calculating = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 84,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _uploadingImage = true;
      _imageLocalPath = picked.path;
      _error = '';
    });
    try {
      final image = await MobileApi.instance.uploadCalculateOrderImage(
        bytes: await picked.readAsBytes(),
        filename: picked.name,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _imageId = image.imageId;
        _imageName = image.imageName;
        _imageMime = image.imageMime;
        _imageSizeBytes = image.imageSizeBytes;
        _imageUrl = image.imageUrl;
        _imageLocalPath = '';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _imageLocalPath = '';
        _error = error is MobileApiException ? error.message : error.toString();
      });
      showAdminTopNotice(context, 'Rasm yuklashda xatolik');
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  void _clearImage() {
    setState(() {
      _imageId = '';
      _imageName = '';
      _imageMime = '';
      _imageSizeBytes = 0;
      _imageUrl = '';
      _imageLocalPath = '';
    });
  }

  void _enableFullEdit() {
    setState(() {
      _editingAllFields = true;
    });
  }

  List<Widget> _fullEditChildren() {
    return [
      const _SectionHeader(title: 'Buyurtma'),
      _PickerInput(
        label: 'Mijoz',
        value: _customer.text,
        subtitle: _customerRef,
        onTap: _openCustomerPicker,
      ),
      _PickerInput(
        label: 'Mahsulot',
        value: _product.text,
        subtitle: _itemCode,
        required: true,
        onTap: _openProductPicker,
      ),
      _TextInput(
        controller: _status,
        label: 'Status',
      ),
      _ImageUploadInput(
        localPath: _imageLocalPath,
        imageUrl: _imageUrl,
        imageName: _imageName,
        imageSizeBytes: _imageSizeBytes,
        uploading: _uploadingImage,
        onPick: _pickImage,
        onClear: _clearImage,
      ),
      const SizedBox(height: 18),
      const _SectionHeader(title: 'Hisob'),
      _NumberInput(
        controller: _kg,
        label: 'KG',
        suffixText: 'kg',
        required: true,
      ),
      _NumberInput(
        controller: _widthMm,
        label: 'Razmer',
        suffixText: 'mm',
        required: true,
      ),
      _NumberInput(
        controller: _wastePercent,
        label: 'Atxod foiz',
        suffixText: '%',
        required: true,
        allowZero: true,
      ),
      _IntegerInput(
        controller: _rollCount,
        label: 'Val soni',
        suffixText: 'ta',
      ),
      const SizedBox(height: 18),
      const _SectionHeader(title: 'Qavatlar'),
      _LayerInputs(
        material: _firstMaterial,
        micron: _firstMicron,
        materialLabel: '1-qavat',
        required: true,
      ),
      _LayerInputs(
        material: _secondMaterial,
        micron: _secondMicron,
        materialLabel: '2-qavat',
        required: true,
      ),
      _LayerInputs(
        material: _thirdMaterial,
        micron: _thirdMicron,
        materialLabel: '3-qavat',
      ),
      const SizedBox(height: 18),
      _TextInput(
        controller: _note,
        label: 'Izoh',
        minLines: 3,
        maxLines: 5,
      ),
      ..._calculateActionChildren(),
    ];
  }

  List<Widget> _compactTemplateChildren() {
    return [
      _SavedTemplateSummary(
        title: _resolvedOrderName(),
        customer: _customer.text,
        customerRef: _customerRef,
        product: _product.text,
        itemCode: _itemCode,
        status: _status.text,
        imageUrl: _imageUrl,
        imageName: _imageName,
        imageSizeBytes: _imageSizeBytes,
        widthMm: _widthMm.text,
        rollCount: _rollCount.text,
        firstLayerMaterial: _firstMaterial.text,
        firstLayerMicron: _firstMicron.text,
        secondLayerMaterial: _secondMaterial.text,
        secondLayerMicron: _secondMicron.text,
        thirdLayerMaterial: _thirdMaterial.text,
        thirdLayerMicron: _thirdMicron.text,
        note: _note.text,
      ),
      const SizedBox(height: 18),
      const _SectionHeader(title: 'Hisob'),
      _NumberInput(
        controller: _kg,
        label: 'KG',
        suffixText: 'kg',
        required: true,
      ),
      _NumberInput(
        controller: _wastePercent,
        label: 'Atxod foiz',
        suffixText: '%',
        required: true,
        allowZero: true,
      ),
      ..._calculateActionChildren(),
    ];
  }

  List<Widget> _calculateActionChildren() {
    final freshResult = _hasFreshCalculation ? _result : null;
    return [
      const SizedBox(height: 22),
      FilledButton.icon(
        onPressed: _calculating ? null : _calculate,
        icon: const Icon(Icons.calculate_outlined),
        label: Text(_calculating ? 'Hisoblanmoqda...' : 'Hisoblash'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      if (_error.isNotEmpty) ...[
        const SizedBox(height: 16),
        _ErrorPanel(message: _error),
      ],
      if (freshResult != null) ...[
        const SizedBox(height: 18),
        _ResultPanel(
          response: freshResult,
          rollCount: _parseOptionalDouble(_rollCount.text),
          widthMm: _parseRequiredDouble(_widthMm.text),
        ),
        if (_sourceMapId.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _openingSavedOrder ? null : _openOrderFromSavedMap,
            icon: Icon(
              _openingSavedOrder
                  ? Icons.hourglass_top_rounded
                  : Icons.playlist_add_check_rounded,
            ),
            label: Text(_openingSavedOrder ? 'Ochilmoqda...' : 'Zakaz ochish'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _openProductionMap,
          icon: const Icon(Icons.account_tree_outlined),
          label: const Text('Production mapga ulash'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    ];
  }

  bool get _hasFreshCalculation =>
      _result != null && _lastCalculatedSignature == _calculationSignature();

  String _calculationSignature() {
    return [
      _product.text.trim(),
      _kg.text.trim(),
      _widthMm.text.trim(),
      _wastePercent.text.trim(),
      _rollCount.text.trim(),
      _firstMaterial.text.trim(),
      _firstMicron.text.trim(),
      _secondMaterial.text.trim(),
      _secondMicron.text.trim(),
      _thirdMaterial.text.trim(),
      _thirdMicron.text.trim(),
    ].join('\u001f');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    final children =
        _editingAllFields ? _fullEditChildren() : _compactTemplateChildren();
    final resolvedName = _resolvedOrderName().trim();
    final pageTitle = resolvedName.isEmpty || resolvedName == 'Zakaz'
        ? 'Zakaz yaratish'
        : resolvedName;
    return AppShell(
      drawer: AdminNavigationDrawer(
        selectedIndex: 0,
        selectedRouteName: AppRoutes.adminCalculate,
        onNavigate: _openDrawerRoute,
      ),
      title: pageTitle,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      actions: [
        AppShellIconAction(
          icon: Icons.list_alt_rounded,
          onTap: _openOrders,
        ),
        if (!_editingAllFields)
          AppShellIconAction(
            icon: Icons.edit_outlined,
            onTap: _enableFullEdit,
          ),
      ],
      bottom: const AdminDock(activeTab: AdminDockTab.home),
      bottomDockFadeStrength: null,
      contentPadding: EdgeInsets.zero,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
            children: children,
          ),
        ),
      ),
    );
  }
}

class _QuickOrderRecreateDialog extends StatelessWidget {
  const _QuickOrderRecreateDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu tezkor zakazlar ro‘yxatida bor',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Qaytadan yaratmoqchimisiz?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 26),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: scheme.errorContainer.withValues(alpha: 0.42),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(false),
                            child: Center(
                              child: Text(
                                'Yo‘q',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.error,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: scheme.surfaceContainerHigh),
                      Expanded(
                        child: Material(
                          color: scheme.primary,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(true),
                            child: Center(
                              child: Text(
                                'Ha',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedTemplateSummary extends StatelessWidget {
  const _SavedTemplateSummary({
    required this.title,
    required this.customer,
    required this.customerRef,
    required this.product,
    required this.itemCode,
    required this.status,
    required this.imageUrl,
    required this.imageName,
    required this.imageSizeBytes,
    required this.widthMm,
    required this.rollCount,
    required this.firstLayerMaterial,
    required this.firstLayerMicron,
    required this.secondLayerMaterial,
    required this.secondLayerMicron,
    required this.thirdLayerMaterial,
    required this.thirdLayerMicron,
    required this.note,
  });

  final String title;
  final String customer;
  final String customerRef;
  final String product;
  final String itemCode;
  final String status;
  final String imageUrl;
  final String imageName;
  final int imageSizeBytes;
  final String widthMm;
  final String rollCount;
  final String firstLayerMaterial;
  final String firstLayerMicron;
  final String secondLayerMaterial;
  final String secondLayerMicron;
  final String thirdLayerMaterial;
  final String thirdLayerMicron;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final imageTitle =
        imageName.trim().isEmpty ? 'Rasm biriktirilgan' : imageName.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.trim().isEmpty ? 'Zakaz' : title.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (imageUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showCalculateImageDialog(context, imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 2.35,
                  child: _ImagePreview(localPath: '', imageUrl: imageUrl),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              imageTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (imageSizeBytes > 0)
              Text(
                _formatBytes(imageSizeBytes),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
          const SizedBox(height: 16),
          _ChecklistSection(
            title: 'Buyurtma',
            rows: [
              _ChecklistRowData('Mijoz', customer, subtitle: customerRef),
              _ChecklistRowData('Mahsulot', product, subtitle: itemCode),
              _ChecklistRowData('Status', status),
            ],
          ),
          const SizedBox(height: 14),
          _ChecklistSection(
            title: 'Parametrlar',
            rows: [
              _ChecklistRowData('Razmer', widthMm, suffix: 'mm'),
              _ChecklistRowData('Val soni', rollCount, suffix: 'ta'),
            ],
          ),
          const SizedBox(height: 14),
          _ChecklistSection(
            title: 'Qavatlar',
            rows: [
              _ChecklistRowData(
                '1-qavat',
                _layerValue(firstLayerMaterial, firstLayerMicron),
              ),
              _ChecklistRowData(
                '2-qavat',
                _layerValue(secondLayerMaterial, secondLayerMicron),
              ),
              if (thirdLayerMaterial.trim().isNotEmpty ||
                  thirdLayerMicron.trim().isNotEmpty)
                _ChecklistRowData(
                  '3-qavat',
                  _layerValue(thirdLayerMaterial, thirdLayerMicron),
                ),
            ],
          ),
          if (note.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _ChecklistSection(
              title: 'Izoh',
              rows: [_ChecklistRowData('', note)],
            ),
          ],
        ],
      ),
    );
  }
}

void _showCalculateImageDialog(BuildContext context, String imageUrl) {
  final token = _sessionToken();
  showDialog<void>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return Dialog.fullscreen(
        backgroundColor: scheme.surface,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      MobileApi.instance.calculateOrderImageUrl(imageUrl),
                      headers: token.isEmpty
                          ? null
                          : {'Authorization': 'Bearer $token'},
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          _ImagePlaceholder(color: scheme.primary),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ChecklistSection extends StatelessWidget {
  const _ChecklistSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_ChecklistRowData> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleRows = rows.where((row) => row.hasValue).toList();
    if (visibleRows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < visibleRows.length; i++) ...[
          _ChecklistRow(data: visibleRows[i]),
          if (i != visibleRows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.data});

  final _ChecklistRowData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = data.formattedValue;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.label.trim().isNotEmpty) ...[
          SizedBox(
            width: 92,
            child: Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: data.label.trim().isEmpty ? 4 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (data.subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  data.subtitle.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistRowData {
  const _ChecklistRowData(
    this.label,
    this.value, {
    this.subtitle = '',
    this.suffix = '',
  });

  final String label;
  final String value;
  final String subtitle;
  final String suffix;

  bool get hasValue => value.trim().isNotEmpty || subtitle.trim().isNotEmpty;

  String get formattedValue {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return subtitle.trim();
    }
    final unit = suffix.trim();
    return unit.isEmpty ? trimmed : '$trimmed $unit';
  }
}

String _layerValue(String material, String micron) {
  final materialText = material.trim();
  final micronText = micron.trim();
  if (materialText.isEmpty) {
    return micronText.isEmpty ? '' : '$micronText mkr';
  }
  if (micronText.isEmpty) {
    return materialText;
  }
  return '$materialText • $micronText mkr';
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.response,
    required this.rollCount,
    required this.widthMm,
  });

  final CalculateResponse response;
  final double? rollCount;
  final double widthMm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Natija',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _ResultMultilineRow(
            label: 'Pechat',
            value: productionMapPechatCompatibilitySummary(
              rollCount: rollCount,
              widthMm: widthMm,
            ),
          ),
          const Divider(height: 18),
          for (var i = 0; i < response.results.length; i++) ...[
            _ResultVariant(
              index: i,
              result: response.results[i],
              wastePercent: response.wastePercent,
              rubberSizeMm: response.rubberSizeMm,
            ),
            if (i != response.results.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ResultVariant extends StatelessWidget {
  const _ResultVariant({
    required this.index,
    required this.result,
    required this.wastePercent,
    required this.rubberSizeMm,
  });

  final int index;
  final CalculateResult result;
  final double wastePercent;
  final int rubberSizeMm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = index == 0 ? 'Asosiy' : 'Variant ${index + 1}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _ResultRow(label: 'Koeff', value: _fmt(result.coeffSum)),
        _ResultRow(label: 'Razmer', value: '${_fmt(result.widthSm)} sm'),
        _ResultRow(label: 'Rezina razmeri', value: '$rubberSizeMm mm'),
        _ResultRow(label: 'Base', value: _fmt(result.baseLength)),
        _ResultRow(
          label: 'Atxod ${_fmt(wastePercent)}%',
          value: _fmt(result.wasteLength),
        ),
        const Divider(height: 18),
        _ResultRow(
          label: 'Yakuniy uzunlik',
          value: _fmt(result.roundedLength),
          emphasized: true,
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ResultMultilineRow extends StatelessWidget {
  const _ResultMultilineRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: style?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _PickerInput extends StatelessWidget {
  const _PickerInput({
    required this.label,
    required this.value,
    required this.onTap,
    this.subtitle = '',
    this.required = false,
  });

  final String label;
  final String value;
  final String subtitle;
  final bool required;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayValue = value.trim();
    final displaySubtitle = subtitle.trim();
    final empty = displayValue.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: required && empty ? scheme.error : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: required && empty
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      empty ? '$label tanlang' : displayValue,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color:
                            empty ? scheme.onSurfaceVariant : scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (displaySubtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        displaySubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageUploadInput extends StatelessWidget {
  const _ImageUploadInput({
    required this.localPath,
    required this.imageUrl,
    required this.imageName,
    required this.imageSizeBytes,
    required this.uploading,
    required this.onPick,
    required this.onClear,
  });

  final String localPath;
  final String imageUrl;
  final String imageName;
  final int imageSizeBytes;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasImage = localPath.trim().isNotEmpty || imageUrl.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: uploading ? null : onPick,
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _ImagePreview(
                    localPath: localPath,
                    imageUrl: imageUrl,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rang rasmi',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasImage
                          ? (imageName.trim().isEmpty
                              ? 'Rasm tanlangan'
                              : imageName.trim())
                          : 'Rasm tanlash',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (imageSizeBytes > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatBytes(imageSizeBytes),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (uploading) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 3),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasImage)
                IconButton(
                  onPressed: uploading ? null : onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              else
                Icon(
                  Icons.upload_file_rounded,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.localPath,
    required this.imageUrl,
  });

  final String localPath;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (localPath.trim().isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
      );
    }
    if (imageUrl.trim().isNotEmpty) {
      final token = _sessionToken();
      return Image.network(
        MobileApi.instance.calculateOrderImageUrl(imageUrl),
        headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'},
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _ImagePlaceholder(color: scheme.primary),
      );
    }
    return _ImagePlaceholder(color: scheme.onSurfaceVariant);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        color: color,
      ),
    );
  }
}

String _sessionToken() {
  try {
    return MobileApi.instance.requireToken();
  } catch (_) {
    return '';
  }
}

class _LayerInputs extends StatelessWidget {
  const _LayerInputs({
    required this.material,
    required this.micron,
    required this.materialLabel,
    this.required = false,
  });

  final TextEditingController material;
  final TextEditingController micron;
  final String materialLabel;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _TextInput(
            controller: material,
            label: materialLabel,
            required: required,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _NumberInput(
            controller: micron,
            label: 'Mikron',
            suffixText: 'mkr',
            required: required,
          ),
        ),
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    this.required = false,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        textInputAction:
            maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
        decoration: InputDecoration(labelText: label),
        validator: required ? _requiredText : null,
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.controller,
    required this.label,
    required this.suffixText,
    this.required = false,
    this.allowZero = false,
  });

  final TextEditingController controller;
  final String label;
  final String suffixText;
  final bool required;
  final bool allowZero;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffixText,
        ),
        validator: required
            ? (allowZero ? _requiredNonNegativeNumber : _requiredPositiveNumber)
            : (allowZero
                ? _optionalNonNegativeNumber
                : _optionalPositiveNumber),
      ),
    );
  }
}

class _IntegerInput extends StatelessWidget {
  const _IntegerInput({
    required this.controller,
    required this.label,
    required this.suffixText,
  });

  final TextEditingController controller;
  final String label;
  final String suffixText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffixText,
        ),
        validator: _optionalPositiveInteger,
      ),
    );
  }
}

String? _requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Majburiy';
  }
  return null;
}

String? _requiredPositiveNumber(String? value) {
  final requiredError = _requiredText(value);
  if (requiredError != null) {
    return requiredError;
  }
  return _optionalPositiveNumber(value);
}

String? _requiredNonNegativeNumber(String? value) {
  final requiredError = _requiredText(value);
  if (requiredError != null) {
    return requiredError;
  }
  return _optionalNonNegativeNumber(value);
}

String? _optionalPositiveNumber(String? value) {
  final normalized = value?.trim().replaceAll(',', '.') ?? '';
  if (normalized.isEmpty) {
    return null;
  }
  final parsed = double.tryParse(normalized);
  if (parsed == null || parsed <= 0) {
    return 'Noto‘g‘ri';
  }
  return null;
}

String? _optionalNonNegativeNumber(String? value) {
  final normalized = value?.trim().replaceAll(',', '.') ?? '';
  if (normalized.isEmpty) {
    return null;
  }
  final parsed = double.tryParse(normalized);
  if (parsed == null || parsed < 0) {
    return 'Noto‘g‘ri';
  }
  return null;
}

String? _optionalPositiveInteger(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }
  final parsed = int.tryParse(normalized);
  if (parsed == null || parsed <= 0) {
    return 'Noto‘g‘ri';
  }
  return null;
}

double _parseRequiredDouble(String value) {
  return double.parse(value.trim().replaceAll(',', '.'));
}

double? _parseOptionalDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  return double.parse(normalized);
}

String _formatBytes(int value) {
  if (value >= 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (value >= 1024) {
    return '${(value / 1024).toStringAsFixed(1)} KB';
  }
  return '$value B';
}

String _fmt(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String _fmtInput(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}

String _normalizeProductMapKey(String value) {
  return value.trim().toLowerCase();
}
