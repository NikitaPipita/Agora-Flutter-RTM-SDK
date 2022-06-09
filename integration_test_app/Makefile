# This will run Agora RTM smoke tests
define run_web_smoke_testing
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/agora_rtm_smoke_test.dart -d web-server
endef

# This will run Agora RTM main tests
define run_web_testing
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/agora_rtm_test.dart -d web-server
endef

# This will run all integration tests
define run_device_testing
flutter test integration_test
endef

web_smoke_testing:
	$(run_web_smoke_testing)

web_testing:
	$(run_web_testing)

device_testing:
	$(run_device_testing)