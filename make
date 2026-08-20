#!/usr/bin/env python3
import sys
import subprocess
import os

VENV_BIN = ".venv/bin" if os.path.exists(".venv") else "env/bin"
RUFF = f"{VENV_BIN}/ruff" if os.path.exists(f"{VENV_BIN}/ruff") else "ruff"
BANDIT = f"{VENV_BIN}/bandit" if os.path.exists(f"{VENV_BIN}/bandit") else "bandit"
PYTEST = f"{VENV_BIN}/pytest" if os.path.exists(f"{VENV_BIN}/pytest") else "pytest"
PYTHON = f"{VENV_BIN}/python" if os.path.exists(f"{VENV_BIN}/python") else "python3"

def run_cmd(cmd):
    print(f"==> {cmd}")
    res = subprocess.run(cmd, shell=True)
    if res.returncode != 0:
        sys.exit(res.returncode)

def main():
    target = sys.argv[1] if len(sys.argv) > 1 else "help"
    
    if target == "lint":
        run_cmd("mkdir -p reports")
        run_cmd(f"{RUFF} check appname tests")
        run_cmd(f"{RUFF} check appname tests --output-format=json > reports/ruff.json")
        run_cmd(f"{RUFF} format --check appname tests")

    elif target == "security":
        run_cmd("mkdir -p reports")
        run_cmd(f"{BANDIT} -r appname -f json -o reports/bandit.json || true")

    elif target == "test":
        run_cmd("mkdir -p reports")
        run_cmd(f"APPNAME_ENV=test {PYTEST} --junitxml=reports/junit.xml --cov=appname --cov-report=xml:reports/coverage.xml --cov-report=html:reports/htmlcov --cov-report=term-missing")

    elif target == "test-ui":
        run_cmd("mkdir -p reports")
        run_cmd(f"APPNAME_ENV=test {PYTEST} tests/e2e/ --junitxml=reports/junit-ui.xml")

    elif target in ("reports", "ci"):
        run_cmd(f"{sys.argv[0]} lint")
        run_cmd(f"{sys.argv[0]} security")
        run_cmd(f"{sys.argv[0]} test")
        run_cmd(f"{sys.argv[0]} test-ui")
        print("\n==========================================")
        print(" Reports Generated Successfully:")
        print(" - JUnit XML Report:    reports/junit.xml")
        print(" - UI JUnit XML Report: reports/junit-ui.xml")
        print(" - Coverage XML Report: reports/coverage.xml")
        print(" - Coverage HTML Site:  reports/htmlcov/index.html")
        print(" - Bandit Security JSON: reports/bandit.json")
        print(" - Ruff Lint JSON:      reports/ruff.json")
        print("==========================================")

    elif target == "agent-test":
        run_cmd(f"APPNAME_ENV=test {PYTEST} --cov-report=term-missing --cov=appname tests/")

    else:
        print(f"Usage: {sys.argv[0]} [lint|security|test|test-ui|reports|ci|agent-test]")

if __name__ == "__main__":
    main()
