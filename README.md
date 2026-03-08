# Mobile App

Flutter Android-first app skeleton for the supplier and werka workflow.

## Bu dastur qayerdan ochildi

VS Code ichidagi terminaldan shu papka ichida ochilgan:

```bash
cd /home/wikki/local.git/erpnext_stock_telegram/mobile_app
flutter run -d linux --dart-define=MOBILE_API_BASE_URL=http://127.0.0.1:8081
```

## Eng qulay qayta ochish usuli

Shu papka ichida tayyor script bor:

```bash
cd /home/wikki/local.git/erpnext_stock_telegram/mobile_app
./run_linux_preview.sh
```

## Muhim

Mobile app ishlashi uchun backend ham turishi kerak:

```bash
cd /home/wikki/local.git/erpnext_stock_telegram
go run ./cmd/mobileapi
```

Keyin alohida terminalda mobile app:

```bash
cd /home/wikki/local.git/erpnext_stock_telegram/mobile_app
./run_linux_preview.sh
```

## Optional web preview

```bash
cd /home/wikki/local.git/erpnext_stock_telegram/mobile_app
flutter run -d chrome --dart-define=MOBILE_API_BASE_URL=http://127.0.0.1:8081
```
