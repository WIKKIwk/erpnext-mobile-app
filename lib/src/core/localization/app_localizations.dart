import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('uz'),
    Locale('en'),
    Locale('ru'),
  ];

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isUzbek => locale.languageCode == 'uz';
  bool get isRussian => locale.languageCode == 'ru';

  String _t(String uz, String en, String ru) {
    if (isUzbek) return uz;
    if (isRussian) return ru;
    return en;
  }

  String get appTitle => _t('Accord', 'Accord', 'Accord');
  String get profileTitle => _t('Profil', 'Profile', 'Профиль');
  String get werkaAccount =>
      _t('Omborchi akkaunti', 'Werka account', 'Аккаунт кладовщика');
  String get supplierAccount =>
      _t('Ta\'minotchi akkaunti', 'Supplier account', 'Аккаунт поставщика');
  String get customerAccount =>
      _t('Haridor akkaunti', 'Customer account', 'Аккаунт покупателя');
  String get adminAccount =>
      _t('Admin akkaunti', 'Admin account', 'Аккаунт администратора');
  String get nicknameSaveFailed => _t(
      'Nickname saqlanmadi', 'Nickname was not saved', 'Псевдоним не сохранен');
  String get imagePickFailed => _t('Rasm tanlanmadi', 'Image selection failed',
      'Не удалось выбрать изображение');
  String get imageSaveFailed =>
      _t('Rasm saqlanmadi', 'Image was not saved', 'Изображение не сохранено');
  String get save => _t('Saqlash', 'Save', 'Сохранить');
  String get saveChanges =>
      _t('O‘zgarishlarni saqlash', 'Save changes', 'Сохранить изменения');
  String get phoneLabel => _t('Telefon', 'Phone', 'Телефон');
  String get legalNameLabel => _t('Asl ism', 'Legal name', 'Официальное имя');
  String get nicknameLabel => _t('Nickname', 'Nickname', 'Псевдоним');
  String get nicknameHint => _t('O‘zingizga ko‘rinadigan ism',
      'The name visible to you', 'Имя, видимое только вам');
  String get securityTitle => _t('Xavfsizlik', 'Security', 'Безопасность');
  String get pinEnabled => _t('4 xonali PIN yoqilgan',
      'A 4-digit PIN is enabled', '4-значный PIN включен');
  String get pinDisabled => _t(
      'App uchun 4 xonali PIN o‘rnating',
      'Set a 4-digit PIN for the app',
      'Установите 4-значный PIN для приложения');
  String get pinSaving => _t('Saqlanmoqda...', 'Saving...', 'Сохранение...');
  String get pinSet => _t('PIN o‘rnatish', 'Set PIN', 'Установить PIN');
  String get pinChange => _t('PIN almashtirish', 'Change PIN', 'Изменить PIN');
  String get pinRemove => _t('PIN o‘chirish', 'Remove PIN', 'Удалить PIN');
  String get biometricEnableTitle => _t(
        'Biometrik autentifikatsiyani yoqish',
        'Enable biometric authentication',
        'Включить биометрическую аутентификацию',
      );
  String get biometricEnabledBody => _t(
        'Yoqilgan. App Face ID yoki fingerprint bilan tez ochiladi.',
        'Enabled. The app can be unlocked quickly with Face ID or fingerprint.',
        'Включено. Приложение можно быстро разблокировать с помощью Face ID или отпечатка пальца.',
      );
  String get biometricDisabledBody => _t(
        'O‘chirilgan. Face ID yoki fingerprint bilan tez ochish ishlamaydi.',
        'Disabled. Fast unlock with Face ID or fingerprint is off.',
        'Выключено. Быстрая разблокировка с помощью Face ID или отпечатка пальца недоступна.',
      );
  String get languageTitle => _t('Til', 'Language', 'Язык');
  String get languageBody => _t('Ilova tilini tanlang',
      'Choose the app language', 'Выберите язык приложения');
  String get uzbek => _t('O‘zbekcha', 'Uzbek', 'Узбекский');
  String get english => _t('English', 'English', 'Английский');
  String get russian => _t('Ruscha', 'Russian', 'Русский');
  String get selectedImageNotice => _t(
        'Yangi rasm tanlandi. Saqlashni bossangiz profil yangilanadi.',
        'A new image was selected. Save to update the profile.',
        'Выбрано новое изображение. Нажмите сохранить, чтобы обновить профиль.',
      );
  String get appLockTitle =>
      _t('App qulfi', 'App lock', 'Блокировка приложения');
  String get appLockSubtitle => _t('4 xonali PIN kiriting',
      'Enter your 4-digit PIN', 'Введите 4-значный PIN');
  String get unlock => _t('Ochish', 'Unlock', 'Открыть');
  String get checking => _t('Tekshirilmoqda...', 'Checking...', 'Проверка...');
  String get biometricCta => _t('Biometrik autentifikatsiya',
      'Biometric authentication', 'Биометрическая аутентификация');
  String get pinWrong => _t('PIN noto‘g‘ri', 'Incorrect PIN', 'Неверный PIN');
  String get biometricFailed => _t(
        'Biometrik tasdiq bajarilmadi',
        'Biometric verification did not complete',
        'Биометрическая проверка не выполнена',
      );

  String get clearTitle => _t('Tozalash', 'Clear', 'Очистить');
  String get logoutTitle => _t('Chiqish', 'Logout', 'Выход');
  String get logoutPrompt => _t(
      'Dasturdan chiqaymi?', 'Do you want to log out?', 'Выйти из приложения?');
  String get yes => _t('Ha', 'Yes', 'Да');
  String get no => _t('Yo‘q', 'No', 'Нет');
  String get retry => _t('Qayta urinish', 'Retry', 'Повторить');
  String get loading => _t('Yuklanmoqda...', 'Loading...', 'Загрузка...');
  String get confirmTitle => _t('Tasdiqlash', 'Confirm', 'Подтверждение');
  String get qtyRequired =>
      _t('Miqdor kiriting', 'Enter quantity', 'Введите количество');
  String get amountLabel => _t('Miqdor', 'Quantity', 'Количество');
  String get customerLabel => _t('Haridor', 'Customer', 'Покупатель');
  String get supplierLabel => _t('Ta\'minotchi', 'Supplier', 'Поставщик');
  String get itemLabel => _t('Mol', 'Item', 'Товар');
  String get selectCustomer =>
      _t('Haridor tanlang', 'Select customer', 'Выберите покупателя');
  String get searchCustomer =>
      _t('Haridor qidiring', 'Search customer', 'Поиск покупателя');
  String get selectSupplier =>
      _t('Ta\'minotchi tanlang', 'Select supplier', 'Выберите поставщика');
  String get searchSupplier =>
      _t('Ta\'minotchi qidiring', 'Search supplier', 'Поиск поставщика');
  String get selectItem => _t('Mol tanlang', 'Select item', 'Выберите товар');
  String get searchItem => _t('Mol qidiring', 'Search item', 'Поиск товара');
  String get createHubTitle => _t('Qayd', 'Create', 'Создать');
  String get unannouncedTitle =>
      _t('Aytilmagan mol', 'Unannounced item', 'Незаявленный товар');
  String get customerIssueTitle =>
      _t('Mol jo‘natish', 'Send item', 'Отправить товар');
  String get unannouncedDescription => _t(
        'Ta\'minotchi, mol va miqdorni bir oqimda tanlang',
        'Choose supplier, item, and quantity in one flow',
        'Выберите поставщика, товар и количество в одном потоке',
      );
  String get customerIssueDescription => _t(
        'Haridorga jo‘natma yaratish oqimi',
        'Flow for creating a shipment to a customer',
        'Поток создания отправки для покупателя',
      );
  String get notificationsTitle =>
      _t('Bildirishnomalar', 'Notifications', 'Уведомления');
  String get noNotifications => _t('Hali bildirishnomalar yo‘q.',
      'No notifications yet.', 'Уведомлений пока нет.');
  String get clearAllNotificationsPrompt => _t(
        'Hamma bildirishnomalarni tozalaysizmi?',
        'Clear all notifications?',
        'Очистить все уведомления?',
      );
  String get notificationsLoadFailed => _t(
        'Bildirishnomalar yuklanmadi',
        'Failed to load notifications',
        'Не удалось загрузить уведомления',
      );
  String get recentTitle =>
      _t('So‘nggi harakatlar', 'Recent', 'Недавние действия');
  String get recentSubtitle => _t(
        'Avvalgi harakatni prefill bilan qayta ishlating',
        'Reuse previous actions with prefill',
        'Повторно используйте предыдущие действия с предзаполнением',
      );
  String get recentLoadFailed => _t('Recent yuklanmadi',
      'Failed to load recent', 'Не удалось загрузить раздел недавних');
  String get noRecentActions => _t(
        'Hali repeat qilish uchun recent harakat yo‘q.',
        'There are no recent actions to repeat yet.',
        'Пока нет недавних действий для повтора.',
      );
  String get repeatSendAgain =>
      _t('Yana jo‘natish', 'Send again', 'Отправить снова');
  String get repeatCreateAgain =>
      _t('Yana qayd qilish', 'Create again', 'Создать снова');
  String get pendingStatus => _t('Jarayonda', 'In progress', 'В процессе');
  String get confirmedStatus => _t('Tasdiqlangan', 'Confirmed', 'Подтверждено');
  String get returnedStatus => _t('Qaytarilgan', 'Returned', 'Возвращено');
  String get inProgressItemsTitle =>
      _t('Jarayondagi mahsulotlar', 'Items in progress', 'Товары в процессе');
  String get recordsLoadFailed => _t('Yozuvlar yuklanmadi',
      'Failed to load records', 'Не удалось загрузить записи');
  String get noRecordsYet => _t('Bu ro‘yxatda hozircha yozuv yo‘q.',
      'No records in this list yet.', 'В этом списке пока нет записей.');
  String get statusListLoadFailed => _t(
        'Status ro‘yxati yuklanmadi',
        'Failed to load status list',
        'Не удалось загрузить список статусов',
      );
  String get noStatusRecords => _t(
        'Bu statusda hozircha yozuv yo‘q.',
        'No records in this status yet.',
        'В этом статусе пока нет записей.',
      );
  String get receiptsSuffix => _t('ta receipt', 'receipts', 'документов');
  String get sentToCustomer =>
      _t('haridorga yuborilgan', 'sent to customer', 'отправлено покупателю');
  String get receivedFromSupplier => _t('ta\'minotchidan qabul qilingan',
      'received from supplier', 'получено от поставщика');
  String get acceptedFromQtyPrefix => _t('Qabul', 'Accepted', 'Принято');
  String get createFlowBack =>
      _t('Qaydga qaytish', 'Back to create', 'Назад к созданию');
  String get pendingListBack => _t('Pending listga qaytish',
      'Back to pending list', 'Назад к списку ожидания');
  String get sentSuccess => _t('Jo‘natildi', 'Sent', 'Отправлено');
  String get createdSuccess => _t('Qayd qilindi', 'Created', 'Создано');
  String get receivedSuccess => _t('Qabul qilindi', 'Received', 'Принято');
  String get customerApproved =>
      _t('Haridor tasdiqlagan', 'Customer approved', 'Покупатель подтвердил');
  String get customerRejected =>
      _t('Haridor rad etgan', 'Customer rejected', 'Покупатель отклонил');
  String get partiallyCompleted =>
      _t('Qisman yakunlangan', 'Partially completed', 'Частично завершено');
  String get cancelled => _t('Bekor qilingan', 'Cancelled', 'Отменено');
  String get waitingCustomerResponse => _t(
        'Haridor javobi kutilmoqda',
        'Waiting for customer response',
        'Ожидается ответ покупателя',
      );
  String get draft => _t('Draft', 'Draft', 'Черновик');
  String get noExtraNote => _t('Qo‘shimcha izoh yo‘q.', 'No additional note.',
      'Дополнительного примечания нет.');
  String get customerShipmentTitle =>
      _t('Haridor jo‘natmasi', 'Customer shipment', 'Отправка покупателю');
  String get statusLabel => _t('Status', 'Status', 'Статус');
  String get dateLabel => _t('Sana', 'Date', 'Дата');
  String get detailsStateTitle => _t('Holat', 'State', 'Состояние');

  String statusWithName(String name, String status) => '$status • $name';
  String recordsLoadFailedWith(Object error) => '$recordsLoadFailed: $error';
  String statusListLoadFailedWith(Object error) =>
      '$statusListLoadFailed: $error';
  String notificationsLoadFailedWith(Object error) =>
      '$notificationsLoadFailed: $error';
  String recentLoadFailedWith(Object error) => '$recentLoadFailed: $error';
  String sentQtyStatus(num qty, String uom, String statusWord) =>
      '${qty.toStringAsFixed(0)} $uom $statusWord';
  String receiptCountLabel(int count) =>
      isUzbek ? '$count ta receipt' : '$count receipts';
  String customerFlowMetric(num qty, String uom) =>
      '${qty.toStringAsFixed(0)} $uom $sentToCustomer';
  String supplierFlowMetric(num qty, String uom) =>
      '${qty.toStringAsFixed(0)} $uom $receivedFromSupplier';
  String acceptedQtyLabel(num qty, String uom) =>
      '$acceptedFromQtyPrefix: ${qty.toStringAsFixed(0)} $uom';
  String customerShipmentPendingNote() => isUzbek
      ? 'Bu jo‘natma omborchi tomonidan haridorga yuborilgan. Qaytarish yoki tasdiqlash haridor tomonidan qilinadi.'
      : isRussian
          ? 'Эта отправка была сделана кладовщиком для покупателя. Возврат или подтверждение должен выполнить покупатель.'
          : 'This shipment was sent by Werka to the customer. Any rejection or approval must be done by the customer.';
  String sentToCustomerLine(num qty, String uom) => _t(
        '${qty.toStringAsFixed(2)} $uom haridorga jo‘natildi',
        '${qty.toStringAsFixed(2)} $uom sent to customer',
        '${qty.toStringAsFixed(2)} $uom отправлено покупателю',
      );
  String createdLine(num qty, String uom) => _t(
        '${qty.toStringAsFixed(2)} $uom qayd qilindi',
        '${qty.toStringAsFixed(2)} $uom recorded',
        '${qty.toStringAsFixed(2)} $uom зафиксировано',
      );
  String receivedLine(num qty, String uom) => _t(
        '${qty.toStringAsFixed(2)} $uom qabul qilindi',
        '${qty.toStringAsFixed(2)} $uom received',
        '${qty.toStringAsFixed(2)} $uom принято',
      );
  String customerIssueFailed(Object error) => _t(
        'Mol jo‘natish bo‘lmadi: $error',
        'Sending item failed: $error',
        'Не удалось отправить товар: $error',
      );
  String unannouncedSuppliersFailed(Object error) => _t(
        'Ta\'minotchilar yuklanmadi: $error',
        'Suppliers failed to load: $error',
        'Не удалось загрузить поставщиков: $error',
      );
  String customersLoadFailed(Object error) => _t(
        'Haridorlar yuklanmadi: $error',
        'Customers failed to load: $error',
        'Не удалось загрузить покупателей: $error',
      );

  String get werkaRoleName => _t('Omborchi', 'Werka', 'Кладовщик');
  String get customerRoleName => _t('Haridor', 'Customer', 'Покупатель');
  String get supplierRoleName => _t('Ta\'minotchi', 'Supplier', 'Поставщик');
  String get submittedStatus => _t('Yuborilgan', 'Submitted', 'Отправлено');
  String get supplierHomeLoadFailed => _t(
      'Home yuklanmadi', 'Home failed to load', 'Не удалось загрузить главную');
  String get noSupplierReceiptsYet =>
      _t('Hozircha receipt yo‘q.', 'No receipts yet.', 'Пока нет приходов.');
  String get noSupplierShipmentsYet =>
      _t('Hali jo‘natishlar yo‘q.', 'No shipments yet.', 'Пока нет отправок.');
  String get supplierAckTitle => _t('Ta\'minotchi tasdiqladi',
      'Supplier acknowledged', 'Поставщик подтвердил');

  String get pendingLabel => _t('Kutilmoqda', 'Pending', 'Ожидается');
  String get rejectedLabel => _t('Rad etilgan', 'Rejected', 'Отклонено');
  String get recentShipmentsTitle =>
      _t('So‘nggi jo‘natmalar', 'Recent shipments', 'Недавние отправки');
  String get noShipments => _t('Jo‘natma yo‘q', 'No shipments', 'Нет отправок');
  String get shipmentsFlowTitle =>
      _t('Jo‘natmalar oqimi', 'Shipment flow', 'Поток отправок');
  String get detailsTitle => _t('Batafsil', 'Details', 'Детали');
  String get shipmentInfoTitle =>
      _t('Jo‘natma ma’lumoti', 'Shipment details', 'Информация об отправке');
  String get noteTitle => _t('Izoh', 'Note', 'Примечание');
  String get responseTitle => _t('Javob', 'Response', 'Ответ');
  String get rejectTitle => _t('Rad etish', 'Reject', 'Отклонить');
  String get optionalReasonHint =>
      _t('Sabab (ixtiyoriy)', 'Reason (optional)', 'Причина (необязательно)');
  String get confirmQuestion => _t(
      'Haqiqatan ham tasdiqlaysizmi?',
      'Are you sure you want to confirm?',
      'Вы уверены, что хотите подтвердить?');
  String responseSendFailed(Object error) => _t('Javob yuborilmadi: $error',
      'Response was not sent: $error', 'Ответ не был отправлен: $error');
  String get approveAction => _t('Tasdiqlayman', 'Approve', 'Подтверждаю');
  String get rejectAction => _t('Rad etaman', 'Reject', 'Отклоняю');
  String get sending => _t('Yuborilmoqda...', 'Sending...', 'Отправка...');
  String get approvedLabel => _t('Tasdiqlandi', 'Approved', 'Подтверждено');
  String get rejectedStatusLabel => _t('Rad etildi', 'Rejected', 'Отклонено');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
        (item) => item.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
