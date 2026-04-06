.PHONY: help list

help:
	@echo ""
	@echo "GenAI Tooling:"
	@echo "    make rules-generate        Generate AI agent rules files"
	@echo ""

list:
	@grep '^[^#[:space:]].*:' Makefile

.PHONY: rules-generate

# rulesync rewrites the Codex MCP section, so reapply Codex-only approval
# blocks after generation.
rules-generate:
	rulesync generate --delete -f rules,skills,mcp,ignore -t agentsmd,agentsskills,claudecode,codexcli,opencode,cursor,copilot
	dart tool/sync_codex_dart_mcp_approvals.dart
