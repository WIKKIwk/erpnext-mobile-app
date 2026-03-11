import '../models/app_models.dart';

class FakeRepository {
  const FakeRepository();

  List<SupplierItem> supplierItems() {
    return const [
      SupplierItem(
        code: 'ITEM-001',
        name: 'Premium Rice',
        uom: 'Kg',
        warehouse: 'Stores - CH',
      ),
      SupplierItem(
        code: 'ITEM-014',
        name: 'Sunflower Oil',
        uom: 'L',
        warehouse: 'Stores - CH',
      ),
      SupplierItem(
        code: 'ITEM-023',
        name: 'Packing Box',
        uom: 'Nos',
        warehouse: 'Stores - CH',
      ),
    ];
  }

  List<DispatchRecord> supplierHistory() {
    return const [
      DispatchRecord(
        id: 'MAT-PRE-0009',
        supplierName: 'Abdulloh',
        itemCode: 'ITEM-014',
        itemName: 'Sunflower Oil',
        uom: 'L',
        sentQty: 40,
        acceptedQty: 40,
        note: '',
        status: DispatchStatus.accepted,
        createdLabel: 'Bugun, 16:20',
      ),
      DispatchRecord(
        id: 'MAT-PRE-0008',
        supplierName: 'Abdulloh',
        itemCode: 'ITEM-023',
        itemName: 'Packing Box',
        uom: 'Nos',
        sentQty: 120,
        acceptedQty: 0,
        note: '',
        status: DispatchStatus.pending,
        createdLabel: 'Kecha, 12:10',
      ),
      DispatchRecord(
        id: 'MAT-PRE-0007',
        supplierName: 'Abdulloh',
        itemCode: 'ITEM-001',
        itemName: 'Premium Rice',
        uom: 'Kg',
        sentQty: 18,
        acceptedQty: 0,
        note: '',
        status: DispatchStatus.draft,
        createdLabel: 'Kecha, 09:35',
      ),
    ];
  }

  List<DispatchRecord> werkaPending() {
    return const [
      DispatchRecord(
        id: 'MAT-PRE-0011',
        supplierName: 'Abdulloh',
        itemCode: 'ITEM-001',
        itemName: 'Premium Rice',
        uom: 'Kg',
        sentQty: 25,
        acceptedQty: 0,
        note: '',
        status: DispatchStatus.pending,
        createdLabel: '3 daqiqa oldin',
      ),
      DispatchRecord(
        id: 'MAT-PRE-0010',
        supplierName: 'Azimjon',
        itemCode: 'ITEM-014',
        itemName: 'Sunflower Oil',
        uom: 'L',
        sentQty: 60,
        acceptedQty: 0,
        note: '',
        status: DispatchStatus.pending,
        createdLabel: 'Bugun, 18:40',
      ),
    ];
  }
}
