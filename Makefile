.PHONY: install smoke feature-gates publish scrub venv

OPENCLAW_DIR ?= $(HOME)/.openclaw

venv:
	python3 -m venv $(OPENCLAW_DIR)/venv-broadlink
	$(OPENCLAW_DIR)/venv-broadlink/bin/pip install -U pip
	$(OPENCLAW_DIR)/venv-broadlink/bin/pip install -r requirements.txt

install:
	bash scripts/install-to-openclaw.sh --force

smoke:
	bash scripts/broadlink-smoke.sh

feature-gates:
	bash scripts/broadlink-feature-gates.sh

scrub:
	bash scripts/scrub-for-publish.sh

publish: scrub smoke feature-gates
	@echo "BROADLINK_PUBLISH_OK"

test:
	python3 -m pytest tests/broadlink -q
