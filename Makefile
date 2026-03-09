API_URL ?= http://127.0.0.1:8081

.PHONY: run web analyze test deps

deps:
	@flutter pub get

run: deps
	@flutter run -d linux --dart-define=MOBILE_API_BASE_URL=$(API_URL)

web: deps
	@flutter run -d chrome --dart-define=MOBILE_API_BASE_URL=$(API_URL)

analyze:
	@flutter analyze

test:
	@flutter test
