API_URL ?= https://core.wspace.sbs
LOCAL_API_URL ?= http://127.0.0.1:8081
JDK_HOME ?= /usr/lib/jvm/java-17-openjdk
APK_NAME ?= accord.apk
ERP_ROOT ?= ../../erpnext_n1/erp
HOST_OS := $(shell uname -s)

ifeq ($(HOST_OS),Darwin)
RUN_DEVICE ?= chrome
RUN_DART_DEFINES ?= --dart-define=APP_FORCE_DEVICE_PREVIEW=true
else
RUN_DEVICE ?= linux
RUN_DART_DEFINES ?=
endif

CHROME_WEB_BROWSER_FLAGS := --web-browser-flag=--disable-web-security --web-browser-flag=--disable-site-isolation-trials --web-browser-flag=--user-data-dir=$(CURDIR)/.chrome-dev-profile
ifeq ($(RUN_DEVICE),chrome)
RUN_BROWSER_FLAGS := $(CHROME_WEB_BROWSER_FLAGS)
else
RUN_BROWSER_FLAGS :=
endif

# Release APKs: arm64-v8a only (typical phones); no universal/fat APK.
FLUTTER_APK_RELEASE_FLAGS := --release --target-platform android-arm64

.PHONY: run web analyze test deps backend-up backend-stop core-up core-stop remote-up remote-stop remote-url apk apk-remote run-remote android-sdk-setup domain-up domain-up-fast domain-url apk-domain run-domain bench-start bench-restart bench-stop bench-limit-start bench-limit-stop prepare-run run-local web-local

deps:
	@flutter pub get

android-sdk-setup:
	@./tools/bootstrap/setup_android_sdk.sh

backend-up:
	@API_URL=$(API_URL) BACKEND_ROOT="$$(cd .. && pwd)" ./tools/bootstrap/ensure_mobileapi.sh

prepare-run:
	@case "$(API_URL)" in \
		http://127.0.0.1:*|http://localhost:*|https://127.0.0.1:*|https://localhost:*) \
			echo "Using local API: $(API_URL)"; \
			API_URL=$(API_URL) BACKEND_ROOT="$$(cd .. && pwd)" ./tools/bootstrap/ensure_mobileapi.sh ;; \
		*) \
			echo "Using external API: $(API_URL)" ;; \
	esac

core-up:
	@API_URL=$(API_URL) BACKEND_ROOT="$$(cd .. && pwd)" ./tools/bootstrap/ensure_core.sh

bench-start:
	@$(ERP_ROOT)/restart_bench.sh

bench-restart: bench-start

bench-stop:
	@$(ERP_ROOT)/stop_bench.sh

bench-limit-start:
	@$(ERP_ROOT)/start_limited_bench.sh

bench-limit-stop:
	@$(ERP_ROOT)/stop_limited_bench.sh

backend-stop:
	@if [ -f garbage/.mobileapi.pid ]; then \
		kill "$$(cat garbage/.mobileapi.pid)" 2>/dev/null || true; \
		rm -f garbage/.mobileapi.pid; \
		echo "mobileapi stopped"; \
	else \
		echo "mobileapi pid file not found"; \
	fi

core-stop:
	@./tools/runtime/stop_remote_core.sh

remote-up:
	@BACKEND_ROOT="$$(cd .. && pwd)" ./tools/runtime/start_remote_core.sh

domain-up:
	@BACKEND_ROOT="$$(cd .. && pwd)" ./tools/runtime/start_domain_core.sh

domain-up-fast:
	@SKIP_PUBLIC_HEALTHCHECK=1 BACKEND_ROOT="$$(cd .. && pwd)" ./tools/runtime/start_domain_core.sh

remote-url:
	@if [ -f garbage/.core_tunnel_url ]; then \
		cat garbage/.core_tunnel_url; \
	else \
		echo "remote URL topilmadi. Avval make remote-up ishlating."; \
		exit 1; \
	fi

domain-url:
	@if [ -f garbage/.core_domain_url ]; then \
		cat garbage/.core_domain_url; \
	else \
		echo "domain URL topilmadi. Avval make domain-up ishlating."; \
		exit 1; \
	fi

remote-stop:
	@./tools/runtime/stop_remote_core.sh

run: prepare-run deps
	@flutter run -d $(RUN_DEVICE) $(RUN_BROWSER_FLAGS) --dart-define=MOBILE_API_BASE_URL=$(API_URL) $(RUN_DART_DEFINES)

web: prepare-run deps
	@flutter run -d chrome $(CHROME_WEB_BROWSER_FLAGS) --dart-define=MOBILE_API_BASE_URL=$(API_URL)

run-local: API_URL=$(LOCAL_API_URL)
run-local: run

web-local: API_URL=$(LOCAL_API_URL)
web-local: web

run-remote: deps remote-up
	@REMOTE_URL="$$(cat garbage/.core_tunnel_url)" && \
	flutter run -d linux --dart-define=MOBILE_API_BASE_URL="$$REMOTE_URL"

run-domain: deps domain-up
	@DOMAIN_URL="$$(cat garbage/.core_domain_url)" && \
	flutter run -d linux --dart-define=MOBILE_API_BASE_URL="$$DOMAIN_URL"

apk: deps android-sdk-setup
	@JAVA_HOME="$(JDK_HOME)" PATH="$(JDK_HOME)/bin:$$PATH" flutter build apk $(FLUTTER_APK_RELEASE_FLAGS) --dart-define=MOBILE_API_BASE_URL=$(API_URL) && \
	cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/$(APK_NAME) && \
	echo "APK (arm64-v8a): build/app/outputs/flutter-apk/$(APK_NAME)" && \
	echo "API: $(API_URL)"

apk-remote: deps remote-up android-sdk-setup
	@REMOTE_URL="$$(cat garbage/.core_tunnel_url)" && \
	JAVA_HOME="$(JDK_HOME)" PATH="$(JDK_HOME)/bin:$$PATH" flutter build apk $(FLUTTER_APK_RELEASE_FLAGS) --dart-define=MOBILE_API_BASE_URL="$$REMOTE_URL" && \
	cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/$(APK_NAME) && \
	echo "APK (arm64-v8a) tayyor: build/app/outputs/flutter-apk/$(APK_NAME)" && \
	echo "Core URL: $$REMOTE_URL"

apk-domain: deps domain-up android-sdk-setup
	@DOMAIN_URL="$$(cat garbage/.core_domain_url)" && \
	JAVA_HOME="$(JDK_HOME)" PATH="$(JDK_HOME)/bin:$$PATH" flutter build apk $(FLUTTER_APK_RELEASE_FLAGS) --dart-define=MOBILE_API_BASE_URL="$$DOMAIN_URL" && \
	cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/$(APK_NAME) && \
	echo "APK (arm64-v8a) tayyor: build/app/outputs/flutter-apk/$(APK_NAME)" && \
	echo "Core URL: $$DOMAIN_URL"

analyze:
	@flutter analyze

test:
	@flutter test
