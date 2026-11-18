include .make_scripts/release-management/release-management-makefile
# This includes make: tag-major, tag-major-beta, tag-minor, tag-minor-beta, tag-patch, tag-patch-beta, tag-latest-beta, tag-major-minor-ruleset, hard-reset-tags, check-for-release and sync-release-assets.

OTP_VERSION    := $(shell awk '$$1=="erlang"{print $$2}' .tool-versions)
ELIXIR_VERSION := $(shell awk '$$1=="elixir"{sub(/-otp.*/,"",$$2);print $$2}' .tool-versions)

.PHONY: docker-build
docker-build:
	docker build --build-arg OTP_VERSION=$(OTP_VERSION) --build-arg ELIXIR_VERSION=$(ELIXIR_VERSION) -t data_aggregator:local .
