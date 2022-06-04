# This will run Agora RTM smoke tests
define run_web_smoke_testing
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/agora_rtm_smoke_test.dart -d web-server
endef

# This will run Agora RTM main tests
define run_web_testing
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/agora_rtm_test.dart -d web-server
endef

web_testing:
	$(run_web_testing)