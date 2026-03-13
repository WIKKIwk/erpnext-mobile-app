# Accord Mobile App

`Accord Mobile App` bu Flutter asosida yozilgan Android-first operatsion mobil ilova bo‘lib, ERPNext bilan ishlaydigan ombor va ta’minot jarayonlarini soddalashtirish uchun ishlab chiqilgan. Ilova 3 xil rolda ishlaydi:

- `Supplier`
- `Werka`
- `Admin`

Bu client ilova mustaqil biznes-logic yozmaydi. Asosiy qoidalar va ERP bilan integratsiya server tomonda bajariladi. Mobil ilovaning vazifasi:

- foydalanuvchini autentifikatsiya qilish
- kerakli API endpointlarga xavfsiz so‘rov yuborish
- role-based ekranlarni ko‘rsatish
- push, local alert, unread, cache, offline warning kabi UX qatlamini boshqarish

## 1. Loyiha maqsadi

Ilova quyidagi real biznes muammolarini hal qilish uchun qurilgan:

- supplier jo‘natgan mahsulotlarni `Werka` tomonidan qabul qilish
- qisman qabul qilish yoki qaytarish sabablarini qayd etish
- supplier va werka o‘rtasidagi kelishmovchiliklarni mobil oqim orqali boshqarish
- admin uchun supplierlar, itemlar, werka sozlamalari va activity monitoring
- ERPNext source’ga tegmasdan, faqat API orqali xavfsiz integratsiya qilish

Qisqa qilib:

- `Mobile App -> mobile_server -> ERPNext`

## 2. Arxitektura

Ilova quyidagi 3 asosiy qatlamga bo‘lingan:

1. `Presentation`
   - ekranlar
   - dialoglar
   - dock navigation
   - local UI state

2. `Core`
   - API client
   - session management
   - local cache
   - unread state
   - theme
   - app lock
   - runtime refresh

3. `Shared Models`
   - role, record, summary, detail, form argument modellari

Asosiy fayllar:

- `[main.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/main.dart)`
- `[app.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/app/app.dart)`
- `[app_router.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/app/app_router.dart)`
- `[mobile_api.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/api/mobile_api.dart)`
- `[app_models.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/features/shared/models/app_models.dart)`

## 3. Role bo‘yicha imkoniyatlar

### `Supplier`

`Supplier` oqimi quyidagilarni bajaradi:

- home summary:
  - `Jarayonda`
  - `Submit`
  - `Qaytarilgan`
- item tanlash
- miqdor kiritish
- jo‘natma yaratish
- history/recent ko‘rish
- detail ichida status va qaytarish note’larini ko‘rish
- kerakli hollarda `Werka` yoki boshqa qarama-qarshi oqimlardan javoblarni ko‘rish

### `Werka`

`Werka` oqimi quyidagilarni bajaradi:

- home summary:
  - `Jarayonda`
  - `Tasdiqlangan`
  - `Qaytarilgan`
- pending receiptlarni ko‘rish
- qabul qilish
- qisman qaytarish
- to‘liq qaytarish
- `Aytilmagan mol` oqimi
- `Mol jo‘natish` oqimi
- history/feed ko‘rish

### `Admin`

`Admin` quyidagilarni boshqaradi:

- ERP va default sozlamalar
- supplierlar ro‘yxati
- inactive / blocked supplierlar
- supplier detail
- supplier item assignment
- item create
- werka sozlamalari
- system activity feed

## 4. Hozirgi asosiy biznes oqimlar

### 4.1 Supplier jo‘natma oqimi

1. Supplier item tanlaydi
2. miqdor kiritadi
3. tasdiqlaydi
4. server `Purchase Receipt` draft yaratadi
5. `Werka` uni qabul qiladi yoki qaytaradi

### 4.2 Werka qabul oqimi

1. `Werka` pending receipt ochadi
2. to‘liq qabul / qisman qabul / to‘liq qaytarish tanlaydi
3. kerakli note va sabab yozadi
4. server ERP hujjatini submit yoki qaytarish logikasi bilan qayta ishlaydi

### 4.3 Aytilmagan mol oqimi

1. `Werka` `+` bosadi
2. `Aytilmagan mol`
3. supplier tanlaydi
4. item tanlaydi
5. miqdor kiritadi
6. draft yaratiladi
7. supplier keyin tasdiqlaydi yoki rad etadi

### 4.4 Mol jo‘natish oqimi

Hozirgi holatda:

1. `Werka` `+` bosadi
2. `Mol jo‘natish`
3. customer tanlaydi
4. o‘sha customerga bog‘langan itemlar chiqadi
5. item tanlanadi
6. miqdor kiritiladi
7. tasdiqlanadi
8. server `Delivery Note` yaratadi

Muhim:

- bu oqim `Stock Entry` emas
- hozir `Delivery Note` yaratadi
- customer-item mapping `Item.customer_items` child-table’dan olinadi

## 5. UI tamoyillari

Ilova dizayni bir nechta qat’iy prinsip asosida qurilgan:

- `dark/light` theme qo‘llab-quvvatlanadi
- action cardlar grouped section ko‘rinishida
- separator bilan ajratilgan row’lar
- dock-based navigation
- bosilganda `ripple + press feedback`
- role bo‘yicha bir xil interaction pattern
- minimal, enterprise-style axborot taqdimoti

Asosiy shared UI komponentlar:

- `[common_widgets.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/widgets/common_widgets.dart)`
- `[app_shell.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/widgets/app_shell.dart)`
- `[motion_widgets.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/widgets/motion_widgets.dart)`

## 6. State va local persistence

Ilova server response’lariga to‘liq qaram bo‘lib qolmasligi uchun local state va persistence ishlatadi.

Asosiy local storage qatlamlari:

- `AppSession`
- `JsonCacheStore`
- `NotificationUnreadStore`
- `NotificationHiddenStore`
- `SecurityController`
- `ThemeController`

### Cache-first

Muhim screenlar:

- avval local cached data ko‘rsatadi
- keyin background’da network refresh qiladi

Bu yondashuv:

- loading vaqtini kamaytiradi
- eski data bilan bo‘lsa ham ekranni bo‘sh qoldirmaydi
- internet sekin bo‘lsa ham UX’ni yaxshilaydi

### Feed hidden / clear logic

Feed screenlarda `tozalash` tugmasi bor:

- supplier feed
- werka feed
- admin activity

Bu serverdan o‘chirish emas.
Bu local `hide` mexanizmi.

Yani:

- joriy feed yozuvlari local yashiriladi
- keyin yangi yozuvlar kelishi davom etadi

## 7. Push, unread va runtime refresh

### Push qatlamlari

Ilovada 2 qatlamli signal tizimi bor:

1. serverdan FCM push
2. app ichida runtime poll + local alert

Asosiy fayllar:

- `[push_messaging_service.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/notifications/push_messaging_service.dart)`
- `[notification_runtime.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/notifications/notification_runtime.dart)`
- `[notification_unread_store.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/notifications/notification_unread_store.dart)`
- `[notification_hidden_store.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/notifications/notification_hidden_store.dart)`
- `[local_notification_service.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/notifications/local_notification_service.dart)`

### Muhim qoidalar

- unread badge faqat real unread ID bo‘lsa ko‘rinadi
- stale unread ID’lar prune qilinadi
- hidden qilingan yozuvlar badge’ni ushlab turmaydi
- detail ochilganda yozuv `seen` bo‘ladi
- noto‘g‘ri role uchun kelgan push ignore qilinadi

## 8. Offline va internetga bog‘liq holatlar

Ilovada internet yo‘q paytdagi foydalanuvchi tajribasi uchun maxsus qatlam bor.

Asosiy fayllar:

- `[network_required_dialog.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/network/network_required_dialog.dart)`
- `[network_requirement_runtime.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/network/network_requirement_runtime.dart)`

### Nima bo‘ladi

- app qora ekranda osilib qolmaydi
- agar backend kerak bo‘lsa va internet bo‘lmasa:
  - blur fonli dialog chiqadi
  - foydalanuvchiga internet kerakligi aytiladi
  - `Yopish` tugmasi bo‘ladi

## 9. Security

Ilovada PIN lock va biometrik unlock mavjud.

Asosiy security fayllar:

- `[security_controller.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/security/security_controller.dart)`
- `[app_lock_gate.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/core/security/app_lock_gate.dart)`
- `[pin_setup_entry_screen.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/features/shared/presentation/pin_setup_entry_screen.dart)`
- `[pin_setup_confirm_screen.dart](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/lib/src/features/shared/presentation/pin_setup_confirm_screen.dart)`

Imkoniyatlar:

- 4 xonali PIN
- PIN current account bo‘yicha alohida saqlanadi
- biometrik unlock
- app background’dan qaytganda lock

## 10. Android integratsiya

Muhim Android komponentlar:

- `[AndroidManifest.xml](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/android/app/src/main/AndroidManifest.xml)`
- `[android/app/build.gradle.kts](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/android/app/build.gradle.kts)`
- `[android/build.gradle.kts](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/android/build.gradle.kts)`

Android tarafdagi muhim integratsiyalar:

- FCM
- local notifications
- launcher icon
- desugaring
- permission handling

## 11. Fayl tuzilmasi

Qisqacha xarita:

```text
mobile_app/
├── android/
├── assets/
│   └── icons/
├── lib/
│   ├── main.dart
│   └── src/
│       ├── app/
│       ├── core/
│       │   ├── api/
│       │   ├── cache/
│       │   ├── network/
│       │   ├── notifications/
│       │   ├── security/
│       │   ├── session/
│       │   ├── theme/
│       │   └── widgets/
│       └── features/
│           ├── auth/
│           ├── supplier/
│           ├── werka/
│           ├── admin/
│           └── shared/
├── test/
├── Makefile
└── pubspec.yaml
```

## 12. Run va build buyruqlari

### Dependencies

```bash
cd /home/wikki/local.git/erpnext_stock_telegram/mobile_app
flutter pub get
```

### Linux preview

```bash
cd /home/wikki/local.git/erpnext_stock_telegram/mobile_app
make run
```

Bu:

- local backend/core’ni ko‘taradi
- Flutter Linux preview’ni ishga tushiradi

### Web preview

```bash
cd /home/wikki/local.git/erpnext_stock_telegram/mobile_app
make web
```

### Domain build

User uchun to‘g‘ri APK build:

```bash
cd /home/wikki/local.git/erpnext_stock_telegram/mobile_app
make apk-domain APK_NAME=accord.apk
```

Natija:

- `[accord.apk](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/build/app/outputs/flutter-apk/accord.apk)`

### Remote/tunnel build

```bash
cd /home/wikki/local.git/erpnext_stock_telegram/mobile_app
make remote-up
make apk-remote APK_NAME=accord.apk
```

## 13. Test va verification

### Static verification

```bash
cd /home/wikki/local.git/erpnext_stock_telegram/mobile_app
flutter analyze
flutter test
```

### Manual verification

Tavsiya etiladigan real testlar:

- supplier login
- werka login
- admin login
- supplier dispatch
- werka accept / partial / full return
- aytilmagan mol
- mol jo‘natish
- unread/badge
- app lock
- offline warning
- real Android APK install

## 14. Muhim Make targetlar

`[Makefile](/home/wikki/local.git/erpnext_stock_telegram/mobile_app/Makefile)` ichidagi asosiy targetlar:

- `make deps`
- `make run`
- `make web`
- `make core-up`
- `make core-stop`
- `make remote-up`
- `make remote-stop`
- `make domain-up`
- `make apk-remote`
- `make apk-domain`
- `make analyze`
- `make test`

## 15. Environment va build define

Muhim `dart-define`:

- `MOBILE_API_BASE_URL`

Default:

```text
http://127.0.0.1:8081
```

APK uchun odatda domain build ishlatiladi.

## 16. Muhim local-only fayllar

Commit qilinmasligi kerak:

- `android/app/google-services.json`
- local secretlar
- developer machine’ga xos build fayllari

## 17. Kuchli tomonlar

Loyihaning texnik kuchli taraflari:

- role-based architecture
- ERPNext API bilan mustaqil mobil client
- push + local runtime signal
- cache-first UX
- grouped enterprise UI
- app lock va biometrik unlock
- offline ogohlantirish
- Delivery Note va Purchase Receipt asosidagi real biznes oqimlar

## 18. Himoya uchun qisqa gap

Agar siz bu loyihani himoya qilayotgan bo‘lsangiz, qisqa ta’rif:

> Accord Mobile App bu ERPNext asosida ishlovchi supplier, werka va admin foydalanuvchilari uchun qurilgan operatsion mobil platforma bo‘lib, real ombor, jo‘natma, qabul va nazorat jarayonlarini mobil qurilmada boshqarish imkonini beradi. Ilova role-based arxitektura, push xabarlash, local cache, PIN xavfsizlik va offline ogohlantirish kabi ishlab chiqarish darajasidagi imkoniyatlarni o‘z ichiga oladi.

## 19. Keyingi rivojlantirish yo‘nalishlari

Potensial keyingi bosqichlar:

- customer login
- delivery note confirmation chain
- richer analytics
- audit timeline
- searchable global activity
- multi-device unread sync
- stronger offline mode
- background sync optimization

## 20. Yakun

Bu repo shunchaki Flutter demo emas. Bu real biznes oqimlari bilan ishlaydigan, ERPNext bilan integratsiyalashgan, security, cache, push, role-based UI va operational workflow’larni birlashtirgan production-oriented mobil clientdir.

Agar keyingi bosqichda xohlasangiz, men shu uslubda:

- `mobile_server`
- root repo (`erpnext_stock_telegram`)

uchun ham alohida mukammal README yozib beraman.
