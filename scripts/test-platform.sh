#!/usr/bin/env bash

# Fixture tests for AI Platform bootstrap and doctor.
# Does not modify application projects. Does not install Composer packages.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

export AI_BOOTSTRAP_SKIP_SKILLS=1

PASSES=0
FAILURES=0

pass() {
  echo "PASS  $1"
  PASSES=$((PASSES + 1))
}

fail() {
  echo "FAIL  $1"
  FAILURES=$((FAILURES + 1))
}

assert_file() {
  local path="$1"
  local label="$2"
  if [[ -f "${path}" ]]; then
    pass "${label}"
  else
    fail "${label} (missing ${path})"
  fi
}

assert_missing() {
  local path="$1"
  local label="$2"
  if [[ ! -e "${path}" ]]; then
    pass "${label}"
  else
    fail "${label} (unexpected ${path})"
  fi
}

assert_dir() {
  local path="$1"
  local label="$2"
  if [[ -d "${path}" ]]; then
    pass "${label}"
  else
    fail "${label} (missing directory ${path})"
  fi
}

assert_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -qE "${pattern}" "${file}"; then
    pass "${label}"
  else
    fail "${label}"
  fi
}

assert_not_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -qE "${pattern}" "${file}"; then
    fail "${label}"
  else
    pass "${label}"
  fi
}

write_laravel_composer() {
  local dir="$1"
  local with_boost="${2:-0}"
  if [[ "${with_boost}" == "1" ]]; then
    cat > "${dir}/composer.json" <<'EOF'
{
  "require": {
    "php": "^8.3",
    "laravel/framework": "^13.0"
  },
  "require-dev": {
    "laravel/boost": "^2.4"
  }
}
EOF
  else
    cat > "${dir}/composer.json" <<'EOF'
{
  "require": {
    "php": "^8.3",
    "laravel/framework": "^13.0"
  }
}
EOF
  fi
}

write_radicle_composer() {
  local dir="$1"
  cat > "${dir}/composer.json" <<'EOF'
{
  "require": {
    "php": "^8.2",
    "roots/acorn": "^5.0",
    "roots/radicle": "*"
  }
}
EOF
}

WORKDIR="${AI_REPO}/.build/platform-tests"
LOGDIR="${WORKDIR}/logs"
rm -rf "${WORKDIR}"
mkdir -p "${LOGDIR}"

echo "=== AI Platform tests ==="
echo "Fixtures: ${WORKDIR}"
echo ""

echo "--- Syntax ---"
for script in \
  "${AI_REPO}/scripts/bootstrap-project.sh" \
  "${AI_REPO}/scripts/doctor.sh" \
  "${AI_REPO}/scripts/link-rules.sh" \
  "${AI_REPO}/scripts/export-chatgpt-context.sh" \
  "${AI_REPO}/scripts/update-skills.sh" \
  "${AI_REPO}/scripts/lib/project-capabilities.sh" \
  "${AI_REPO}/scripts/test-platform.sh"
do
  if bash -n "${script}"; then
    pass "bash -n $(basename "${script}")"
  else
    fail "bash -n $(basename "${script}")"
  fi
done

echo ""
echo "--- Onboarding docs ---"
assert_file "${AI_REPO}/core/prompts/project-adoption.md" \
  "project adoption prompt exists"
assert_file "${AI_REPO}/README.md" "README exists"
assert_grep '^# AI Development Harness' "${AI_REPO}/README.md" \
  "README uses the public product title"
assert_grep '^Version 1\.2\.0$' "${AI_REPO}/README.md" \
  "README reports harness version 1.2.0"
assert_file "${AI_REPO}/CHANGELOG.md" "CHANGELOG exists"
assert_grep '^## 1\.2\.0' "${AI_REPO}/CHANGELOG.md" \
  "CHANGELOG has a 1.2.0 entry"
assert_grep 'Version 1\.2\.0' "${AI_REPO}/docs/99-project-status.md" \
  "status document reports version 1.2.0"
assert_grep '^Version 1\.2\.0$' "${AI_REPO}/docs/00-project-context.md" \
  "project context reports version 1.2.0"
assert_file "${AI_REPO}/LICENSE" "LICENSE exists"
assert_grep 'MIT License' "${AI_REPO}/LICENSE" \
  "LICENSE is MIT"
assert_grep 'Joe Conlin' "${AI_REPO}/LICENSE" \
  "LICENSE names the copyright holder"
assert_grep '2026' "${AI_REPO}/LICENSE" \
  "LICENSE uses the current year"
assert_not_grep 'bootstrap-ai' "${AI_REPO}/README.md" \
  "README does not mention bootstrap-ai"
assert_not_grep '/Users/joeconlin' "${AI_REPO}/README.md" \
  "README does not require a personal absolute path"
assert_grep 'AI_PLATFORM=' "${AI_REPO}/README.md" \
  "README defines an AI_PLATFORM path convention"
assert_grep 'npx skills experimental_install' "${AI_REPO}/README.md" \
  "README documents skill restore from skills-lock.json"
assert_grep 'npx skills update' "${AI_REPO}/scripts/update-skills.sh" \
  "update-skills.sh is the skill-update command"
assert_grep 'npx -y @playwright/mcp@latest' "${AI_REPO}/mcp/playwright/README.md" \
  "Playwright MCP docs include the user-global npx invocation"
assert_grep 'user-global MCP servers during clone' "${AI_REPO}/mcp/README.md" \
  "MCP index states the platform does not install user-global MCP servers"
assert_grep 'install MCP servers' "${AI_REPO}/README.md" \
  "README states bootstrap does not install MCP servers"
assert_file "${AI_REPO}/core/agent-core.md" "canonical agent-core exists"
assert_file "${AI_REPO}/AGENTS.md" "platform AGENTS.md exists"
assert_file "${AI_REPO}/core/adapters/README.md" "adapter index exists"
assert_file "${AI_REPO}/core/adapters/hermes.md" "Hermes adapter documents Nous Research Hermes Agent"
assert_grep 'Does \*\*not\*\* create' "${AI_REPO}/core/adapters/hermes.md" \
  "Hermes adapter forbids creating .hermes.md"
assert_not_grep 'Not provisioned' "${AI_REPO}/core/adapters/hermes.md" \
  "Hermes adapter is no longer a stub"
assert_grep 'STOP before making any changes' "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform.mdc includes the project identity guardrail"
assert_grep 'STOP before making any changes' "${AI_REPO}/core/agent-core.md" \
  "agent-core includes the project identity guardrail"
assert_grep 'destructive database operations without approval' "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform.mdc includes destructive-database safety"
assert_grep 'destructive database operations without approval' "${AI_REPO}/core/agent-core.md" \
  "agent-core includes destructive-database safety"
assert_grep 'project dependencies or configuration without approval' "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform.mdc includes dependency-approval safety"
assert_grep 'project dependencies or configuration without approval' "${AI_REPO}/core/agent-core.md" \
  "agent-core includes dependency-approval safety"
assert_missing "${AI_REPO}/.hermes.md" "platform repo does not ship .hermes.md"
assert_missing "${AI_REPO}/HERMES.md" "platform repo does not ship HERMES.md"
assert_grep 'Hermes Agent' "${AI_REPO}/README.md" \
  "README names Hermes Agent as a supported client"
assert_grep 'You do not choose an agent during bootstrap' "${AI_REPO}/README.md" \
  "README states bootstrap does not require choosing an agent"

echo ""
echo "--- Agent continuation ---"
assert_file "${AI_REPO}/docs/working-mode.md" \
  "platform working-mode exists"
assert_file "${AI_REPO}/templates/docs/working-mode.md" \
  "working-mode template exists"
assert_file "${AI_REPO}/core/prompts/resume.md" \
  "resume prompt exists"
assert_file "${AI_REPO}/docs/contracts/adrs/0005-agent-continuation-and-concise-reporting.md" \
  "continuation ADR exists"
assert_missing "${AI_REPO}/docs/98-agent-handoff.md" \
  "platform does not use a 98-agent-handoff filename"
assert_missing "${AI_REPO}/templates/docs/98-agent-handoff.md" \
  "templates do not ship a 98-agent-handoff file"
assert_grep 'type: continuation' "${AI_REPO}/templates/docs/working-mode.md" \
  "working-mode template uses continuation type"
assert_grep 'Not project context' "${AI_REPO}/templates/docs/working-mode.md" \
  "working-mode template is not a second context document"
assert_grep 'do not copy them' "${AI_REPO}/templates/docs/working-mode.md" \
  "working-mode template forbids copying authoritative docs"
assert_grep 'docs/working-mode.md' "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform tells agents to read working-mode"
assert_grep 'docs/working-mode.md' "${AI_REPO}/core/agent-core.md" \
  "portable core tells agents to read working-mode"
assert_grep 'short completion: DONE or BLOCKED' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform defaults to concise completion"
assert_grep 'short completion: DONE or BLOCKED' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core defaults to concise completion"
assert_grep 'not after routine bounded tasks' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform does not rewrite working-mode after every task"
assert_grep 'not after routine bounded tasks' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core does not rewrite working-mode after every task"
assert_grep 'Do not routinely emit file lists' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform forbids routine file-list completions"
assert_grep 'unrelated docs' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core requires progressive disclosure on resume"
assert_grep 'type: continuation' "${AI_REPO}/.cursor/rules/10-documentation.mdc" \
  "documentation rule recognizes continuation type"
assert_grep 'not a progress log' "${AI_REPO}/docs/documentation-philosophy.md" \
  "documentation philosophy treats continuation as not a progress log"
assert_grep 'Read `docs/working-mode.md` before the first edit' \
  "${AI_REPO}/.cursor/rules/10-documentation.mdc" \
  "selective loading starts with working-mode"
assert_grep 'Do not ingest the whole documentation tree on resume' \
  "${AI_REPO}/docs/documentation-philosophy.md" \
  "philosophy forbids ingesting all docs on resume"
assert_grep 'Concise completion reporting is the default' \
  "${AI_REPO}/.cursor/rules/10-documentation.mdc" \
  "documentation rule states concise completion default"
assert_grep 'exhaustive files-changed lists' \
  "${AI_REPO}/.cursor/rules/10-documentation.mdc" \
  "documentation rule forbids routine files-changed lists"
assert_grep 'core/prompts/resume.md' "${AI_REPO}/README.md" \
  "README documents the resume prompt"
assert_grep 'current working mode for a fresh agent' "${AI_REPO}/README.md" \
  "README says what working-mode is for"
assert_grep 'when that mode changes, not after every task' \
  "${AI_REPO}/README.md" \
  "README says when to update working-mode"
assert_grep 'load working mode automatically' "${AI_REPO}/README.md" \
  "README says a bounded task is enough; always-on loads working mode"
assert_grep 're-run bootstrap to add the' "${AI_REPO}/README.md" \
  "README says existing projects get working-mode via bootstrap"
assert_grep 'Resume this project from its working mode' \
  "${AI_REPO}/core/prompts/resume.md" \
  "resume prompt orients without editing"
assert_grep 'Do not make speculative changes' \
  "${AI_REPO}/core/prompts/resume.md" \
  "resume prompt forbids speculative edits"
assert_grep 'Do not load other docs unless those files cannot answer' \
  "${AI_REPO}/core/prompts/resume.md" \
  "resume prompt does not eagerly load extra docs"
assert_not_grep '00-project-context.md' "${AI_REPO}/core/prompts/resume.md" \
  "resume prompt does not load project context by default"
assert_not_grep 'docs/README.md' "${AI_REPO}/core/prompts/resume.md" \
  "resume prompt does not load the docs index by default"
assert_grep 'working-mode.md' "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption establishes working-mode"
assert_grep 'docs/working-mode.md' "${AI_REPO}/.cursor/rules/50-workflows.mdc" \
  "workflows require a working-mode file"
working_mode_template_lines="$(wc -l < "${AI_REPO}/templates/docs/working-mode.md" | tr -d ' ')"
if [[ "${working_mode_template_lines}" -le 50 ]]; then
  pass "working-mode template stays small (${working_mode_template_lines} lines)"
else
  fail "working-mode template stays small (${working_mode_template_lines} lines)"
fi

echo ""
echo "--- Work-item lifecycle ---"
assert_file "${AI_REPO}/.cursor/rules/70-work-items.mdc" \
  "70-work-items rule exists"
assert_file "${AI_REPO}/docs/contracts/features/work-item-lifecycle.md" \
  "work-item lifecycle contract exists"
assert_file "${AI_REPO}/docs/contracts/adrs/0003-work-item-lifecycle.md" \
  "work-item lifecycle ADR exists"
assert_file "${AI_REPO}/.github/PULL_REQUEST_TEMPLATE.md" \
  "repository PR template exists"
assert_file "${AI_REPO}/templates/github/PULL_REQUEST_TEMPLATE.md" \
  "optional project PR template exists"
assert_missing "${AI_REPO}/.github/ISSUE_TEMPLATE.md" \
  "no repository Issue template file"
assert_missing "${AI_REPO}/.github/ISSUE_TEMPLATE" \
  "no repository Issue template directory"
assert_grep 'Capture, don.t expand scope' "${AI_REPO}/core/agent-core.md" \
  "agent-core includes capture-don't-expand"
assert_grep 'Capture, don.t expand scope' "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform includes capture-don't-expand"
assert_grep 'Never auto-merge' "${AI_REPO}/core/agent-core.md" \
  "agent-core forbids auto-merge"
assert_grep 'Never auto-merge' "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform forbids auto-merge"
assert_grep 'Never push unless' "${AI_REPO}/core/agent-core.md" \
  "agent-core requires push authorization"
assert_grep 'Push unless explicitly instructed' "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform requires push authorization"
assert_grep '70-work-items' "${AI_REPO}/core/agent-core.md" \
  "agent-core selective rules include 70-work-items"
assert_grep 'Do not create empty PRs' \
  "${AI_REPO}/docs/contracts/features/work-item-lifecycle.md" \
  "contract forbids empty PRs as backlog"
assert_grep 'Do not expand scope in the PR' \
  "${AI_REPO}/.cursor/rules/70-work-items.mdc" \
  "work-items rule forbids PR scope expansion"
assert_grep 'gh. is \*\*optional\*\*' \
  "${AI_REPO}/docs/contracts/features/work-item-lifecycle.md" \
  "contract marks gh as optional"
assert_grep 'not a bootstrap dependency' \
  "${AI_REPO}/.cursor/rules/70-work-items.mdc" \
  "work-items rule does not make gh a bootstrap dependency"
assert_grep 'a replacement for canonical project documentation' \
  "${AI_REPO}/docs/contracts/features/work-item-lifecycle.md" \
  "contract distinguishes Issues from project docs"
assert_grep 'Discrete future work' \
  "${AI_REPO}/docs/contracts/features/work-item-lifecycle.md" \
  "contract assigns Issues to discrete future work"
assert_grep '## 10. Issues and pull requests' "${AI_REPO}/README.md" \
  "README has an Issues and pull requests section"
assert_grep 'gh. is' "${AI_REPO}/README.md" \
  "README states gh is optional"
assert_grep 'Existing project Issue/PR/branch' "${AI_REPO}/README.md" \
  "README states existing project conventions are respected"
assert_grep 'GitHub / contribution conventions' \
  "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption inspects existing GitHub conventions"
assert_not_grep '^\- \[ \]' "${AI_REPO}/.github/PULL_REQUEST_TEMPLATE.md" \
  "PR template is not checkbox-heavy"
pr_template_lines="$(wc -l < "${AI_REPO}/.github/PULL_REQUEST_TEMPLATE.md" | tr -d ' ')"
if [[ "${pr_template_lines}" -le 30 ]]; then
  pass "PR template is concise (${pr_template_lines} lines)"
else
  fail "PR template is concise (${pr_template_lines} lines)"
fi
assert_not_grep 'GitHub CLI is required' "${AI_REPO}/core/adapters/README.md" \
  "adapter index does not require GitHub CLI"
assert_not_grep 'gh issue' "${AI_REPO}/core/adapters/cursor.md" \
  "Cursor adapter is unchanged regarding gh Issues"
assert_not_grep 'gh pr' "${AI_REPO}/core/adapters/hermes.md" \
  "Hermes adapter is unchanged regarding gh PRs"

echo ""
echo "--- Design stack ---"
assert_file "${AI_REPO}/.cursor/rules/40-ui.mdc" "40-ui rule exists"
assert_file "${AI_REPO}/docs/contracts/adrs/0004-design-stack-and-ui-visual-verification.md" \
  "design-stack ADR exists"
assert_dir "${AI_REPO}/.agents/skills/hallmark" "Hallmark skill is present"
assert_file "${AI_REPO}/.claude/skills/hallmark/SKILL.md" \
  "Claude adapter exposes Hallmark"
assert_file "${AI_REPO}/.grok/skills/hallmark/SKILL.md" \
  "Grok adapter exposes Hallmark"
assert_missing "${AI_REPO}/.agents/skills/frontend-design" \
  "frontend-design is not in the managed skill stack"
assert_missing "${AI_REPO}/.agents/skills/ui-ux-pro-max" \
  "ui-ux-pro-max is not in the managed skill stack"
assert_missing "${AI_REPO}/.agents/skills/superdesign" \
  "superdesign is not in the managed skill stack"
assert_missing "${AI_REPO}/.claude/skills/frontend-design" \
  "Claude adapter does not expose frontend-design"
assert_missing "${AI_REPO}/.claude/skills/ui-ux-pro-max" \
  "Claude adapter does not expose ui-ux-pro-max"
assert_missing "${AI_REPO}/.claude/skills/superdesign" \
  "Claude adapter does not expose superdesign"
assert_missing "${AI_REPO}/.grok/skills/frontend-design" \
  "Grok adapter does not expose frontend-design"
assert_missing "${AI_REPO}/.grok/skills/ui-ux-pro-max" \
  "Grok adapter does not expose ui-ux-pro-max"
assert_missing "${AI_REPO}/.grok/skills/superdesign" \
  "Grok adapter does not expose superdesign"
assert_grep '"hallmark"' "${AI_REPO}/skills-lock.json" \
  "skills-lock.json pins Hallmark"
assert_not_grep 'frontend-design' "${AI_REPO}/skills-lock.json" \
  "skills-lock.json does not pin frontend-design"
assert_not_grep 'ui-ux-pro-max' "${AI_REPO}/skills-lock.json" \
  "skills-lock.json does not pin ui-ux-pro-max"
assert_not_grep 'superdesign' "${AI_REPO}/skills-lock.json" \
  "skills-lock.json does not pin Superdesign"
assert_not_grep 'Automatically consult' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not auto-load multiple taste skills"
assert_not_grep 'frontend-design' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not reference frontend-design"
assert_not_grep 'ui-ux-pro-max' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not reference ui-ux-pro-max"
assert_not_grep 'Superdesign' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not reference Superdesign"
assert_grep 'Scope router' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui classifies UI scope"
assert_grep 'Do \*\*not\*\* load Hallmark' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "small UI does not automatically load Hallmark"
assert_grep 'Do \*\*not\*\* run Playwright' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "small UI does not automatically run Playwright"
assert_grep 'authoritative' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "project design system remains authoritative"
assert_grep 'It is \*\*not\*\* authorization for a Mode A suite' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "significant UI Mode B does not imply Mode A"
assert_grep 'bounded Mode B visual pass' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "significant UI authorizes bounded visual verification"
assert_grep 'creating or expanding a Playwright Mode A suite' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "Mode B UI authorization does not imply Mode A"
assert_grep 'availability is not general authorization' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "tool availability is not general authorization"
assert_grep 'best available real-browser capability' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "visual verification uses the best available real-browser capability"
assert_grep 'An IDE-integrated browser is valid' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "IDE-integrated browser is a valid visual-verification capability"
assert_not_grep 'Cursor' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "canonical browser-qa rule is not Cursor-specific"
assert_grep 'Do not weaken the role of Playwright' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "capability-aware verification does not weaken Playwright"
assert_grep 'must not\*\* be reported as' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "interactive browser pass is not reported as Playwright execution"
assert_grep 'Do not weaken the role of Playwright' \
  "${AI_REPO}/docs/contracts/features/browser-qa.md" \
  "browser-qa contract does not weaken Playwright"
assert_grep 'do not silently install large browser dependencies' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "missing Playwright browser binaries are not silently installed"
assert_grep 'do not silently downgrade the verification claim' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "missing Playwright binaries do not silently downgrade claims"
assert_grep 'Do not encode opening an external Chrome window as the fallback' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "Chrome is not the encoded fallback browser"
assert_grep 'static / code inspection' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "verification honesty distinguishes static inspection"
assert_grep 'interactive real-browser verification' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "verification honesty distinguishes interactive real-browser verification"
assert_grep 'automated Playwright / E2E execution' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "verification honesty distinguishes Playwright/E2E execution"
assert_grep 'best available real-browser capability' \
  "${AI_REPO}/docs/contracts/features/browser-qa.md" \
  "browser-qa contract owns capability-aware visual verification"
assert_grep 'not a platform requirement' \
  "${AI_REPO}/docs/contracts/features/browser-qa.md" \
  "contract treats an IDE browser as an example, not a requirement"
assert_grep 'This is not Playwright execution' \
  "${AI_REPO}/docs/contracts/adrs/0004-design-stack-and-ui-visual-verification.md" \
  "design-stack ADR uncouples Mode B visual verification from Playwright"
assert_grep 'best available real-browser capability' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core uses capability-aware visual verification"
assert_not_grep 'Superdesign' "${AI_REPO}/README.md" \
  "README does not document Superdesign as current tooling"
assert_not_grep '@superdesign/cli' "${AI_REPO}/README.md" \
  "README has no Superdesign CLI login/setup"
assert_not_grep 'Superdesign' "${AI_REPO}/mcp/README.md" \
  "MCP index does not present Superdesign as supported tooling"
assert_grep 'Design system, tokens, component conventions' \
  "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption inspects existing design conventions"
assert_grep 'Do not impose a new' \
  "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption does not impose a new design system"
assert_grep 'decorative numeric sequencing as a visual design device' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui prohibits decorative sequential numbering"
assert_grep 'Do not use em dashes' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui prohibits em dashes in generated end-user copy"
assert_grep 'generated end-user copy' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui scopes the em-dash rule to generated end-user copy"
assert_grep 'generous whitespace' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui positively supports generous whitespace"
assert_grep 'Do not treat generous whitespace as an AI-design tell' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not treat whitespace as an AI-design prohibition"
assert_not_grep 'excessive whitespace' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not list excessive whitespace as an anti-pattern"
assert_grep 'challenge rather than' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui includes anti-AI design heuristics"
assert_grep 'Hallmark is the only managed design skill' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "Hallmark remains the only managed design skill"
assert_grep 'outrank Hallmark' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui design constraints outrank Hallmark"
assert_grep 'Semantic section boundaries should also be perceptible visual' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires perceptible visual section boundaries"
assert_grep 'Adjacent semantic sections must remain visually distinguishable' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires adjacent sections to remain distinguishable"
assert_grep 'not a mechanical alternating-background rule' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not mandate alternating section backgrounds"
assert_grep 'Whitespace alone can provide sufficient separation' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui allows whitespace-only section separation"
assert_grep 'Identical backgrounds between adjacent sections are allowed' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui allows identical adjacent backgrounds when delineation is clear"
assert_grep 'CTA immediately preceding a footer' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires a pre-footer CTA to read as a distinct section"
assert_grep 'Do not add containers or cards merely to manufacture separation' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not manufacture section separation with cards"
assert_grep 'mechanically alternating white/gray/dark section backgrounds' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui challenges mechanically alternating section backgrounds"
assert_grep 'Cards are semantic containers' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui treats cards as semantic containers, not decoration"
assert_grep 'would the conceptual grouping become less clear' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui includes the card-earning test"
assert_grep 'coherent vocabulary of' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires a coherent card vocabulary"
assert_grep 'colored icon circles' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui rejects the colored-icon-circle feature-card tell"
assert_grep 'imagery must have a purpose' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires purposeful imagery"
assert_grep 'art-direct visual assets' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires art-directed visual assets"
assert_grep 'not merely be desktop content' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui forbids treating mobile as stacked desktop content"
assert_grep 'Feature/capability card' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui documents a feature/capability card pattern"
assert_grep 'Media/content card' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui documents a media/content card pattern"
assert_grep 'Action/resource card' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui documents an action/resource card pattern"
assert_grep 'not mandatory components' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui card patterns are conceptual, not required components"
assert_grep 'every section placed inside a card' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui still prohibits boxing every section as a card"
assert_grep 'repetitive icon \+ heading \+ paragraph feature grids' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui still challenges repetitive feature grids"
assert_grep 'excessive rounded cards/containers' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui still challenges excessive decorative cards"
assert_grep 'arbitrary badges/eyebrows above every heading' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui still challenges arbitrary badges"
assert_grep 'Cards are semantic containers' \
  "${AI_REPO}/docs/contracts/adrs/0004-design-stack-and-ui-visual-verification.md" \
  "design-stack ADR does not treat cards as prohibited"
assert_grep 'not a mechanical alternating-background rule' \
  "${AI_REPO}/docs/contracts/adrs/0004-design-stack-and-ui-visual-verification.md" \
  "design-stack ADR does not mandate alternating section backgrounds"
assert_not_grep 'over cards, dividers' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core does not rank hierarchy over cards as such"
assert_grep '### Exploration' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui keeps exploration routing"
assert_grep '### Significant' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui keeps significant-UI routing"
assert_grep 'bounded Mode B visual verification' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui keeps Mode B visual verification"
assert_grep 'decorative sequential numbering' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core prohibits decorative sequential numbering"
assert_grep 'em dashes in generated end-user' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core prohibits em dashes in generated end-user copy"
assert_grep 'generous whitespace' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core favors generous whitespace"
assert_grep 'Cards are semantic containers' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core treats cards as semantic containers"
assert_grep 'Adjacent semantic sections must remain visually distinguishable' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core requires distinguishable semantic sections"
assert_grep 'not a mandate to alternate' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core does not mandate alternating section backgrounds"
assert_grep 'AI/template conventions' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core avoids generic AI/template design patterns"
assert_grep 'outrank Hallmark' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core states UI constraints outrank Hallmark"
assert_not_grep 'excessive whitespace' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core does not list excessive whitespace as an anti-pattern"
assert_grep 'inherit harness UI design preferences' \
  "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption inherits harness UI design preferences"
assert_grep 'Semantic cards that earn' \
  "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption does not treat semantic cards as default-AI patterns"
assert_grep 'Do not silently rewrite' \
  "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption does not silently rewrite existing visual language"
assert_grep 'inherit harness UI design preferences' \
  "${AI_REPO}/.cursor/rules/50-workflows.mdc" \
  "workflows inherit harness UI design preferences on adoption"

echo ""
echo "--- Capability-on-demand and motion ---"
assert_grep 'capability-on-demand, not capability-by-default' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "capability-on-demand is canonical platform guidance"
assert_grep 'capability-on-demand, not capability-by-default' \
  "${AI_REPO}/core/agent-core.md" \
  "capability-on-demand is in the portable core"
assert_grep 'not justification for using a tool' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "tool availability does not itself justify usage"
assert_grep 'not justification for using a tool' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core states availability is not justification"
assert_grep 'not justification for using a tool' \
  "${AI_REPO}/mcp/README.md" \
  "MCP guidance states availability is not justification"
assert_grep 'availability is not general authorization' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "tool availability is not authorization"
assert_grep 'purpose and value' "${AI_REPO}/mcp/README.md" \
  "MCP discipline is governed by purpose and value, not count"
assert_grep 'not required bootstrap dependencies' \
  "${AI_REPO}/mcp/README.md" \
  "additional MCPs are not required bootstrap dependencies"
assert_grep 'Capability parity is not the goal' \
  "${AI_REPO}/mcp/README.md" \
  "MCP guidance does not force cross-agent capability parity"
assert_grep 'does not install MCP servers' \
  "${AI_REPO}/.cursor/rules/50-workflows.mdc" \
  "bootstrap policy does not install MCP servers"
assert_not_grep 'mcpServers' "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap script does not write MCP server config"
assert_not_grep 'mcp.json' "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap script does not write mcp.json"
assert_not_grep 'Context7' "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap does not add Context7"
assert_not_grep 'chrome-devtools' "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap does not add Chrome DevTools MCP"
assert_not_grep 'gsap' "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap does not add GSAP"
assert_not_grep 'framer-motion' "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap does not add Framer Motion"
assert_missing "${AI_REPO}/.agents/skills/motion" \
  "no motion skill is introduced"
assert_not_grep 'motion' "${AI_REPO}/skills-lock.json" \
  "skills-lock does not pin a motion skill"
assert_grep 'Do not add a motion skill' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui forbids adding a motion skill"
assert_grep 'Hallmark is the only managed design skill' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "Hallmark remains the only managed design skill"
assert_grep '## Significant motion' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "significant motion receives proportionate review"
assert_grep 'do \*\*not\*\* trigger an expanded motion review' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "trivial transitions do not trigger expanded motion QA"
assert_grep 'prefers-reduced-motion' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "reduced-motion consideration exists"
assert_grep 'does \*\*not\*\* automatically authorize new Mode A' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "motion does not automatically authorize Mode A"
assert_grep 'Do not require formal performance profiling' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "motion does not automatically authorize performance profiling"
assert_grep 'formal performance profiling' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "Mode B motion observation does not authorize profiling"
assert_grep 'observe the relevant animation' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "bounded Mode B may observe significant motion"
assert_grep 'everything fading upward on scroll' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "anti-AI motion patterns remain in design heuristics"
assert_grep 'Do not add an MCP simply because' \
  "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption does not add MCPs merely because docs mention them"
assert_grep 'Project requirements drive tool selection' \
  "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption lets project requirements drive tool selection"
assert_grep 'Capability parity is not the goal' \
  "${AI_REPO}/core/adapters/README.md" \
  "adapter index does not force MCP parity"
assert_grep 'Cursor \(reference\)' "${AI_REPO}/core/adapters/README.md" \
  "Cursor remains a supported agent"
assert_grep 'Grok Build' "${AI_REPO}/core/adapters/README.md" \
  "Grok Build remains a supported agent"
assert_grep 'OpenAI Codex' "${AI_REPO}/core/adapters/README.md" \
  "Codex remains a supported agent"
assert_grep 'Claude Code' "${AI_REPO}/core/adapters/README.md" \
  "Claude Code remains a supported agent"
assert_grep 'Nous Research Hermes Agent' "${AI_REPO}/core/adapters/README.md" \
  "Hermes remains a supported agent"

echo ""
echo "--- Doctor (AI Platform repo) ---"
if "${AI_REPO}/scripts/doctor.sh" "${AI_REPO}" >"${LOGDIR}/doctor-platform.log" 2>&1; then
  pass "doctor on AI Platform exits 0"
else
  fail "doctor on AI Platform exits 0"
  cat "${LOGDIR}/doctor-platform.log"
fi
assert_grep "Playwright and Laravel Boost are not required" "${LOGDIR}/doctor-platform.log" \
  "doctor does not require Playwright/Boost of the platform repo"
assert_grep "GitHub CLI is not required" "${LOGDIR}/doctor-platform.log" \
  "doctor does not require GitHub CLI of the platform repo"

echo ""
echo "--- Generic new project ---"
GENERIC="${WORKDIR}/generic"
mkdir -p "${GENERIC}"
printf 'hello\n' > "${GENERIC}/README.md"

"${AI_REPO}/scripts/bootstrap-project.sh" "${GENERIC}" >${LOGDIR}/boot-generic.log 2>&1

assert_file "${GENERIC}/docs/README.md" "generic received docs templates"
assert_file "${GENERIC}/docs/working-mode.md" \
  "generic received working-mode template"
assert_file "${GENERIC}/AGENTS.md" "generic received AGENTS.md"
assert_file "${GENERIC}/CLAUDE.md" "generic received CLAUDE.md"
if [[ -L "${GENERIC}/AGENTS.md" ]] && [[ "$(readlink "${GENERIC}/AGENTS.md")" == "${AI_REPO}/core/agent-core.md" ]]; then
  pass "generic AGENTS.md links to canonical agent-core"
else
  fail "generic AGENTS.md links to canonical agent-core"
fi
assert_grep '@AGENTS.md' "${GENERIC}/CLAUDE.md" \
  "generic CLAUDE.md imports AGENTS.md"
assert_missing "${GENERIC}/.hermes.md" "generic did not receive .hermes.md"
assert_missing "${GENERIC}/HERMES.md" "generic did not receive HERMES.md"
assert_missing "${GENERIC}/.ai/guidelines/ai-platform.md" \
  "generic did not receive Laravel Boost guideline"
assert_grep "Hermes consumes AGENTS.md" ${LOGDIR}/boot-generic.log \
  "bootstrap documents Hermes AGENTS.md usage"
assert_missing "${GENERIC}/docs/contracts/features/browser-qa.md" \
  "generic did not receive browser-QA template"
assert_missing "${GENERIC}/docs/contracts/foundational/platform-reconciliation.md" \
  "generic new project did not receive reconciliation draft"
assert_missing "${GENERIC}/resources/images" \
  "generic did not receive Roots resources/images"
assert_not_grep 'playwright-report' "${GENERIC}/.gitignore" \
  "generic gitignore has no Playwright artifacts"
assert_grep "Playwright Mode A is not required" ${LOGDIR}/boot-generic.log \
  "bootstrap does not require Playwright for generic projects"
assert_grep "Laravel Boost is not required" ${LOGDIR}/boot-generic.log \
  "bootstrap does not require Boost for generic projects"
assert_grep "Detected profile: none" ${LOGDIR}/boot-generic.log \
  "bootstrap does not assign laravel-webapp or roots-radicle to generic projects"
assert_grep "GitHub CLI \\(gh\\) is optional" ${LOGDIR}/boot-generic.log \
  "bootstrap states GitHub CLI is optional"
assert_grep "does not copy or overwrite .github/" ${LOGDIR}/boot-generic.log \
  "bootstrap does not copy GitHub templates"
assert_missing "${GENERIC}/.github/PULL_REQUEST_TEMPLATE.md" \
  "generic did not receive a GitHub PR template"
assert_missing "${GENERIC}/.github" \
  "generic did not receive a .github directory"
assert_grep '^\.hallmark/' "${GENERIC}/.gitignore" \
  "generic gitignore ignores Hallmark operational artifacts"
assert_not_grep '^design\.md' "${GENERIC}/.gitignore" \
  "generic gitignore does not ignore design.md"

mkdir -p \
  "${GENERIC}/.agents/skills/frontend-design" \
  "${GENERIC}/.agents/skills/ui-ux-pro-max" \
  "${GENERIC}/.agents/skills/superdesign" \
  "${GENERIC}/.claude/skills" \
  "${GENERIC}/.grok/skills"
printf 'retired\n' > "${GENERIC}/.agents/skills/frontend-design/SKILL.md"
printf 'retired\n' > "${GENERIC}/.agents/skills/ui-ux-pro-max/SKILL.md"
printf 'retired\n' > "${GENERIC}/.agents/skills/superdesign/SKILL.md"
ln -sfn "../../.agents/skills/frontend-design" "${GENERIC}/.claude/skills/frontend-design"
ln -sfn "../../.agents/skills/superdesign" "${GENERIC}/.grok/skills/superdesign"

"${AI_REPO}/scripts/bootstrap-project.sh" "${GENERIC}" >${LOGDIR}/boot-generic-prune.log 2>&1

assert_missing "${GENERIC}/.agents/skills/frontend-design" \
  "bootstrap prunes frontend-design even when skill restore is skipped"
assert_missing "${GENERIC}/.agents/skills/ui-ux-pro-max" \
  "bootstrap prunes ui-ux-pro-max even when skill restore is skipped"
assert_missing "${GENERIC}/.agents/skills/superdesign" \
  "bootstrap prunes superdesign even when skill restore is skipped"
assert_missing "${GENERIC}/.claude/skills/frontend-design" \
  "bootstrap prunes retired Claude skill links"
assert_missing "${GENERIC}/.grok/skills/superdesign" \
  "bootstrap prunes retired Grok skill links"
assert_grep 'Removed retired skill' ${LOGDIR}/boot-generic-prune.log \
  "bootstrap reports retired skill pruning"

if [[ -L "${GENERIC}/.cursor/rules/70-work-items.mdc" ]] && [[ "$(readlink "${GENERIC}/.cursor/rules/70-work-items.mdc")" == "${AI_REPO}/.cursor/rules/70-work-items.mdc" ]]; then
  pass "generic received 70-work-items rule link"
else
  fail "generic received 70-work-items rule link"
fi

if "${AI_REPO}/scripts/doctor.sh" "${GENERIC}" >${LOGDIR}/doctor-generic.log 2>&1; then
  pass "doctor on generic project exits 0"
else
  fail "doctor on generic project exits 0"
  cat ${LOGDIR}/doctor-generic.log
fi
assert_grep "Playwright Mode A not required" ${LOGDIR}/doctor-generic.log \
  "doctor does not force Playwright on generic projects"
assert_grep "Boost not applicable" ${LOGDIR}/doctor-generic.log \
  "doctor does not require Boost on generic projects"

echo ""
echo "--- New Roots/Radicle project ---"
RADICLE_NEW="${WORKDIR}/radicle-new"
mkdir -p "${RADICLE_NEW}"
write_radicle_composer "${RADICLE_NEW}"

"${AI_REPO}/scripts/bootstrap-project.sh" "${RADICLE_NEW}" >${LOGDIR}/boot-radicle-new.log 2>&1

assert_file "${RADICLE_NEW}/docs/README.md" "Radicle project received docs templates"
assert_missing "${RADICLE_NEW}/docs/contracts/features/browser-qa.md" \
  "Radicle project did not receive browser-QA template"
assert_dir "${RADICLE_NEW}/resources/images" \
  "new Radicle project received resources/images"
assert_file "${RADICLE_NEW}/resources/images/.gitkeep" \
  "new Radicle resources/images has .gitkeep"
assert_not_grep 'playwright-report' "${RADICLE_NEW}/.gitignore" \
  "Radicle gitignore has no Playwright artifacts"
assert_grep "Detected profile: roots-radicle" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap detects roots-radicle profile"
assert_not_grep "Detected profile: laravel-webapp" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap does not treat Radicle as laravel-webapp"
assert_grep "Playwright Mode A is not required" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap does not require Playwright for Radicle"
assert_grep "Laravel Boost is not required" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap does not require Boost for Radicle"
assert_grep "Preferred greenfield stack: ACF Pro, Keen Slider, WPForms Lite" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap reports Roots greenfield stack"
assert_grep "Install keen-slider via npm" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap prints Keen npm next step"
assert_grep "WPForms Lite" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap prints WPForms Lite next step"
assert_grep "does not install npm packages or WordPress plugins" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap does not install Roots npm/plugins"
assert_not_grep "Gravity Forms is the preferred" ${LOGDIR}/boot-radicle-new.log \
  "bootstrap does not prefer Gravity Forms as default"

if "${AI_REPO}/scripts/doctor.sh" "${RADICLE_NEW}" >${LOGDIR}/doctor-radicle-new.log 2>&1; then
  pass "doctor on Radicle project exits 0"
else
  fail "doctor on Radicle project exits 0"
  cat ${LOGDIR}/doctor-radicle-new.log
fi
assert_grep "Playwright Mode A not required" ${LOGDIR}/doctor-radicle-new.log \
  "doctor does not force Playwright on Radicle projects"
assert_grep "Boost not applicable" ${LOGDIR}/doctor-radicle-new.log \
  "doctor does not require Boost on Radicle projects"

echo ""
echo "--- Existing Roots/Radicle project ---"
RADICLE_EXISTING="${WORKDIR}/radicle-existing"
mkdir -p "${RADICLE_EXISTING}/docs"
write_radicle_composer "${RADICLE_EXISTING}"
cat > "${RADICLE_EXISTING}/docs/README.md" <<'EOF'
# Docs
EOF

"${AI_REPO}/scripts/bootstrap-project.sh" "${RADICLE_EXISTING}" >${LOGDIR}/boot-radicle-existing.log 2>&1
assert_missing "${RADICLE_EXISTING}/resources/images" \
  "existing Radicle bootstrap does not create resources/images"
assert_file "${RADICLE_EXISTING}/docs/contracts/foundational/platform-reconciliation.md" \
  "existing Radicle project received reconciliation draft"
assert_grep "Detected profile: roots-radicle" ${LOGDIR}/boot-radicle-existing.log \
  "existing Radicle bootstrap detects roots-radicle"
assert_grep "Do not install or migrate during bootstrap" ${LOGDIR}/boot-radicle-existing.log \
  "existing Radicle bootstrap does not install or migrate stack"
assert_grep "core/prompts/project-adoption.md" ${LOGDIR}/boot-radicle-existing.log \
  "existing Radicle bootstrap points at project adoption prompt"
assert_not_grep "Install keen-slider via npm" ${LOGDIR}/boot-radicle-existing.log \
  "existing Radicle bootstrap does not auto-install Keen"

echo ""
echo "--- Bedrock WordPress without Sage/Acorn ---"
BEDROCK="${WORKDIR}/bedrock-only"
mkdir -p "${BEDROCK}"
cat > "${BEDROCK}/composer.json" <<'EOF'
{
  "require": {
    "php": "^8.2",
    "roots/wordpress": "^6.8"
  }
}
EOF

"${AI_REPO}/scripts/bootstrap-project.sh" "${BEDROCK}" >${LOGDIR}/boot-bedrock.log 2>&1
assert_grep "Detected profile: none" ${LOGDIR}/boot-bedrock.log \
  "Bedrock without Sage/Acorn is not roots-radicle"
assert_not_grep "Detected profile: roots-radicle" ${LOGDIR}/boot-bedrock.log \
  "Navi/Radicle profile is not imposed on plain Roots WordPress"
assert_missing "${BEDROCK}/resources/images" \
  "plain Bedrock did not receive Roots resources/images"

echo ""
echo "--- New Laravel project without Boost ---"
LARAVEL_NEW="${WORKDIR}/laravel-new"
mkdir -p "${LARAVEL_NEW}"
write_laravel_composer "${LARAVEL_NEW}" 0

"${AI_REPO}/scripts/bootstrap-project.sh" "${LARAVEL_NEW}" >${LOGDIR}/boot-laravel-new.log 2>&1

assert_file "${LARAVEL_NEW}/docs/contracts/features/browser-qa.md" \
  "new Laravel project received browser-QA draft"
assert_missing "${LARAVEL_NEW}/resources/images" \
  "Laravel project did not receive Roots resources/images"
assert_grep 'playwright-report' "${LARAVEL_NEW}/.gitignore" \
  "new Laravel gitignore includes Playwright artifacts"
assert_grep "Detected profile: laravel-webapp" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap detects laravel-webapp profile"
assert_not_grep "Detected profile: roots-radicle" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap does not treat Laravel as roots-radicle"
assert_grep "missing_package" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap diagnoses missing Boost package"
assert_grep "composer require laravel/boost --dev" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap prints native Boost install steps"
assert_grep "Do not add Boost to user-global" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap warns against user-global Boost MCP"
if [[ -L "${LARAVEL_NEW}/.ai/guidelines/ai-platform.md" ]] && [[ "$(readlink "${LARAVEL_NEW}/.ai/guidelines/ai-platform.md")" == "${AI_REPO}/core/agent-core.md" ]]; then
  pass "new Laravel project received Boost guideline symlink"
else
  fail "new Laravel project received Boost guideline symlink"
fi
assert_missing "${LARAVEL_NEW}/.hermes.md" "new Laravel project did not receive .hermes.md"

if "${AI_REPO}/scripts/doctor.sh" "${LARAVEL_NEW}" >${LOGDIR}/doctor-laravel-new.log 2>&1; then
  fail "doctor fails Laravel project with missing Boost"
else
  pass "doctor fails Laravel project with missing Boost"
fi
assert_grep "laravel/boost missing from composer.json" ${LOGDIR}/doctor-laravel-new.log \
  "doctor names missing Boost package"
assert_grep "Playwright Mode A expected" ${LOGDIR}/doctor-laravel-new.log \
  "doctor expects Playwright for Laravel web apps"
assert_grep "Playwright Mode A not present yet" ${LOGDIR}/doctor-laravel-new.log \
  "missing Playwright is a warning, not a silent skip"

echo ""
echo "--- Laravel with Boost declared, installed, and MCP-configured ---"
LARAVEL_OK="${WORKDIR}/laravel-ok"
mkdir -p "${LARAVEL_OK}/vendor/laravel/boost" "${LARAVEL_OK}/.cursor"
write_laravel_composer "${LARAVEL_OK}" 1
touch "${LARAVEL_OK}/artisan"
cat > "${LARAVEL_OK}/.cursor/mcp.json" <<'EOF'
{
  "mcpServers": {
    "laravel-boost": {
      "command": "php",
      "args": ["artisan", "boost:mcp"]
    }
  }
}
EOF

"${AI_REPO}/scripts/bootstrap-project.sh" "${LARAVEL_OK}" >${LOGDIR}/boot-laravel-ok.log 2>&1
assert_grep "Laravel Boost: ok" ${LOGDIR}/boot-laravel-ok.log \
  "bootstrap reports Boost ok when native setup is present"
assert_file "${LARAVEL_OK}/.cursor/mcp.json" "bootstrap did not remove Boost MCP config"
assert_grep "laravel-boost" "${LARAVEL_OK}/.cursor/mcp.json" \
  "bootstrap did not rewrite Boost MCP config"

if "${AI_REPO}/scripts/doctor.sh" "${LARAVEL_OK}" >${LOGDIR}/doctor-laravel-ok.log 2>&1; then
  pass "doctor passes Laravel project with working Boost setup"
else
  fail "doctor passes Laravel project with working Boost setup"
  cat ${LOGDIR}/doctor-laravel-ok.log
fi
assert_grep "Boost MCP configured" ${LOGDIR}/doctor-laravel-ok.log \
  "doctor reports Boost MCP configured"

echo ""
echo "--- Existing Laravel project (docs already present) ---"
LARAVEL_EXISTING="${WORKDIR}/laravel-existing"
mkdir -p "${LARAVEL_EXISTING}/docs/contracts/foundational"
write_laravel_composer "${LARAVEL_EXISTING}" 0
cat > "${LARAVEL_EXISTING}/docs/README.md" <<'EOF'
# Existing docs
UNIQUE_EXISTING_MARKER
EOF
printf 'do not overwrite\n' > "${LARAVEL_EXISTING}/docs/00-project-context.md"
printf 'UNIQUE_AGENTS_MARKER\n' > "${LARAVEL_EXISTING}/AGENTS.md"

"${AI_REPO}/scripts/bootstrap-project.sh" "${LARAVEL_EXISTING}" >${LOGDIR}/boot-existing.log 2>&1

assert_grep "UNIQUE_EXISTING_MARKER" "${LARAVEL_EXISTING}/docs/README.md" \
  "existing docs/README.md was not overwritten"
assert_grep "do not overwrite" "${LARAVEL_EXISTING}/docs/00-project-context.md" \
  "existing project context was not overwritten"
assert_grep "UNIQUE_AGENTS_MARKER" "${LARAVEL_EXISTING}/AGENTS.md" \
  "existing AGENTS.md was not overwritten"
if [[ -L "${LARAVEL_EXISTING}/.ai/guidelines/ai-platform.md" ]] && [[ "$(readlink "${LARAVEL_EXISTING}/.ai/guidelines/ai-platform.md")" == "${AI_REPO}/core/agent-core.md" ]]; then
  pass "existing Laravel project received Boost guideline without replacing AGENTS.md"
else
  fail "existing Laravel project received Boost guideline without replacing AGENTS.md"
fi
assert_missing "${LARAVEL_EXISTING}/.hermes.md" "existing Laravel project did not receive .hermes.md"
assert_file "${LARAVEL_EXISTING}/CLAUDE.md" \
  "existing Laravel project received CLAUDE.md"
assert_file "${LARAVEL_EXISTING}/docs/contracts/features/browser-qa.md" \
  "existing Laravel project received missing browser-QA draft"
assert_file "${LARAVEL_EXISTING}/docs/contracts/foundational/platform-reconciliation.md" \
  "existing Laravel project received reconciliation draft"
assert_file "${LARAVEL_EXISTING}/docs/working-mode.md" \
  "existing Laravel project received missing working-mode draft"
assert_file "${LARAVEL_EXISTING}/docs/99-project-status.md" \
  "existing Laravel project received missing status draft"
assert_grep "Existing project" ${LOGDIR}/boot-existing.log \
  "bootstrap detected existing-project mode"
assert_grep "core/prompts/project-adoption.md" ${LOGDIR}/boot-existing.log \
  "bootstrap points at project adoption prompt"
assert_grep "did not adopt the project" ${LOGDIR}/boot-existing.log \
  "bootstrap states it did not adopt the project"

echo ""
echo "--- Existing project GitHub conventions ---"
EXISTING_GH="${WORKDIR}/existing-github"
mkdir -p "${EXISTING_GH}/docs" "${EXISTING_GH}/.github/ISSUE_TEMPLATE"
write_laravel_composer "${EXISTING_GH}" 0
cat > "${EXISTING_GH}/docs/README.md" <<'EOF'
# Existing docs
EOF
printf 'UNIQUE_PR_TEMPLATE_MARKER\n' > "${EXISTING_GH}/.github/PULL_REQUEST_TEMPLATE.md"
printf 'UNIQUE_ISSUE_TEMPLATE_MARKER\n' > "${EXISTING_GH}/.github/ISSUE_TEMPLATE/bug.md"
printf 'UNIQUE_WORKING_MODE_MARKER\n' > "${EXISTING_GH}/docs/working-mode.md"

"${AI_REPO}/scripts/bootstrap-project.sh" "${EXISTING_GH}" >${LOGDIR}/boot-existing-github.log 2>&1

assert_grep "UNIQUE_PR_TEMPLATE_MARKER" "${EXISTING_GH}/.github/PULL_REQUEST_TEMPLATE.md" \
  "existing PR template was not overwritten"
assert_grep "UNIQUE_ISSUE_TEMPLATE_MARKER" "${EXISTING_GH}/.github/ISSUE_TEMPLATE/bug.md" \
  "existing Issue template was not overwritten"
assert_grep "UNIQUE_WORKING_MODE_MARKER" "${EXISTING_GH}/docs/working-mode.md" \
  "existing working-mode was not overwritten"
assert_grep "does not copy or overwrite .github/" ${LOGDIR}/boot-existing-github.log \
  "existing-project bootstrap states it does not overwrite GitHub templates"
assert_not_grep 'gh auth' ${LOGDIR}/boot-existing-github.log \
  "bootstrap does not authenticate GitHub CLI"

echo ""
echo "--- Idempotent re-run (generic) ---"
"${AI_REPO}/scripts/bootstrap-project.sh" "${GENERIC}" >${LOGDIR}/boot-generic-2.log 2>&1
build_count="$(grep -cE '^\.build/?$' "${GENERIC}/.gitignore" || true)"
if [[ "${build_count}" -eq 1 ]]; then
  pass "re-run does not duplicate .build/ gitignore"
else
  fail "re-run does not duplicate .build/ gitignore (count=${build_count})"
fi

echo ""
echo "--- ChatGPT context export ---"
if "${AI_REPO}/scripts/export-chatgpt-context.sh" >"${LOGDIR}/export-chatgpt.log" 2>&1; then
  pass "export-chatgpt-context.sh exits 0"
else
  fail "export-chatgpt-context.sh exits 0"
  cat "${LOGDIR}/export-chatgpt.log"
fi
assert_file "${AI_REPO}/.build/chatgpt-context.zip" \
  "ChatGPT export zip exists"
assert_dir "${AI_REPO}/.build/chatgpt-context" \
  "ChatGPT export directory exists"
assert_file "${AI_REPO}/.build/chatgpt-context/docs/00-project-context.md" \
  "export includes project context"
assert_file "${AI_REPO}/.build/chatgpt-context/docs/working-mode.md" \
  "export includes working-mode"
assert_file "${AI_REPO}/.build/chatgpt-context/.cursor/rules/40-ui.mdc" \
  "export includes 40-ui"
assert_file "${AI_REPO}/.build/chatgpt-context/.cursor/rules/60-browser-qa.mdc" \
  "export includes 60-browser-qa"
assert_dir "${AI_REPO}/.build/chatgpt-context/.agents/skills/hallmark" \
  "export includes Hallmark"
assert_grep '^Version 1\.2\.0$' \
  "${AI_REPO}/.build/chatgpt-context/docs/00-project-context.md" \
  "export project context is v1.2.0"
assert_file "${AI_REPO}/.build/chatgpt-context/CHANGELOG.md" \
  "export includes changelog"
assert_file "${AI_REPO}/.build/chatgpt-context/README.md" \
  "export includes README"
assert_grep '^Version 1\.2\.0$' \
  "${AI_REPO}/.build/chatgpt-context/README.md" \
  "export README is v1.2.0"
assert_missing "${AI_REPO}/.build/chatgpt-context/.agents/skills/frontend-design" \
  "export does not bundle frontend-design"
assert_missing "${AI_REPO}/.build/chatgpt-context/.agents/skills/ui-ux-pro-max" \
  "export does not bundle ui-ux-pro-max"
assert_missing "${AI_REPO}/.build/chatgpt-context/.agents/skills/superdesign" \
  "export does not bundle Superdesign"
assert_not_grep '@superdesign/cli' "${AI_REPO}/.build/chatgpt-context/README.md" \
  "export README has no Superdesign CLI setup"

echo ""
echo "--- Summary ---"
echo "Passed: ${PASSES}"
echo "Failed: ${FAILURES}"
echo "Workdir: ${WORKDIR}"

if [[ "${FAILURES}" -gt 0 ]]; then
  exit 1
fi

exit 0
