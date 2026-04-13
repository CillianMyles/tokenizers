.PHONY: help list fmt lint test run rules-generate

help:
	@echo ""
	@echo "Project Commands:"
	@echo "    make fmt                   Format Dart code"
	@echo "    make lint                  Analyze Dart code"
	@echo "    make test                  Run Flutter tests"
	@echo "    make run                   Run Flutter with dart defines from .env"
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

run:
	flutter run --dart-define-from-file=.env

# rulesync rewrites the Codex MCP section, so reapply Codex-only approval
# blocks after generation.
rules-generate:
	rulesync generate --delete -f rules,skills,mcp,ignore -t agentsmd,agentsskills,claudecode,codexcli,opencode,cursor,copilot
	dart tool/sync_codex_dart_mcp_approvals.dart
