.PHONY: docs test agent-setup agent-resetdb agent-smoke agent-test lint security test-ui reports ci clean deps help

VENV_PYTHON ?= $(shell if [ -d ".venv" ]; then echo ".venv/bin/python"; elif [ -d "env" ]; then echo "env/bin/python"; else echo "python3"; fi)
RUFF ?= $(shell if [ -d ".venv" ]; then echo ".venv/bin/ruff"; elif [ -d "env" ]; then echo "env/bin/ruff"; else echo "ruff"; fi)
BANDIT ?= $(shell if [ -d ".venv" ]; then echo ".venv/bin/bandit"; elif [ -d "env" ]; then echo "env/bin/bandit"; else echo "bandit"; fi)
PYTEST ?= $(shell if [ -d ".venv" ]; then echo ".venv/bin/pytest"; elif [ -d "env" ]; then echo "env/bin/pytest"; else echo "pytest"; fi)

AGENT_TEST_FILES=$(shell git ls-files 'tests/*.py')

help:
	@echo "  env         create a development environment using virtualenv"
	@echo "  deps        install dependencies using pip"
	@echo "  clean       remove unwanted files like .pyc's"
	@echo "  lint        check style with ruff and generate reports/ruff.json"
	@echo "  security    run security analysis with bandit"
	@echo "  test        run all unit/integration tests with pytest and coverage"
	@echo "  test-ui     run Playwright E2E tests"
	@echo "  reports     run lint, security, test, and test-ui together"
	@echo "  ci          run full CI pipeline (alias for reports)"
	@echo "  agent-setup install dependencies in ./env for AI/code agents"
	@echo "  agent-resetdb reset and seed local development database"
	@echo "  agent-smoke run fast smoke tests"
	@echo "  agent-test  run full test suite with coverage"

env:
	python3 -m venv env && \
	. env/bin/activate && \
	make deps

deps:
	pip install -r requirements.txt

clean:
	find . | grep -E "(__pycache__|\.pyc|\.DS_Store|\.db|\.pyo$\)" | xargs rm -rf
	rm -rf reports/ .pytest_cache/ .coverage

lint:
	@mkdir -p reports
	$(RUFF) check appname tests
	$(RUFF) check appname tests --output-format=json > reports/ruff.json
	$(RUFF) format --check appname tests

security:
	@mkdir -p reports
	$(BANDIT) -r appname -f json -o reports/bandit.json || true

test:
	@mkdir -p reports
	APPNAME_ENV=test $(PYTEST) --junitxml=reports/junit.xml --cov=appname --cov-report=xml:reports/coverage.xml --cov-report=html:reports/htmlcov --cov-report=term-missing

test-ui:
	@mkdir -p reports
	APPNAME_ENV=test $(PYTEST) tests/e2e/ --junitxml=reports/junit-ui.xml

reports: lint security test test-ui
	@echo ""
	@echo "=========================================="
	@echo " Reports Generated Successfully:"
	@echo " - JUnit XML Report:    reports/junit.xml"
	@echo " - UI JUnit XML Report: reports/junit-ui.xml"
	@echo " - Coverage XML Report: reports/coverage.xml"
	@echo " - Coverage HTML Site:  reports/htmlcov/index.html"
	@echo " - Bandit Security JSON: reports/bandit.json"
	@echo " - Ruff Lint JSON:      reports/ruff.json"
	@echo "=========================================="

ci: reports

agent-setup:
	python3 -m venv env
	$(VENV_PYTHON) -m pip install --upgrade pip
	$(VENV_PYTHON) -m pip install -r requirements.txt

agent-resetdb:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=dev $(VENV_PYTHON) manage.py resetdb

agent-smoke:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=test $(VENV_PYTHON) -m pytest -q tests/test_urls.py tests/test_login.py

agent-test:
	@if [ ! -x "$(VENV_PYTHON)" ]; then echo "Run 'make agent-setup' first."; exit 1; fi
	APPNAME_ENV=test $(VENV_PYTHON) -m pytest --cov-report=term-missing --cov=appname $(AGENT_TEST_FILES)
