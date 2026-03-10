API_URL ?= http://127.0.0.1:8081
JDK_HOME ?= /usr/lib/jvm/java-17-openjdk
APK_NAME ?= accord.apk

.PHONY: run web analyze test deps backend-up backend-stop core-up core-stop remote-up remote-stop remote-url apk-remote run-remote android-sdk-setup domain-up domain-url apk-domain run-domain

deps:
	@flutter pub get

android-sdk-setup:
	@./setup_android_sdk.sh

backend-up:
	@API_URL=$(API_URL) BACKEND_ROOT="$$(cd .. && pwd)" ./ensure_mobileapi.sh

core-up:
	@API_URL=$(API_URL) BACKEND_ROOT="$$(cd .. && pwd)" ./ensure_core.sh

backend-stop:
	@if [ -f .mobileapi.pid ]; then \
		kill "$$(cat .mobileapi.pid)" 2>/dev/null || true; \
		rm -f .mobileapi.pid; \
		echo "mobileapi stopped"; \
	else \
		echo "mobileapi pid file not found"; \
	fi

core-stop:
	@./stop_remote_core.sh

remote-up:
	@BACKEND_ROOT="$$(cd .. && pwd)" ./start_remote_core.sh

domain-up:
	@BACKEND_ROOT="$$(cd .. && pwd)" ./start_domain_core.sh

remote-url:
	@if [ -f .core_tunnel_url ]; then \
		cat .core_tunnel_url; \
	else \
		echo "remote URL topilmadi. Avval make remote-up ishlating."; \
		exit 1; \
	fi

domain-url:
	@if [ -f .core_domain_url ]; then \
		cat .core_domain_url; \
	else \
		echo "domain URL topilmadi. Avval make domain-up ishlating."; \
		exit 1; \
	fi

remote-stop:
	@./stop_remote_core.sh

run: backend-up deps
	@flutter run -d linux --dart-define=MOBILE_API_BASE_URL=$(API_URL)

web: backend-up deps
	@flutter run -d chrome --dart-define=MOBILE_API_BASE_URL=$(API_URL)

run-remote: deps remote-up
	@REMOTE_URL="$$(cat .core_tunnel_url)" && \
	flutter run -d linux --dart-define=MOBILE_API_BASE_URL="$$REMOTE_URL"

run-domain: deps domain-up
	@DOMAIN_URL="$$(cat .core_domain_url)" && \
	flutter run -d linux --dart-define=MOBILE_API_BASE_URL="$$DOMAIN_URL"

apk-remote: deps remote-up android-sdk-setup
	@REMOTE_URL="$$(cat .core_tunnel_url)" && \
	JAVA_HOME="$(JDK_HOME)" PATH="$(JDK_HOME)/bin:$$PATH" flutter build apk --release --dart-define=MOBILE_API_BASE_URL="$$REMOTE_URL" && \
	cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/$(APK_NAME) && \
	echo "APK tayyor: build/app/outputs/flutter-apk/$(APK_NAME)" && \
	echo "Core URL: $$REMOTE_URL"

apk-domain: deps domain-up android-sdk-setup
	@DOMAIN_URL="$$(cat .core_domain_url)" && \
	JAVA_HOME="$(JDK_HOME)" PATH="$(JDK_HOME)/bin:$$PATH" flutter build apk --release --dart-define=MOBILE_API_BASE_URL="$$DOMAIN_URL" && \
	cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/$(APK_NAME) && \
	echo "APK tayyor: build/app/outputs/flutter-apk/$(APK_NAME)" && \
	echo "Core URL: $$DOMAIN_URL"

analyze:
	@flutter analyze

test:
	@flutter test
