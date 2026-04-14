.DEFAULT_GOAL := help
SHELL := /bin/bash

HARNESS_DIR := $(shell cd "$(dir $(lastword $(MAKEFILE_LIST)))" && pwd)
PROJECTS_FILE := $(HOME)/.claude-harness/projects

## ── Help ────────────────────────────────────────────
.PHONY: help
help: ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

## ── Install ─────────────────────────────────────────
.PHONY: install
install: ## Global install (hooks + commands + agents)
	@bash $(HARNESS_DIR)/scripts/install.sh

.PHONY: install-dry-run
install-dry-run: ## Dry-run install (show what would be done)
	@DRY_RUN=1 bash $(HARNESS_DIR)/scripts/install.sh

## ── Audit ───────────────────────────────────────────
.PHONY: audit
audit: ## Audit current directory (or DIR=/path)
	@bash $(HARNESS_DIR)/scripts/audit.sh $(DIR)

.PHONY: regression
regression: ## Audit all registered projects
	@bash $(HARNESS_DIR)/scripts/regression-audit.sh

## ── Templates ───────────────────────────────────────
.PHONY: validate
validate: ## Dry-run all 5 stack templates
	@for t in go node python rust flutter; do \
		echo "── Validating $$t ──"; \
		bash $(HARNESS_DIR)/scripts/bootstrap.sh --type $$t --base main --dry-run /tmp/harness-validate-$$t || exit 1; \
	done
	@echo "✓ All templates valid"

## ── Quality ─────────────────────────────────────────
.PHONY: lint
lint: ## Bash syntax check on hooks + scripts
	@echo "Checking hooks..."
	@for f in $(HARNESS_DIR)/hooks/*.sh; do bash -n "$$f" && echo "  ✓ $$(basename $$f)"; done
	@echo "Checking scripts..."
	@for f in $(HARNESS_DIR)/scripts/*.sh; do bash -n "$$f" && echo "  ✓ $$(basename $$f)"; done
	@echo "✓ All files pass syntax check"

.PHONY: test
test: lint validate ## lint + validate

## ── Projects ────────────────────────────────────────
.PHONY: register
register: ## Register a project (P=/abs/path)
	@if [ -z "$(P)" ]; then echo "Usage: make register P=/abs/path"; exit 1; fi
	@mkdir -p "$$(dirname $(PROJECTS_FILE))"
	@grep -qxF '$(P)' $(PROJECTS_FILE) 2>/dev/null || echo '$(P)' >> $(PROJECTS_FILE)
	@echo "✓ Registered: $(P)"

## ── Watch ───────────────────────────────────────────
.PHONY: watch-status
watch-status: ## Show watch sources and their status
	@bash $(HARNESS_DIR)/scripts/watch-check.sh --status

## ── Cleanup ─────────────────────────────────────────
.PHONY: clean
clean: ## Remove validation artifacts
	@rm -rf /tmp/harness-validate-*
	@echo "✓ Cleaned"
