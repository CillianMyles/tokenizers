.PHONY: help list fmt lint test codegen run run-web run-macos rules-generate

help:
	@echo ""
	@echo "Project Commands:"
	@echo "    make fmt                   Format Dart code"
	@echo "    make lint                  Analyze Dart code"
	@echo "    make test                  Run Flutter tests"
	@echo "    make codegen               Regenerate Drift database code"
	@echo ""
	@echo "Run Commands:"
	@echo "    make run                   Run on Chrome with env"
	@echo "    make run-web               Run on Chrome with env"
	@echo "    make run-macos             Run on macOS with env"
	@echo ""
	@echo "    For mobile targets, pass a device ID:"
	@echo "    flutter run --dart-define-from-file=.env -d <device_id>"
	@echo "    Run 'flutter devices' to list available devices."
	@echo ""
	@echo "GenAI Tooling:"
	@echo "    make rules-generate        Generate AI agent rules files"
	@echo ""

list:
	@awk -F: '/^[[:alnum:]_-]+:/ { print $$1 }' Makefile

fmt:
	dart format .

lint:
	dart analyze

test:
	flutter test

codegen:
	dart run build_runner build --delete-conflicting-outputs

run: run-web

run-web:
	flutter run --dart-define-from-file=.env -d chrome

run-macos:
	flutter run --dart-define-from-file=.env -d macos

# rulesync rewrites the Codex MCP section, so reapply Codex-only approval
# blocks after generation.
rules-generate:
	rulesync generate --delete -f rules,skills,mcp,ignore -t agentsmd,agentsskills,claudecode,codexcli,opencode,cursor,copilot
	dart tool/sync_codex_dart_mcp_approvals.dart
