.PHONY: help list run rules-generate

help:
	@echo ""
	@echo "GenAI Tooling:"
	@echo "    make run                   Run Flutter with dart defines from .env"
	@echo "    make rules-generate        Generate AI agent rules files"
	@echo ""

list:
	@awk -F: '/^[[:alnum:]_-]+:/ { print $$1 }' Makefile

run:
	flutter run --dart-define-from-file=.env

# rulesync rewrites the Codex MCP section, so reapply Codex-only approval
# blocks after generation.
rules-generate:
	rulesync generate --delete -f rules,skills,mcp,ignore -t agentsmd,agentsskills,claudecode,codexcli,opencode,cursor,copilot
	dart tool/sync_codex_dart_mcp_approvals.dart
