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
  String get welcomeToAccord => _t(
        'Accord mobil ilovasiga xush kelibsiz',
        'Welcome to Accord mobile app',
        'Добро пожаловать в мобильное приложение Accord',
      );
  String get signInTitle => _t('Kirish', 'Sign in', 'Вход');
  String get getStarted => _t('Boshlash', 'Get started', 'Начать');
  String get loginAction => _t('Kirish', 'Login', 'Войти');
  String get codeLabel => _t('Kod', 'Code', 'Код');
  String get loginRequiredFields => _t(
        'Telefon raqam va kodni kiriting',
        'Enter phone number and code',
        'Введите номер телефона и код',
      );
  String get loginFailed => _t(
        'Kirish muvaffaqiyatsiz',
        'Login failed',
        'Не удалось войти',
      );
  String get connectInternetPrompt => _t(
        'Iltimos internetga ulaning.',
        'Please connect to the internet.',
        'Пожалуйста, подключитесь к интернету.',
      );
  String get profileTitle => _t('Profil', 'Profile', 'Профиль');
  String get werkaAccount =>
      _t('Omborchi akkaunti', 'Wmanager account', 'Аккаунт кладовщика');
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
  String get pinEnabled => _t('PIN yoqilgan', 'PIN enabled', 'PIN включен');
  String get pinDisabled => _t('PIN o‘rnating', 'Set PIN', 'Установите PIN');
  String get pinSaving => _t('Saqlanmoqda...', 'Saving...', 'Сохранение...');
  String get pinSet => _t('PIN o‘rnatish', 'Set PIN', 'Установить PIN');
  String get pinChange => _t('PIN almashtirish', 'Change PIN', 'Изменить PIN');
  String get pinRemove => _t('PIN o‘chirish', 'Remove PIN', 'Удалить PIN');
  String get biometricEnableTitle => _t(
        'Biometrik autentifikatsiya',
        'Biometric authentication',
        'Биометрическая аутентификация',
      );
  String get biometricEnabledBody => _t(
        'Yoqilgan',
        'Enabled',
        'Включено',
      );
  String get biometricDisabledBody => _t(
        'O‘chirilgan',
        'Disabled',
        'Выключено',
      );
  String get languageTitle => _t('Til', 'Language', 'Язык');
  String get languageUnselected =>
      _t('Tanlanmagan', 'Unselected', 'Не выбрано');
  String get languageBody => _t('Ilova tilini tanlang',
      'Choose the app language', 'Выберите язык приложения');
  String get themeTitle => _t('Tema', 'Theme', 'Тема');
  String get themeBody => _t('Rang uslubini tanlang', 'Choose the color style',
      'Выберите цветовой стиль');
  String get themeClassicLabel => _t('Klassik', 'Classic', 'Классика');
  String get themeEarthLabel => _t('Qumli', 'Earthy', 'Песочная');
  String get themeBlushLabel => _t('Atirgul', 'Blush', 'Розовая');
  String get themeMossLabel => _t('Yaproq', 'Moss', 'Листва');
  String get themeLavenderLabel => _t('Lavanda', 'Lavender', 'Лаванда');
  String get themeSlateLabel => _t('Tutun', 'Slate', 'Сланец');
  String get themeOceanLabel => _t('Dengiz', 'Ocean', 'Океан');
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
  String get itemLabel => _t('Mahsulot', 'Item', 'Товар');
  String get selectCustomer =>
      _t('Haridor tanlang', 'Select customer', 'Выберите покупателя');
  String get searchCustomer =>
      _t('Haridor qidiring', 'Search customer', 'Поиск покупателя');
  String get selectSupplier =>
      _t('Ta\'minotchi tanlang', 'Select supplier', 'Выберите поставщика');
  String get searchSupplier =>
      _t('Ta\'minotchi qidiring', 'Search supplier', 'Поиск поставщика');
  String get selectItem =>
      _t('Mahsulot tanlang', 'Select item', 'Выберите товар');
  String get searchItem =>
      _t('Mahsulot qidiring', 'Search item', 'Поиск товара');
  String get aiSearchTakePhoto =>
      _t('Rasmga olish', 'Take photo', 'Сделать фото');
  String get aiSearchChoosePhoto =>
      _t('Gallereyadan tanlash', 'Choose from gallery', 'Выбрать из галереи');
  String get aiSearchNotConfigured => _t(
        'AI qidiruv sozlanmagan.',
        'AI search is not configured.',
        'AI-поиск не настроен.',
      );
  String get aiSearchNoResult => _t(
        'AI rasm bo‘yicha qidiruv so‘zini topolmadi.',
        'AI could not infer a search query from the image.',
        'AI не смог подобрать поисковый запрос по изображению.',
      );
  String aiSearchFailed(String error) => _t(
        'AI qidiruv bajarilmadi: $error',
        'AI search failed: $error',
        'AI-поиск не выполнен: $error',
      );
  String get createHubTitle => _t('Qayd', 'Create', 'Создать');
  String get unannouncedTitle =>
      _t('Aytilmagan mahsulot', 'Unannounced item', 'Незаявленный товар');
  String get customerIssueTitle =>
      _t('Mahsulot jo‘natish', 'Send item', 'Отправить товар');
  String get unannouncedDescription => _t(
        'Ta\'minotchi, mahsulot va miqdorni bir oqimda tanlang',
        'Choose supplier, item, and quantity in one flow',
        'Выберите поставщика, товар и количество в одном потоке',
      );
  String get customerIssueDescription => _t(
        'Haridorga jo‘natma yaratish oqimi',
        'Flow for creating a shipment to a customer',
        'Поток создания отправки для покупателя',
      );
  String get batchDispatchTitle => _t(
        'Ko‘p mahsulot chiqarish',
        'Multi-item dispatch',
        'Массовая отправка товаров',
      );
  String get batchDispatchDescription => _t(
        'Bir oqimda bir nechta jo‘natma tayyorlang',
        'Prepare multiple shipments in one flow',
        'Подготовьте несколько отправок в одном потоке',
      );
  String get nextItemAction => _t('Keyingi', 'Next', 'Далее');
  String get addAnotherAction => _t('Yana', 'Add another', 'Добавить еще');
  String get batchReviewTitle => _t(
        'Ro‘yxatni tekshirish',
        'Review list',
        'Проверка списка',
      );
  String get batchReviewUnlockHint => _t(
        'Tasdiqlash uchun ro‘yxatni oxirigacha ko‘ring',
        'Review the full list to unlock confirm',
        'Просмотрите список до конца, чтобы разблокировать подтверждение',
      );
  String get batchDraftAdded => _t(
        'Ro‘yxatga qo‘shildi',
        'Added to the list',
        'Добавлено в список',
      );
  String get batchNeedAtLeastTwoItems => _t(
        'Kamida 2 ta mahsulot kerak.',
        'At least 2 items are required.',
        'Нужно минимум 2 товара.',
      );
  String get batchSubmitResultTitle => _t('Natija', 'Result', 'Результат');
  String get closeAction => _t('Yopish', 'Close', 'Закрыть');
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
  String get archiveTitle => _t('Data', 'Data', 'Data');
  String get archivePlaceholder => _t(
        'Bu bo‘limga keyin yangi archive logikasi qo‘yiladi.',
        'A new archive flow will be added here later.',
        'Позже сюда будет добавлена новая логика архива.',
      );
  String get archiveReceivedTitle =>
      _t('Qabul qilingan', 'Received', 'Принятые');
  String get archiveSentTitle => _t('Jo\'natilgan', 'Sent', 'Отправленные');
  String get archiveReturnedTitle =>
      _t('Qaytarilgan', 'Returned', 'Возвращённые');
  String get archiveDailyTitle => _t('Kunlik', 'Daily', 'Дневной');
  String get archiveMonthlyTitle => _t('Oylik', 'Monthly', 'Месячный');
  String get archiveYearlyTitle => _t('Yillik', 'Yearly', 'Годовой');
  String get archiveCustomRangeTitle => _t(
        'Sana oralig‘i',
        'Date range',
        'Период дат',
      );
  String get archiveDateTitle => _t('Sana', 'Date', 'Дата');
  String get archiveMonthTitle => _t('Oy', 'Month', 'Месяц');
  String get archiveCalendarHint => _t(
        'Maʼlumot bor kunlar belgilangan.',
        'Days with data are highlighted.',
        'Дни с данными выделены.',
      );
  String get archiveCalendarEmptyMonth => _t(
        'Bu oyda yozuv topilmadi.',
        'No records found in this month.',
        'За этот месяц записей не найдено.',
      );
  String get archiveMonthCalendarHint => _t(
        'Maʼlumot bor oylar belgilangan.',
        'Months with data are highlighted.',
        'Месяцы с данными выделены.',
      );
  String get archiveYearCalendarHint => _t(
        'Maʼlumot bor yillar belgilangan.',
        'Years with data are highlighted.',
        'Годы с данными выделены.',
      );
  String get archiveCalendarEmptyYear => _t(
        'Bu yilda yozuv topilmadi.',
        'No records found in this year.',
        'За этот год записей не найдено.',
      );
  String get archiveStartDateLabel => _t(
        'Boshlanish sana',
        'Start date',
        'Дата начала',
      );
  String get archiveEndDateLabel => _t(
        'Tugash sana',
        'End date',
        'Дата окончания',
      );
  String get archiveSelectDateAction => _t('Tanlash', 'Select', 'Выбрать');
  String get archiveSelectMonthAction =>
      _t('Oy tanlash', 'Choose month', 'Выбрать месяц');
  String get archiveViewAction => _t('Ko‘rish', 'View', 'Открыть');
  String get archiveCustomRangeHint => _t(
        'Aynan kerakli kun yoki oraliqni tanlang.',
        'Choose the exact day or range you need.',
        'Выберите нужный день или диапазон.',
      );
  String get archiveInvalidRange => _t(
        'Tugash sana boshlanish sanadan oldin bo‘lishi mumkin emas.',
        'End date cannot be before start date.',
        'Дата окончания не может быть раньше даты начала.',
      );
  String get archiveChoosePeriod => _t(
        'Periodni tanlang',
        'Choose a period',
        'Выберите период',
      );
  String get archiveNoItems => _t(
        'Bu bo‘limda hozircha yozuv yo‘q.',
        'There are no records in this section yet.',
        'В этом разделе пока нет записей.',
      );
  String get archiveDownloadPdfAction =>
      _t('Yuklab olish', 'Download', 'Скачать');
  String get archiveDownloadingPdf =>
      _t('PDF yuklanmoqda...', 'Downloading PDF...', 'PDF загружается...');
  String get archivePdfReadyTitle => _t(
        'PDF tayyor',
        'PDF is ready',
        'PDF готов',
      );
  String get archivePdfReadyMessage => _t(
        'Uni Files ga, Photos ga saqlashingiz yoki share qilishingiz mumkin.',
        'You can save it to Files, save it to Photos, or share it.',
        'Вы можете сохранить его в Files, в Фото или поделиться им.',
      );
  String get archiveSaveToFilesAction => _t(
        'Files ga saqlash',
        'Save to Files',
        'Сохранить в Files',
      );
  String get archiveShareAction => _t(
        'Ulashish',
        'Share',
        'Поделиться',
      );
  String get batchViewListAction => _t(
        'Ro‘yxatni ko‘rish',
        'View list',
        'Открыть список',
      );
  String get archiveSavePhotoAction => _t(
        'Rasmga saqlash',
        'Save photo',
        'Сохранить как фото',
      );
  String get archivePdfSavedToPhotos => _t(
        'PDF birinchi sahifasi Photos ga saqlandi.',
        'The first PDF page was saved to Photos.',
        'Первая страница PDF сохранена в Фото.',
      );
  String get archivePdfPhotoFailed => _t(
        'PDF ni rasm sifatida saqlab bo‘lmadi.',
        'Failed to save the PDF as a photo.',
        'Не удалось сохранить PDF как фото.',
      );
  String archivePdfSavedAt(String location) => _t(
        'PDF saqlandi: $location',
        'PDF saved: $location',
        'PDF сохранён: $location',
      );
  String get archivePdfSavedToFiles => _t(
        'PDF Files ga saqlandi.',
        'PDF saved to Files.',
        'PDF сохранён в Files.',
      );
  String get archivePdfSavedOnIPhone => _t(
        'PDF Files ilovasiga saqlandi: On My iPhone > Erpnext Stock Mobile',
        'PDF saved in Files: On My iPhone > Erpnext Stock Mobile',
        'PDF сохранён в Files: На моём iPhone > Erpnext Stock Mobile',
      );
  String get archivePdfDownloadStartedWeb => _t(
        'PDF yuklab olish boshlandi.',
        'PDF download started.',
        'Загрузка PDF началась.',
      );
  String get archivePdfFailed => _t(
        'PDF yuklab bo‘lmadi. Qayta urinib ko‘ring.',
        'Failed to download PDF. Try again.',
        'Не удалось загрузить PDF. Попробуйте снова.',
      );
  String archiveRecordCountLabel(int count) => _t(
        '$count ta yozuv',
        '$count records',
        '$count записей',
      );
  String archiveTotalByUomLabel(String uom, double qty) => _t(
        '${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2)} $uom',
        '${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2)} $uom',
        '${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2)} $uom',
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
  String get serverDisconnectedRetry => _t(
        'Server uzilgan. Qayta urining.',
        'Server disconnected. Try again.',
        'Сервер отключен. Повторите попытку.',
      );
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
  String backToFlow(String flowName) =>
      _t('$flowName ga qaytish', 'Back to $flowName', 'Назад к $flowName');
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
  String recordsLoadFailedWith(Object error) => serverDisconnectedRetry;
  String statusListLoadFailedWith(Object error) => serverDisconnectedRetry;
  String notificationsLoadFailedWith(Object error) => serverDisconnectedRetry;
  String recentLoadFailedWith(Object error) => serverDisconnectedRetry;
  String sentQtyStatus(num qty, String uom, String statusWord) =>
      '${qty.toStringAsFixed(0)} $uom $statusWord';
  String receiptCountLabel(int count) =>
      isUzbek ? '$count ta receipt' : '$count receipts';
  String recordCountLabel(int count) =>
      isUzbek ? '$count ta hujjat' : '$count records';
  String customerFlowMetric(num qty, String uom) =>
      '${qty.toStringAsFixed(0)} $uom $sentToCustomer';
  String supplierFlowMetric(num qty, String uom) =>
      '${qty.toStringAsFixed(0)} $uom $receivedFromSupplier';
  String acceptedQtyLabel(num qty, String uom) =>
      '$acceptedFromQtyPrefix: ${qty.toStringAsFixed(0)} $uom';
  String batchDraftCountLabel(int count) => _t(
        'Ro‘yxatda $count ta mahsulot',
        '$count items in the list',
        'В списке $count товаров',
      );
  String batchCustomerCountLabel(int count) => _t(
        '$count ta haridor',
        '$count customers',
        '$count покупателей',
      );
  String batchCreatedCountLabel(int count) => _t(
        '$count ta jo‘natma yaratildi',
        '$count shipments created',
        'Создано $count отправок',
      );
  String batchFailedCountLabel(int count) => _t(
        '$count ta jo‘natma xato bo‘ldi',
        '$count shipments failed',
        '$count отправок завершились ошибкой',
      );
  String batchSentLine(int count) => _t(
        '$count ta jo‘natma yuborildi',
        '$count shipments sent',
        'Отправлено $count отправок',
      );
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
        'Server uzilgan. Qayta urining.',
        'Server disconnected. Try again.',
        'Сервер отключен. Повторите попытку.',
      );
  String get insufficientStockMessage => _t(
        'Omborda yetarli mahsulot yo‘q.',
        'There is not enough stock in the warehouse.',
        'На складе недостаточно товара.',
      );
  String unannouncedSuppliersFailed(Object error) => _t(
        'Server uzilgan. Qayta urining.',
        'Server disconnected. Try again.',
        'Сервер отключен. Повторите попытку.',
      );
  String customersLoadFailed(Object error) => _t(
        'Server uzilgan. Qayta urining.',
        'Server disconnected. Try again.',
        'Сервер отключен. Повторите попытку.',
      );

  String get werkaRoleName => _t('Omborchi', 'Wmanager', 'Кладовщик');
  String get customerRoleName => _t('Haridor', 'Customer', 'Покупатель');
  String get supplierRoleName => _t('Ta\'minotchi', 'Supplier', 'Поставщик');
  String get adminRoleName => _t('Admin', 'Admin', 'Админ');
  String get submittedStatus => _t('Qabul qilingan', 'Accepted', 'Принято');
  String get supplierAcceptedByWerkaTitle => _t(
      'Omborchi qabul qilganlar', 'Accepted by Werka', 'Принято кладовщиком');
  String get supplierAcceptedUnannouncedTitle => _t(
        'Aytilmagan mahsulot tasdiqlanganlar',
        'Approved unannounced items',
        'Подтвержденные незаявленные товары',
      );
  String get supplierPendingDispatchesTitle => _t(
        'Jo‘natilgan, javob kutilayotganlar',
        'Sent and awaiting response',
        'Отправлено, ожидается ответ',
      );
  String get supplierPendingUnannouncedTitle => _t(
        'Aytilmagan mahsulot bo‘yicha javob kutilayotganlar',
        'Awaiting reply on unannounced items',
        'Ожидается ответ по незаявленным товарам',
      );
  String get supplierHomeLoadFailed => _t(
      'Home yuklanmadi', 'Home failed to load', 'Не удалось загрузить главную');
  String get noSupplierReceiptsYet =>
      _t('Hozircha receipt yo‘q.', 'No receipts yet.', 'Пока нет приходов.');
  String get noSupplierShipmentsYet =>
      _t('Hali jo‘natishlar yo‘q.', 'No shipments yet.', 'Пока нет отправок.');
  String get adminSummaryLoadFailed => _t(
      'Admin summary yuklanmadi',
      'Admin summary failed to load',
      'Не удалось загрузить сводку администратора');
  String get adminSettingsTitle =>
      _t('Admin sozlamalari', 'Admin settings', 'Настройки администратора');
  String get adminActivityTitle => _t('Harakatlar', 'Activity', 'Активность');
  String get adminNoActivity =>
      _t('Hali harakat yo‘q.', 'No activity yet.', 'Активности пока нет.');
  String get adminCreateTitle => _t('Qo‘shish', 'Create', 'Создать');
  String get adminSettingsLoadFailed => _t('Settings yuklanmadi',
      'Settings failed to load', 'Не удалось загрузить настройки');
  String get settingsSaved =>
      _t('Sozlamalar saqlandi', 'Settings saved', 'Настройки сохранены');
  String get erpConnectionTitle =>
      _t('ERP ulanishi', 'ERP connection', 'ERP подключение');
  String get erpConnectionSubtitle => _t(
      'Core integratsiya va stock default sozlamalari',
      'Core integration and stock defaults',
      'Интеграция с ядром и значения по умолчанию для склада');
  String get adminCreateSupplierTitle =>
      _t('Ta\'minotchi qo‘shish', 'Add supplier', 'Добавить поставщика');
  String get adminCreateSupplierSubtitle => _t(
      'Ta\'minotchi yaratish va code boshqaruvi',
      'Create a supplier and manage codes',
      'Создание поставщика и управление кодами');
  String get adminCreateCustomerTitle =>
      _t('Haridor qo‘shish', 'Add customer', 'Добавить покупателя');
  String get adminCreateCustomerSubtitle => _t(
      'Haridor yaratish va jo‘natma qabul oqimi',
      'Create a customer and manage receiving flow',
      'Создание покупателя и управление потоком приемки');
  String get adminCreateWerkaTitle =>
      _t('Omborchi qo‘shish', 'Add Werka', 'Добавить кладовщика');
  String get adminCreateWerkaSubtitle => _t(
      'Omborchi phone va name sozlash',
      'Configure warehouse worker phone and name',
      'Настройка телефона и имени кладовщика');
  String get adminErpSettingsTitle =>
      _t('ERP sozlamalari', 'ERP settings', 'Настройки ERP');
  String get adminErpSettingsSubtitle => _t(
      'URL, key, secret va ombor sozlamalari',
      'URL, key, secret, and warehouse settings',
      'URL, key, secret и настройки склада');
  String get adminCreateItemTitle =>
      _t('Item qo‘shish', 'Add item', 'Добавить товар');
  String get adminCreateItemSubtitle =>
      _t('Yangi mahsulot yaratish', 'Create a new item', 'Создать новый товар');
  String get adminSettingsSectionTitle =>
      _t('Omborchi sozlamalari', 'Werka defaults', 'Настройки кладовщика');
  String get adminSettingsSectionSubtitle => _t(
      'Mobil oqimda ishlatiladigan contact qiymatlar',
      'Contact values used by the mobile flow',
      'Контактные значения, используемые в мобильном потоке');
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
  String get commentsTitle => _t('Izohlar', 'Comments', 'Комментарии');
  String get openDiscussionAction =>
      _t('Muhokamani ochish', 'Open discussion', 'Открыть обсуждение');
  String get responseTitle => _t('Javob', 'Response', 'Ответ');
  String get rejectTitle => _t('Rad etish', 'Reject', 'Отклонить');
  String get partialAcceptTitle =>
      _t('Qisman qabul', 'Partial acceptance', 'Частичное принятие');
  String get partialAcceptAction =>
      _t('Qisman qabul qilish', 'Accept partially', 'Принять частично');
  String get reportIssueTitle =>
      _t('Muammo bildirish', 'Report issue', 'Сообщить о проблеме');
  String get reportIssueAction =>
      _t('Muammo bildirish', 'Report issue', 'Сообщить о проблеме');
  String get reasonLabel => _t('Sabab', 'Reason', 'Причина');
  String get returningQtyLabel => _t('Qaytarilayotgan miqdor',
      'Returning quantity', 'Возвращаемое количество');
  String get returnedQtyLabel =>
      _t('Qaytarilgan miqdor', 'Returned quantity', 'Возвращаемое количество');
  String get rejectReasonRequired => _t(
      'Sabab tanlang yoki kamida 3 harf izoh yozing',
      'Select a reason or enter at least 3 characters',
      'Выберите причину или введите минимум 3 символа');
  String get rejectReasonDefective => _t('Yaroqsiz', 'Defective', 'Брак');
  String get rejectReasonWrongItem =>
      _t('Noto‘g‘ri mahsulot', 'Wrong item', 'Неверный товар');
  String get rejectReasonQtyMismatch =>
      _t('Miqdor noto‘g‘ri', 'Quantity mismatch', 'Неверное количество');
  String get extraCommentLabel => _t('Izoh', 'Comment', 'Комментарий');
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
