#!/usr/bin/env bash

# Fixture tests for AI Platform bootstrap and doctor.
# Does not modify application projects. Does not install Composer packages.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

export AI_BOOTSTRAP_SKIP_SKILLS=1
export AI_BOOTSTRAP_NONINTERACTIVE=1

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
  if grep -qE -- "${pattern}" "${file}"; then
    pass "${label}"
  else
    fail "${label}"
  fi
}

assert_not_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -qE -- "${pattern}" "${file}"; then
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

write_wordpress_root() {
  local dir="$1"
  mkdir -p "${dir}/wp-content/uploads"
  printf "<?php\n// sample\n" > "${dir}/wp-config-sample.php"
}

write_bedrock_composer() {
  local dir="$1"
  mkdir -p "${dir}/web/app"
  printf "<?php\n" > "${dir}/web/wp-config.php"
  cat > "${dir}/composer.json" <<'EOF'
{
  "require": {
    "php": "^8.2",
    "roots/wordpress": "^6.8"
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
  "${AI_REPO}/scripts/install-deployer.sh" \
  "${AI_REPO}/scripts/doctor.sh" \
  "${AI_REPO}/scripts/check-guardrails.sh" \
  "${AI_REPO}/scripts/link-rules.sh" \
  "${AI_REPO}/scripts/export-chatgpt-context.sh" \
  "${AI_REPO}/scripts/update-skills.sh" \
  "${AI_REPO}/scripts/lib/project-capabilities.sh" \
  "${AI_REPO}/scripts/lib/deployer.sh" \
  "${AI_REPO}/scripts/test-platform.sh"
do
  if bash -n "${script}"; then
    pass "bash -n $(basename "${script}")"
  else
    fail "bash -n $(basename "${script}")"
  fi
done
if python3 -m py_compile "${AI_REPO}/scripts/lib/check_guardrails.py"; then
  pass "python3 -m py_compile check_guardrails.py"
else
  fail "python3 -m py_compile check_guardrails.py"
fi

echo ""
echo "--- Onboarding docs ---"
assert_file "${AI_REPO}/core/prompts/project-adoption.md" \
  "project adoption prompt exists"
assert_file "${AI_REPO}/README.md" "README exists"
assert_grep '^# AI Development Harness' "${AI_REPO}/README.md" \
  "README uses the public product title"
assert_grep '^Version 1\.3\.0$' "${AI_REPO}/README.md" \
  "README reports harness version 1.3.0"
assert_file "${AI_REPO}/CHANGELOG.md" "CHANGELOG exists"
assert_grep '^## 1\.3\.0' "${AI_REPO}/CHANGELOG.md" \
  "CHANGELOG has a 1.3.0 entry"
assert_grep '^## 1\.2\.0' "${AI_REPO}/CHANGELOG.md" \
  "CHANGELOG preserves the 1.2.0 entry"
assert_grep 'Version 1\.3\.0' "${AI_REPO}/docs/99-project-status.md" \
  "status document reports version 1.3.0"
assert_grep '^Version 1\.3\.0$' "${AI_REPO}/docs/00-project-context.md" \
  "project context reports version 1.3.0"
assert_file "${AI_REPO}/LICENSE" "LICENSE exists"
assert_grep 'MIT License' "${AI_REPO}/LICENSE" \
  "LICENSE is MIT"
assert_grep 'Joe Conlin' "${AI_REPO}/LICENSE" \
  "LICENSE names the copyright holder"
assert_grep '2026' "${AI_REPO}/LICENSE" \
  "LICENSE uses the current year"
assert_file "${AI_REPO}/docs/getting-started.md" "getting-started guide exists"
assert_file "${AI_REPO}/docs/how-it-works.md" "how-it-works guide exists"
assert_file "${AI_REPO}/docs/adopting-projects.md" "adopting-projects guide exists"
assert_file "${AI_REPO}/docs/maintaining.md" "maintaining guide exists"
assert_file "${AI_REPO}/docs/llm-support-prompt.md" "LLM support prompt exists"
assert_grep 'docs/getting-started.md' "${AI_REPO}/README.md" \
  "README links to getting-started"
assert_grep 'docs/llm-support-prompt.md' "${AI_REPO}/README.md" \
  "README links to the LLM support prompt"
assert_not_grep 'bootstrap-ai' "${AI_REPO}/README.md" \
  "README does not mention bootstrap-ai"
assert_not_grep '/Users/joeconlin' "${AI_REPO}/README.md" \
  "README does not require a personal absolute path"
assert_not_grep '/Users/joeconlin' "${AI_REPO}/docs/getting-started.md" \
  "getting-started does not require a personal absolute path"
assert_not_grep '/Sites/AI' "${AI_REPO}/README.md" \
  "README does not use an author-specific clone path"
assert_not_grep '/Sites/AI' "${AI_REPO}/docs/getting-started.md" \
  "getting-started does not use an author-specific clone path"
assert_grep 'AI_PLATFORM=' "${AI_REPO}/README.md" \
  "README defines an AI_PLATFORM path convention"
assert_grep 'AI_PLATFORM=' "${AI_REPO}/docs/getting-started.md" \
  "getting-started defines an AI_PLATFORM path convention"
assert_grep 'npx skills experimental_install' "${AI_REPO}/docs/getting-started.md" \
  "getting-started documents skill restore from skills-lock.json"
assert_grep 'First-time skill restore requires' "${AI_REPO}/docs/getting-started.md" \
  "getting-started states first-time skill restore requires network access"
assert_grep 'GitHub/upstream' "${AI_REPO}/docs/getting-started.md" \
  "getting-started states skill restore retrieves the skill from GitHub/upstream"
assert_grep 'Start with the root README.md' "${AI_REPO}/docs/llm-support-prompt.md" \
  "LLM support seed starts at the root README for public orientation"
assert_grep 'not the public landing page' "${AI_REPO}/docs/llm-support-prompt.md" \
  "LLM support seed treats docs/README.md as the contract registry"
assert_grep 'Apply Current-First' "${AI_REPO}/docs/llm-support-prompt.md" \
  "LLM support seed names Current-First"
assert_grep 'newer than' "${AI_REPO}/docs/llm-support-prompt.md" \
  "LLM support seed treats the inspected working tree as newer than GitHub main"
assert_grep 'only if that stack is present' "${AI_REPO}/docs/llm-support-prompt.md" \
  "LLM support seed does not assume Laravel or Roots"
assert_grep 'Known limitation' "${AI_REPO}/docs/maintaining.md" \
  "maintaining documents re-bootstrap classification as a known limitation"
assert_grep 'npx skills update' "${AI_REPO}/scripts/update-skills.sh" \
  "update-skills.sh is the skill-update command"
assert_grep 'npx -y @playwright/mcp@latest' "${AI_REPO}/mcp/playwright/README.md" \
  "Playwright MCP docs include the user-global npx invocation"
assert_grep 'user-global MCP servers during clone' "${AI_REPO}/mcp/README.md" \
  "MCP index states the platform does not install user-global MCP servers"
assert_grep 'install MCP servers' "${AI_REPO}/docs/getting-started.md" \
  "getting-started states bootstrap does not install MCP servers"
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
assert_grep 'ls -l /path/to/your-project/.cursor/rules' "${AI_REPO}/README.md" \
  "README uses linked rules as the harness install check"
assert_grep 'profile gap, not a failed' "${AI_REPO}/docs/getting-started.md" \
  "getting-started distinguishes Laravel doctor FAIL from a failed harness link"
assert_grep 'until Laravel Boost is declared' "${AI_REPO}/docs/getting-started.md" \
  "getting-started says Laravel project doctor fails until Boost is present"
assert_grep 'does \*\*not\*\* implement the deferred project-local' \
  "${AI_REPO}/CHANGELOG.md" \
  "v1.3.0 changelog states the deferred portability architecture was not implemented"
assert_grep 'Installing or configuring deployment tooling does not authorize' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform states installing Deployer does not authorize deployment"
assert_grep 'Installing or configuring deployment tooling does not authorize' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core states installing Deployer does not authorize deployment"
assert_grep 'restorable production backup' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform keeps the production backup requirement"
assert_grep 'restorable production backup' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core keeps the production backup requirement"
assert_grep 'catastrophic operations' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform keeps the catastrophic-operation guardrail"
assert_grep 'catastrophic operations' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core keeps the catastrophic-operation guardrail"
assert_file "${AI_REPO}/scripts/install-deployer.sh" \
  "standalone Deployer installer exists"
assert_file "${AI_REPO}/docs/contracts/features/deployer.md" \
  "canonical Deployer contract exists"
assert_file "${AI_REPO}/docs/contracts/adrs/0007-optional-deployer-capability.md" \
  "Deployer ADR exists"
assert_missing "${AI_REPO}/templates/docs/contracts/features/deployment.md" \
  "docs templates do not auto-copy Deployer notes into every new project"
assert_not_grep 'vendor/bin/dep deploy' "${AI_REPO}/scripts/lib/deployer.sh" \
  "deployer helpers do not invoke dep deploy"
assert_not_grep 'vendor/bin/dep deploy' "${AI_REPO}/scripts/install-deployer.sh" \
  "standalone installer does not invoke dep deploy"
assert_not_grep 'vendor/bin/dep deploy' "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap does not invoke dep deploy"

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
assert_grep 'current working mode for a fresh agent' \
  "${AI_REPO}/docs/adopting-projects.md" \
  "adopting-projects says what working-mode is for"
assert_grep 'when that mode changes, not after every task' \
  "${AI_REPO}/docs/adopting-projects.md" \
  "adopting-projects says when to update working-mode"
assert_grep 'load working mode automatically' \
  "${AI_REPO}/docs/adopting-projects.md" \
  "adopting-projects says a bounded task is enough; always-on loads working mode"
assert_grep 're-run bootstrap to add the' \
  "${AI_REPO}/docs/adopting-projects.md" \
  "adopting-projects says existing projects get working-mode via bootstrap"
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
assert_grep 'work-item-lifecycle.md' "${AI_REPO}/README.md" \
  "README links to the work-item lifecycle contract"
assert_grep 'gh. is optional' "${AI_REPO}/docs/adopting-projects.md" \
  "adopting-projects states gh is optional"
assert_grep 'Existing project Issue/PR/branch' \
  "${AI_REPO}/docs/adopting-projects.md" \
  "adopting-projects states existing project conventions are respected"
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
assert_dir "${AI_REPO}/.agents/skills/impeccable" "Impeccable skill is present"
assert_grep 'version: 4\.3\.1' \
  "${AI_REPO}/.agents/skills/impeccable/SKILL.md" \
  "Impeccable skill version is 4.3.1"
assert_file "${AI_REPO}/.agents/skills/impeccable/scripts/impeccable" \
  "Impeccable launcher is present"
assert_file "${AI_REPO}/.claude/skills/hallmark/SKILL.md" \
  "Claude adapter exposes Hallmark"
assert_file "${AI_REPO}/.grok/skills/hallmark/SKILL.md" \
  "Grok adapter exposes Hallmark"
assert_file "${AI_REPO}/.claude/skills/impeccable/SKILL.md" \
  "Claude adapter exposes Impeccable"
assert_file "${AI_REPO}/.grok/skills/impeccable/SKILL.md" \
  "Grok adapter exposes Impeccable"
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
assert_grep '"impeccable"' "${AI_REPO}/skills-lock.json" \
  "skills-lock.json pins Impeccable"
assert_grep '"source": "pbakaus/impeccable"' "${AI_REPO}/skills-lock.json" \
  "skills-lock.json uses the official Impeccable source"
assert_not_grep 'frontend-design' "${AI_REPO}/skills-lock.json" \
  "skills-lock.json does not pin frontend-design"
assert_not_grep 'ui-ux-pro-max' "${AI_REPO}/skills-lock.json" \
  "skills-lock.json does not pin ui-ux-pro-max"
assert_not_grep 'superdesign' "${AI_REPO}/skills-lock.json" \
  "skills-lock.json does not pin Superdesign"
assert_not_grep 'Automatically consult' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not auto-load multiple taste skills"
assert_grep 'remain retired' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui keeps retired design skills out of the stack"
assert_grep 'Scope router' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui classifies UI scope"
assert_grep 'Do \*\*not\*\* load Impeccable or Hallmark' "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "small UI does not automatically load a design skill"
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
assert_grep 'managed design stack is Impeccable plus Hallmark' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui defines the routed managed design stack"
assert_grep 'Impeccable is primary for product and application UI' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui routes product UI to Impeccable"
assert_grep 'Hallmark is specialist art direction' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui routes expressive art direction to Hallmark"
assert_grep 'Do not combine them merely to get a second opinion' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui prevents default multi-skill loading"
assert_grep 'skills never outrank' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui preserves project design authority"
assert_grep 'availability is not authorization' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "Impeccable does not expand tool authorization"
assert_grep 'outrank Impeccable and Hallmark' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui design constraints outrank both skills"
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
assert_grep 'Simplicity is capable, not empty' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires capable simplicity, not empty screens"
assert_grep '## Interaction quality' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui encodes interaction-quality principles"
assert_grep 'Progressive disclosure' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires progressive disclosure"
assert_grep 'Preserve context' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires preserved user context"
assert_grep 'approximately 44x44 CSS px' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui sets a practical touch-target floor"
assert_grep 'excessively light weights' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui rejects aesthetic-only light type weights"
assert_grep 'Do not globally prescribe visual trends' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not globally prescribe visual trends"
assert_grep 'higher-authority creative direction' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "approved visual references outrank skill defaults"
assert_grep 'must not silently create a parallel design system' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui forbids skills from creating a parallel design system"
assert_grep 'Responsive layout is not a shrunk desktop' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui forbids treating responsive layout as a shrunk desktop"
assert_grep 'at relevant breakpoints' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "significant UI review is against the rendered result at breakpoints"
assert_grep 'simplicity rather than empty screens' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core requires capable simplicity"
assert_grep 'override project design systems' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core keeps design skills from overriding usability principles"
assert_grep 'Cards are semantic containers' \
  "${AI_REPO}/docs/contracts/adrs/0004-design-stack-and-ui-visual-verification.md" \
  "design-stack ADR does not treat cards as prohibited"
assert_grep 'not a mechanical alternating-background rule' \
  "${AI_REPO}/docs/contracts/adrs/0004-design-stack-and-ui-visual-verification.md" \
  "design-stack ADR does not mandate alternating section backgrounds"
assert_not_grep 'over cards, dividers' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core does not rank hierarchy over cards as such"
assert_grep '### Substantial redesign' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires a substantial-redesign comp gate"
assert_grep 'design-reviews/<slug>/index.html' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui saves the review comp at a stable project path"
assert_grep 'does not authorize deployment' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not treat comp generation as deployment authorization"
assert_grep 'small polish, copy changes, straightforward fixes' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui keeps small UI off the comp gate"
assert_grep 'Impeccable `shape` owns discovery' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui keeps shape as discovery rather than a second design process"
assert_grep 'Do not fork either skill' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui does not encode the comp gate by forking vendor skills"
assert_file "${AI_REPO}/core/prompts/ui-comp-approval.md" \
  "UI comp approval checklist exists"
assert_grep 'file://' \
  "${AI_REPO}/core/prompts/ui-comp-approval.md" \
  "comp checklist tells the user how to open the comp in a browser"
assert_grep 'Stop. Do not change application UI' \
  "${AI_REPO}/core/prompts/ui-comp-approval.md" \
  "comp checklist stops before application UI changes"
assert_file "${AI_REPO}/docs/contracts/adrs/0008-substantial-redesign-comp-approval.md" \
  "substantial-redesign comp ADR exists"
assert_grep 'comp approval gate' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core routes every agent to the comp approval gate"
assert_grep 'ui-comp-approval.md' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core points at the comp checklist"
assert_grep 'comp approval gate in' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "always-on platform rule points at the comp gate"
assert_grep 'Substantial-redesign review comp' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "browser QA distinguishes the review comp from Mode B"
assert_grep 'Playwright, not Mode A' \
  "${AI_REPO}/docs/contracts/features/browser-qa.md" \
  "browser-qa contract distinguishes the review comp from Playwright"
assert_not_grep 'design-reviews' \
  "${AI_REPO}/.agents/skills/impeccable/reference/shape.md" \
  "shape is not forked to host the harness comp gate"
assert_not_grep 'design-reviews' \
  "${AI_REPO}/.agents/skills/impeccable/reference/new-work.md" \
  "new-work is not forked to host the harness comp gate"
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
assert_grep 'outrank Impeccable and Hallmark' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core states UI constraints outrank both skills"
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
echo "--- Image generation protocol ---"
assert_grep '## Image generation / design exploration' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui owns the image-generation protocol"
assert_grep 'Do \*\*not\*\* invoke image generation by default' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "small UI does not invoke image generation by default"
assert_grep 'Explicitly choose the image model' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "image-generation model is chosen explicitly when supported"
assert_grep 'Explicitly choose quality, resolution, aspect ratio, and number of' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "image-generation quality, resolution, aspect ratio, and option count are chosen explicitly"
assert_grep 'Do not rely on generic model defaults' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "high-fidelity design work does not rely on generic image-model defaults"
assert_grep 'Choose settings from the artifact being designed' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "image-generation settings are adaptive to the artifact"
assert_grep 'Do not apply one' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "image generation does not apply one universal configuration"
assert_grep 'grok-imagine-image-2.0' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "Grok Imagine 2.0 high-fidelity baseline names grok-imagine-image-2.0"
assert_grep 'quality: `medium`' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "Grok high-fidelity baseline uses medium quality"
assert_grep 'resolution: `2k`' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "Grok high-fidelity baseline uses 2k resolution"
assert_grep 'Do not make' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui forbids making 16:9 a global image-generation default"
assert_grep '`16:9` a global default' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "16:9 is documented as not a global default"
assert_grep 'desktop dashboard or product surface: commonly `16:9`' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "16:9 is an artifact example, not a universal setting"
assert_grep 'website hero: the actual intended hero proportion' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "hero aspect ratio follows the actual intended proportion"
assert_grep 'mobile UI: an appropriate portrait ratio' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "mobile UI uses an appropriate portrait ratio"
assert_grep 'Generate 2–3 meaningfully different directions' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "exploration prefers 2-3 meaningfully different directions"
assert_grep 'not trivial' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "exploration directions must not be trivial variations"
assert_grep 'prefer editing the selected image in place rather' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "selected concepts should be edited rather than unnecessarily regenerated"
assert_grep 'Preserve unaffected areas during edits' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "edits preserve unaffected areas when supported"
assert_grep 'exploration/reference artifacts, not the' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "generated images are references, not implementation truth"
assert_grep 'the real rendered product is authoritative' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "the real rendered product remains authoritative after image generation"
assert_grep 'must not replace framework-native implementation or' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "image generation must not replace framework-native implementation or rendered QA"
assert_grep 'override generic image-model preferences' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "project design decisions override generic image-model preferences"
assert_grep 'does not authorize or' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "image-generation tool availability does not authorize or justify use"
assert_grep 'capability-on-demand' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "image generation stays consistent with capability-on-demand"
assert_grep 'Image generation does not replace that pass' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "image generation does not replace significant-UI Mode B verification"
assert_grep 'bounded Mode B visual verification' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "significant-UI Mode B visual verification remains intact"
assert_grep 'It is \*\*not\*\* authorization for a Mode A suite' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "significant UI still does not authorize a Mode A suite"
assert_grep 'creating or expanding a Playwright Mode A suite' \
  "${AI_REPO}/.cursor/rules/60-browser-qa.mdc" \
  "browser-qa still withholds Mode A from the bounded visual pass"
assert_grep 'capability-on-demand, not capability-by-default' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "capability-on-demand remains intact in the always-on platform rule"
assert_grep 'exploration/reference artifacts, not the' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core states generated images are not implementation truth"
assert_grep 'adapt those settings to the' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core requires adaptive image-generation settings"
assert_not_grep 'grok-imagine-image-2.0' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core does not duplicate the Grok-specific baseline"
assert_grep 'exploration/reference artifacts, not the implementation' \
  "${AI_REPO}/docs/contracts/adrs/0004-design-stack-and-ui-visual-verification.md" \
  "design-stack ADR records generated images as not implementation truth"
assert_grep 'Do not invent meaningful product metrics' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "visual briefs must not invent product metrics as filler"
assert_grep 'fake stock photos of people' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "visual briefs must not introduce fake stock photos of people by default"
assert_grep 'preserve them exactly unless' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "supplied UI labels are preserved exactly unless rewrite is requested"
assert_not_grep 'npx.*imagine' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "image-generation protocol does not add an external image-generation CLI"
assert_not_grep 'mcpServers' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "image-generation protocol does not add MCP server config"

echo ""
echo "--- Current symlink/bootstrap architecture ---"
assert_file "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap script remains the project-harness installer"
assert_file "${AI_REPO}/scripts/link-rules.sh" \
  "link-rules.sh remains a bootstrap alias"
assert_missing "${AI_REPO}/scripts/update-project-harness.sh" \
  "no project-harness update script was added"
assert_missing "${AI_REPO}/scripts/update-harness.sh" \
  "no generic harness update script was added"
assert_grep '^\.ai/?$' "${AI_REPO}/.gitignore" \
  "platform gitignore ignores .ai/"
assert_grep '^\.DS_Store$' "${AI_REPO}/.gitignore" \
  "platform gitignore ignores .DS_Store"
assert_grep '^\*\*/\.DS_Store$' "${AI_REPO}/.gitignore" \
  "platform gitignore ignores nested .DS_Store"
assert_missing "${AI_REPO}/.ai/rules" \
  "platform does not migrate rules into a project-local .ai/rules tree"
assert_missing "${AI_REPO}/.ai/guidelines" \
  "platform repo does not ship a project-local .ai/guidelines tree"
assert_file "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "canonical UI rule remains in .cursor/rules"
assert_grep 'Canonical detailed rules live in `.cursor/rules/`' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core still points at .cursor/rules as canonical"
assert_grep 'symlinked from the' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core still describes current rule symlink architecture"
assert_not_grep 'v1\.4\.0' "${AI_REPO}/README.md" \
  "README does not begin a later unreleased version"
assert_grep '^Version 1\.3\.0$' "${AI_REPO}/README.md" \
  "README version is 1.3.0"
assert_grep '^Version 1\.3\.0$' "${AI_REPO}/docs/00-project-context.md" \
  "project context version is 1.3.0"
assert_grep '\.DS_Store' "${AI_REPO}/.cursor/rules/50-workflows.mdc" \
  "workflows document macOS gitignore entries"
assert_grep '`\.ai/`' "${AI_REPO}/.cursor/rules/50-workflows.mdc" \
  "workflows document ignoring .ai/"

echo ""
echo "--- Copy and Tailwind guardrails ---"
assert_file "${AI_REPO}/scripts/check-guardrails.sh" \
  "check-guardrails.sh exists"
assert_file "${AI_REPO}/scripts/lib/check_guardrails.py" \
  "guardrail scanner exists"
assert_file "${AI_REPO}/docs/contracts/adrs/0006-instruction-precedence-and-mechanical-guardrails.md" \
  "guardrail ADR exists"
assert_file "${AI_REPO}/docs/contracts/features/copy-and-tailwind-guardrails.md" \
  "guardrail feature contract exists"
assert_grep 'standard utility scale when an equivalent exists' \
  "${AI_REPO}/.cursor/rules/20-coding.mdc" \
  "20-coding requires Tailwind standard-scale first"
assert_grep 'Arbitrary values remain valid when genuinely necessary' \
  "${AI_REPO}/.cursor/rules/20-coding.mdc" \
  "20-coding keeps an arbitrary-value exception"
assert_grep 'guardrail-allow-arbitrary' \
  "${AI_REPO}/.cursor/rules/20-coding.mdc" \
  "20-coding documents the arbitrary-value exception marker"
assert_grep 'text-\[1\.2rem\]' \
  "${AI_REPO}/.cursor/rules/20-coding.mdc" \
  "20-coding names text-[1.2rem] as undesirable default behavior"
assert_grep '&mdash;' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui prohibits &mdash; as well as the em dash character"
assert_grep 'page metadata' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui applies the em-dash rule to page metadata"
assert_grep 'Hallmark copy and typography guidance may recommend' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui overrides Hallmark em-dash guidance without forking Hallmark"
assert_grep 'Em-dash for interruption' \
  "${AI_REPO}/.agents/skills/hallmark/references/copy.md" \
  "Hallmark vendor copy still recommends em dashes"
assert_grep 'Secondary implementation guidance' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform names secondary implementation guidance"
assert_grep 'weaken or override an applicable project' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform forbids secondary sources silently overriding project rules"
assert_grep 'Do not ask the user to resolve a conflict whose precedence is' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform does not ask when precedence is already clear"
assert_grep 'before implementing the conflicting decision' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform requires clarification for genuine instruction conflicts"
assert_grep 'Do not make an arbitrary choice' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "00-platform forbids arbitrary resolution of genuine conflicts"
assert_grep 'Secondary implementation guidance' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core names secondary implementation guidance"
assert_grep 'conflicting secondary guidance' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core states project/platform rules outrank secondary guidance"
assert_grep 'stop before implementing the conflicting decision' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core requires clarification for genuine instruction conflicts"
assert_grep 'standard utility scale' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core prefers Tailwind standard utilities over arbitrary values"
assert_grep '&mdash;' \
  "${AI_REPO}/core/agent-core.md" \
  "portable core includes &mdash; in the em-dash rule"
assert_grep 'scripts/check-guardrails.sh' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "always-on platform rule requires the guardrail check for applicable work"
assert_grep 'Lint, tests, and build passing do not' \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "always-on platform rule says lint/tests/build do not imply guardrails ran"
assert_grep 'scripts/check-guardrails.sh' \
  "${AI_REPO}/.cursor/rules/10-documentation.mdc" \
  "completion criteria include the guardrail check"
assert_grep 'A failed guardrail check is not a green completion' \
  "${AI_REPO}/.cursor/rules/10-documentation.mdc" \
  "completion criteria reject a green report after a failed guardrail check"
assert_grep 'scripts/check-guardrails.sh' \
  "${AI_REPO}/.cursor/rules/20-coding.mdc" \
  "coding quality requires the guardrail check for copy/Tailwind work"
assert_grep 'scripts/check-guardrails.sh' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "40-ui requires the guardrail check for copy and Tailwind work"
assert_grep 'small UI and copy-only work' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "em-dash enforcement is not limited to significant UI"
assert_grep 'check-guardrails.sh' \
  "${AI_REPO}/.cursor/rules/50-workflows.mdc" \
  "bootstrap links the guardrail check script"
assert_grep 'Do not fork Hallmark' \
  "${AI_REPO}/docs/contracts/adrs/0006-instruction-precedence-and-mechanical-guardrails.md" \
  "ADR 0006 keeps Hallmark unforked"
assert_grep 'git-changed files versus' \
  "${AI_REPO}/docs/contracts/features/copy-and-tailwind-guardrails.md" \
  "guardrail contract defaults to git-changed files"
assert_file "${AI_REPO}/.cursor/rules/36-wordpress-theme.mdc" \
  "36-wordpress-theme rule exists"
assert_grep 'Project Tailwind tokens are the typography and color source of truth' \
  "${AI_REPO}/.cursor/rules/36-wordpress-theme.mdc" \
  "wordpress theme rule keeps Tailwind tokens as the type and color source"
assert_grep 'Do not add `!important`' \
  "${AI_REPO}/.cursor/rules/36-wordpress-theme.mdc" \
  "wordpress theme rule does not prescribe !important"
assert_grep 'Do not remove `theme.json`' \
  "${AI_REPO}/.cursor/rules/36-wordpress-theme.mdc" \
  "wordpress theme rule keeps theme.json"
assert_grep 'Do not apply it to Laravel' \
  "${AI_REPO}/.cursor/rules/36-wordpress-theme.mdc" \
  "wordpress theme rule stays off non-WordPress stacks"
assert_grep '36-wordpress-theme.mdc' \
  "${AI_REPO}/.cursor/rules/35-roots.mdc" \
  "roots rule points at the wordpress theme rule"
assert_grep '36-wordpress-theme.mdc' \
  "${AI_REPO}/.cursor/rules/20-coding.mdc" \
  "coding rule points at the wordpress theme rule for WordPress theme.json"
assert_grep '36-wordpress-theme.mdc' \
  "${AI_REPO}/core/project-profiles/roots-radicle.md" \
  "roots profile points at the wordpress theme rule"

assert_file "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract exists"
assert_file "${AI_REPO}/docs/contracts/adrs/0009-roots-upgrade-procedure.md" \
  "Roots upgrade ADR exists"
assert_file "${AI_REPO}/core/prompts/roots-upgrade.md" \
  "Roots upgrade prompt exists"
assert_grep 'read-only' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract requires a read-only assessment"
assert_grep 'newest major is not a default target' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract does not default to the newest major"
assert_grep 'Immediate security remediation' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract classifies security remediation"
assert_grep 'Compatible patch or minor maintenance' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract classifies maintenance"
assert_grep 'Framework upgrade' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract classifies framework upgrades"
assert_grep 'Major architectural migration' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract classifies architectural migrations"
assert_grep 'Deferred or blocked' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract classifies deferred work"
assert_grep 'roots/radicle' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract detects Radicle by composer name"
assert_grep 'When a routine update is enough' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract defines the routine-update boundary"
assert_not_grep 'evoscapes' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract does not hardcode a project name"
assert_grep 'docs/contracts/features/roots-upgrade.md' \
  "${AI_REPO}/.cursor/rules/35-roots.mdc" \
  "35-roots points at the Roots upgrade contract"
assert_grep 'docs/contracts/features/roots-upgrade.md' \
  "${AI_REPO}/core/agent-core.md" \
  "agent core points at the Roots upgrade contract"
assert_grep 'docs/contracts/features/roots-upgrade.md' \
  "${AI_REPO}/core/prompts/roots-upgrade.md" \
  "Roots upgrade prompt points at the contract"
assert_grep 'docs/contracts/planning/roots-upgrade.md' \
  "${AI_REPO}/core/prompts/roots-upgrade.md" \
  "Roots upgrade prompt writes the plan in the project"
assert_grep 'not an application root' \
  "${AI_REPO}/core/prompts/roots-upgrade.md" \
  "Roots upgrade prompt ignores plugin-internal composer files"
assert_grep 'Do not plan' \
  "${AI_REPO}/docs/contracts/features/roots-upgrade.md" \
  "Roots upgrade contract does not upgrade inside plugin source"

GUARD_FIXTURES="${WORKDIR}/guardrail-fixtures"
mkdir -p "${GUARD_FIXTURES}/resources/views" "${GUARD_FIXTURES}/resources/css"

cat > "${GUARD_FIXTURES}/resources/views/em-dash.blade.php" <<'EOF'
<p>Quality salt — harvested by hand.</p>
EOF
cat > "${GUARD_FIXTURES}/resources/views/mdash.blade.php" <<'EOF'
<p>Quality salt &mdash; harvested by hand.</p>
EOF
cat > "${GUARD_FIXTURES}/resources/views/entity-numeric.blade.php" <<'EOF'
<p>Quality salt &#8212; harvested by hand.</p>
EOF
cat > "${GUARD_FIXTURES}/resources/views/text-arbitrary.blade.php" <<'EOF'
<h1 class="text-[1.2rem]">Headline</h1>
EOF
cat > "${GUARD_FIXTURES}/resources/views/many-text-arbitrary.blade.php" <<'EOF'
<h1 class="text-[2.35rem]">Display</h1>
<p class="text-[1.2rem]">Lead</p>
<span class="text-[0.95rem]">Meta</span>
EOF
cat > "${GUARD_FIXTURES}/resources/views/spacing-arbitrary.blade.php" <<'EOF'
<section class="mt-[17px] px-[22px]">Content</section>
EOF
cat > "${GUARD_FIXTURES}/resources/views/source-quote.blade.php" <<'EOF'
{{-- guardrail-allow-em-dash: original publication title --}}
<blockquote>Quality salt — harvested by hand.</blockquote>
EOF
cat > "${GUARD_FIXTURES}/resources/views/necessary-arbitrary.blade.php" <<'EOF'
{{-- guardrail-allow-arbitrary: clip to the physical brand-mark box --}}
<div class="max-w-[1173px]">Mark</div>
EOF
cat > "${GUARD_FIXTURES}/resources/css/theme.css" <<'EOF'
@theme {
  --text-display: 2.35rem;
  --spacing-section: 4.5rem;
}
EOF
cat > "${GUARD_FIXTURES}/resources/views/theme-tokens.blade.php" <<'EOF'
<h1 class="text-display mt-section">Headline</h1>
EOF
cat > "${GUARD_FIXTURES}/resources/views/file-allow.blade.php" <<'EOF'
{{-- guardrail-allow-file: em-dash --}}
<p>Quoted source title — 1998 reprint.</p>
EOF

if "${AI_REPO}/scripts/check-guardrails.sh" "${GUARD_FIXTURES}" --files \
  resources/views/em-dash.blade.php >"${LOGDIR}/guard-em-dash.log" 2>&1; then
  fail "em dash in generated copy fails the guardrail check"
else
  pass "em dash in generated copy fails the guardrail check"
fi
assert_grep 'em dash' "${LOGDIR}/guard-em-dash.log" \
  "em dash failure names the em dash"

if "${AI_REPO}/scripts/check-guardrails.sh" "${GUARD_FIXTURES}" --files \
  resources/views/mdash.blade.php >"${LOGDIR}/guard-mdash.log" 2>&1; then
  fail "&mdash; in generated copy fails the guardrail check"
else
  pass "&mdash; in generated copy fails the guardrail check"
fi
assert_grep '&mdash;' "${LOGDIR}/guard-mdash.log" \
  "&mdash; failure names the entity"

if "${AI_REPO}/scripts/check-guardrails.sh" "${GUARD_FIXTURES}" --files \
  resources/views/entity-numeric.blade.php >"${LOGDIR}/guard-entity.log" 2>&1; then
  fail "numeric em-dash entity fails the guardrail check"
else
  pass "numeric em-dash entity fails the guardrail check"
fi

if "${AI_REPO}/scripts/check-guardrails.sh" "${GUARD_FIXTURES}" --files \
  resources/views/text-arbitrary.blade.php >"${LOGDIR}/guard-text.log" 2>&1; then
  fail "text-[1.2rem] fails the guardrail check"
else
  pass "text-[1.2rem] fails the guardrail check"
fi
assert_grep 'text-\[1\.2rem\]' "${LOGDIR}/guard-text.log" \
  "arbitrary text-size failure names the class"

if "${AI_REPO}/scripts/check-guardrails.sh" "${GUARD_FIXTURES}" --files \
  resources/views/many-text-arbitrary.blade.php >"${LOGDIR}/guard-many-text.log" 2>&1; then
  fail "several arbitrary font sizes fail the guardrail check"
else
  pass "several arbitrary font sizes fail the guardrail check"
fi
many_count="$(grep -c 'arbitrary Tailwind utility' "${LOGDIR}/guard-many-text.log" || true)"
if [[ "${many_count}" -ge 3 ]]; then
  pass "several arbitrary font sizes are each reported (${many_count})"
else
  fail "several arbitrary font sizes are each reported (${many_count})"
fi

if "${AI_REPO}/scripts/check-guardrails.sh" "${GUARD_FIXTURES}" --files \
  resources/views/spacing-arbitrary.blade.php >"${LOGDIR}/guard-spacing.log" 2>&1; then
  fail "arbitrary spacing fails the guardrail check"
else
  pass "arbitrary spacing fails the guardrail check"
fi
assert_grep 'mt-\[17px\]' "${LOGDIR}/guard-spacing.log" \
  "arbitrary spacing failure names mt-[17px]"

if "${AI_REPO}/scripts/check-guardrails.sh" "${GUARD_FIXTURES}" --files \
  resources/views/source-quote.blade.php >"${LOGDIR}/guard-source.log" 2>&1; then
  pass "source material with em-dash exception marker passes"
else
  fail "source material with em-dash exception marker passes"
  cat "${LOGDIR}/guard-source.log"
fi

if "${AI_REPO}/scripts/check-guardrails.sh" "${GUARD_FIXTURES}" --files \
  resources/views/necessary-arbitrary.blade.php >"${LOGDIR}/guard-allow-arb.log" 2>&1; then
  pass "genuine one-off arbitrary value with exception marker passes"
else
  fail "genuine one-off arbitrary value with exception marker passes"
  cat "${LOGDIR}/guard-allow-arb.log"
fi

if "${AI_REPO}/scripts/check-guardrails.sh" "${GUARD_FIXTURES}" --files \
  resources/css/theme.css resources/views/theme-tokens.blade.php \
  >"${LOGDIR}/guard-theme.log" 2>&1; then
  pass "project theme tokens are not flagged as arbitrary utilities"
else
  fail "project theme tokens are not flagged as arbitrary utilities"
  cat "${LOGDIR}/guard-theme.log"
fi

if "${AI_REPO}/scripts/check-guardrails.sh" "${GUARD_FIXTURES}" --files \
  resources/views/file-allow.blade.php >"${LOGDIR}/guard-file-allow.log" 2>&1; then
  pass "file-level em-dash exception marker passes"
else
  fail "file-level em-dash exception marker passes"
  cat "${LOGDIR}/guard-file-allow.log"
fi

HALLMARK_COPY="${WORKDIR}/hallmark-cannot-pass.blade.php"
cat > "${HALLMARK_COPY}" <<'EOF'
<p>A studio for what is next — printed matter included.</p>
EOF
if "${AI_REPO}/scripts/check-guardrails.sh" "${WORKDIR}" --files \
  hallmark-cannot-pass.blade.php >"${LOGDIR}/guard-hallmark.log" 2>&1; then
  fail "Hallmark-style em dash copy cannot pass the guardrail check"
else
  pass "Hallmark-style em dash copy cannot pass the guardrail check"
fi

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
assert_grep 'managed design stack is Impeccable plus Hallmark' \
  "${AI_REPO}/.cursor/rules/40-ui.mdc" \
  "routed design stack remains in force"
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
assert_grep "Deployer is not required of the harness clone" "${LOGDIR}/doctor-platform.log" \
  "doctor does not require Deployer of the platform repo"

echo ""
echo "--- Generic new project ---"
GENERIC="${WORKDIR}/generic"
mkdir -p "${GENERIC}"
printf 'hello\n' > "${GENERIC}/README.md"

"${AI_REPO}/scripts/bootstrap-project.sh" "${GENERIC}" >${LOGDIR}/boot-generic.log 2>&1

assert_file "${GENERIC}/docs/README.md" "generic received docs templates"
assert_file "${GENERIC}/docs/working-mode.md" \
  "generic received working-mode template"
assert_file "${GENERIC}/docs/contracts/features/public-submissions.md" \
  "generic new project received public-submissions record"
assert_grep 'not applicable' "${GENERIC}/docs/contracts/features/public-submissions.md" \
  "public-submissions template records not applicable"
assert_grep 'spam-and-abuse-protection.md' \
  "${GENERIC}/docs/contracts/features/public-submissions.md" \
  "public-submissions template points at the canonical contract"
assert_not_grep 'Turnstile' ${LOGDIR}/boot-generic.log \
  "bootstrap does not install or recommend Turnstile"
assert_file "${GENERIC}/AGENTS.md" "generic received AGENTS.md"
assert_file "${GENERIC}/CLAUDE.md" "generic received CLAUDE.md"
if [[ -L "${GENERIC}/AGENTS.md" ]] && [[ "$(readlink "${GENERIC}/AGENTS.md")" == "${AI_REPO}/core/agent-core.md" ]]; then
  pass "generic AGENTS.md links to canonical agent-core"
else
  fail "generic AGENTS.md links to canonical agent-core"
fi
assert_grep '@AGENTS.md' "${GENERIC}/CLAUDE.md" \
  "generic CLAUDE.md imports AGENTS.md"
assert_grep 'Added CLAUDE.md' ${LOGDIR}/boot-generic.log \
  "bootstrap reports CLAUDE.md as added, not as a fill-in draft"
assert_not_grep 'Fill from this project' ${LOGDIR}/boot-generic.log \
  "first-run CLAUDE.md copy does not ask the user to fill a documentation draft"
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
assert_grep '^# impeccable-ignore-start$' "${GENERIC}/.gitignore" \
  "generic gitignore includes Impeccable ephemeral-artifact block"
assert_grep '^\.impeccable/review/$' "${GENERIC}/.gitignore" \
  "generic gitignore ignores Impeccable review captures"
assert_not_grep '^\.impeccable/config\.json$' "${GENERIC}/.gitignore" \
  "generic gitignore keeps shared Impeccable config tracked"
assert_not_grep '^\.impeccable/design\.json$' "${GENERIC}/.gitignore" \
  "generic gitignore keeps Impeccable design sidecar tracked"
assert_not_grep '^design\.md' "${GENERIC}/.gitignore" \
  "generic gitignore does not ignore design.md"
assert_grep '^\.DS_Store$' "${GENERIC}/.gitignore" \
  "generic gitignore ignores .DS_Store"
assert_not_grep '^\*\*/\.DS_Store$' "${GENERIC}/.gitignore" \
  "generic gitignore does not add redundant nested .DS_Store"
assert_grep '^\.ai/?$' "${GENERIC}/.gitignore" \
  "generic gitignore ignores .ai/"
assert_grep '^# macOS$' "${GENERIC}/.gitignore" \
  "generic gitignore labels macOS ignore entries"
assert_grep '^# AI Development Harness$' "${GENERIC}/.gitignore" \
  "generic gitignore labels harness local ignore entries"

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

if [[ -L "${GENERIC}/scripts/check-guardrails.sh" ]] && [[ "$(readlink "${GENERIC}/scripts/check-guardrails.sh")" == "${AI_REPO}/scripts/check-guardrails.sh" ]]; then
  pass "generic received check-guardrails.sh link"
else
  fail "generic received check-guardrails.sh link"
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
assert_grep "Guardrail check script linked" ${LOGDIR}/doctor-generic.log \
  "doctor reports the guardrail script is linked"
assert_grep "Deployer not installed" ${LOGDIR}/doctor-generic.log \
  "doctor treats Deployer absence as valid on generic projects"
assert_missing "${GENERIC}/deploy.php" \
  "non-interactive generic bootstrap does not install Deployer"

echo ""
echo "--- Skill adapter links (bootstrap from harness cwd) ---"
mkdir -p \
  "${GENERIC}/.agents/skills/hallmark" \
  "${GENERIC}/.agents/skills/impeccable"
printf '# Hallmark\n' > "${GENERIC}/.agents/skills/hallmark/SKILL.md"
printf '# Impeccable\n' > "${GENERIC}/.agents/skills/impeccable/SKILL.md"
"${AI_REPO}/scripts/bootstrap-project.sh" "${GENERIC}" \
  >"${LOGDIR}/boot-generic-adapters.log" 2>&1
if [[ -L "${GENERIC}/.claude/skills/hallmark" ]] \
  && [[ "$(readlink "${GENERIC}/.claude/skills/hallmark")" == "../../.agents/skills/hallmark" ]]; then
  pass "generic Claude skill adapter links to .agents/skills/hallmark"
else
  fail "generic Claude skill adapter links to .agents/skills/hallmark"
fi
if [[ -L "${GENERIC}/.grok/skills/hallmark" ]] \
  && [[ "$(readlink "${GENERIC}/.grok/skills/hallmark")" == "../../.agents/skills/hallmark" ]]; then
  pass "generic Grok skill adapter links to .agents/skills/hallmark"
else
  fail "generic Grok skill adapter links to .agents/skills/hallmark"
fi
if [[ -L "${GENERIC}/.claude/skills/impeccable" ]] \
  && [[ "$(readlink "${GENERIC}/.claude/skills/impeccable")" == "../../.agents/skills/impeccable" ]]; then
  pass "generic Claude skill adapter links to .agents/skills/impeccable"
else
  fail "generic Claude skill adapter links to .agents/skills/impeccable"
fi
if [[ -L "${GENERIC}/.grok/skills/impeccable" ]] \
  && [[ "$(readlink "${GENERIC}/.grok/skills/impeccable")" == "../../.agents/skills/impeccable" ]]; then
  pass "generic Grok skill adapter links to .agents/skills/impeccable"
else
  fail "generic Grok skill adapter links to .agents/skills/impeccable"
fi
assert_not_grep 'missing source for Claude skill' \
  "${LOGDIR}/boot-generic-adapters.log" \
  "bootstrap does not warn that the Claude skill source is missing"
if "${AI_REPO}/scripts/doctor.sh" "${GENERIC}" \
  >"${LOGDIR}/doctor-generic-adapters.log" 2>&1; then
  pass "doctor on generic project with skill adapters exits 0"
else
  fail "doctor on generic project with skill adapters exits 0"
  cat "${LOGDIR}/doctor-generic-adapters.log"
fi
assert_grep "Claude skill adapter linked: hallmark" \
  "${LOGDIR}/doctor-generic-adapters.log" \
  "doctor reports the Claude skill adapter is linked"
assert_grep "Grok skill adapter linked: hallmark" \
  "${LOGDIR}/doctor-generic-adapters.log" \
  "doctor reports the Grok skill adapter is linked"
assert_grep "Claude skill adapter linked: impeccable" \
  "${LOGDIR}/doctor-generic-adapters.log" \
  "doctor reports the Impeccable Claude adapter is linked"
assert_grep "Grok skill adapter linked: impeccable" \
  "${LOGDIR}/doctor-generic-adapters.log" \
  "doctor reports the Impeccable Grok adapter is linked"

echo ""
echo "--- New Roots/Radicle project ---"
RADICLE_NEW="${WORKDIR}/radicle-new"
mkdir -p "${RADICLE_NEW}"
write_radicle_composer "${RADICLE_NEW}"

"${AI_REPO}/scripts/bootstrap-project.sh" "${RADICLE_NEW}" >${LOGDIR}/boot-radicle-new.log 2>&1

assert_file "${RADICLE_NEW}/docs/README.md" "Radicle project received docs templates"
assert_file "${RADICLE_NEW}/docs/contracts/features/public-submissions.md" \
  "Radicle project received public-submissions record"
assert_missing "${RADICLE_NEW}/docs/contracts/features/browser-qa.md" \
  "Radicle project did not receive browser-QA template"
assert_dir "${RADICLE_NEW}/resources/images" \
  "new Radicle project received resources/images"
assert_file "${RADICLE_NEW}/resources/images/.gitkeep" \
  "new Radicle resources/images has .gitkeep"
assert_not_grep 'playwright-report' "${RADICLE_NEW}/.gitignore" \
  "Radicle gitignore has no Playwright artifacts"
assert_grep '^\.DS_Store$' "${RADICLE_NEW}/.gitignore" \
  "Radicle gitignore ignores .DS_Store"
assert_not_grep '^\*\*/\.DS_Store$' "${RADICLE_NEW}/.gitignore" \
  "Radicle gitignore does not add redundant nested .DS_Store"
assert_grep '^\.ai/?$' "${RADICLE_NEW}/.gitignore" \
  "Radicle gitignore ignores .ai/"
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
assert_file "${RADICLE_EXISTING}/docs/contracts/features/public-submissions.md" \
  "existing Radicle project received missing public-submissions draft"
assert_not_grep 'Turnstile' ${LOGDIR}/boot-radicle-existing.log \
  "existing Radicle bootstrap does not install Turnstile"
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
assert_file "${LARAVEL_NEW}/docs/contracts/features/public-submissions.md" \
  "new Laravel project received public-submissions record"
assert_missing "${LARAVEL_NEW}/resources/images" \
  "Laravel project did not receive Roots resources/images"
assert_grep 'playwright-report' "${LARAVEL_NEW}/.gitignore" \
  "new Laravel gitignore includes Playwright artifacts"
assert_grep '^\.DS_Store$' "${LARAVEL_NEW}/.gitignore" \
  "new Laravel gitignore ignores .DS_Store"
assert_not_grep '^\*\*/\.DS_Store$' "${LARAVEL_NEW}/.gitignore" \
  "new Laravel gitignore does not add redundant nested .DS_Store"
assert_grep '^\.ai/?$' "${LARAVEL_NEW}/.gitignore" \
  "new Laravel gitignore ignores .ai/"
assert_grep "Detected profile: laravel-webapp" ${LOGDIR}/boot-laravel-new.log \
  "bootstrap detects laravel-webapp profile"
assert_missing "${LARAVEL_NEW}/deploy.php" \
  "non-interactive Laravel bootstrap does not install Deployer by default"
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
assert_file "${LARAVEL_EXISTING}/docs/contracts/features/public-submissions.md" \
  "existing Laravel project received missing public-submissions draft"
assert_grep 'Do not install protection during bootstrap' ${LOGDIR}/boot-existing.log \
  "existing-project public-submissions draft does not install protection"
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
assert_grep 'Fill from this project' ${LOGDIR}/boot-existing.log \
  "existing-project drafts still tell the user to fill from project reality"

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
printf 'UNIQUE_GITIGNORE_MARKER\n' > "${EXISTING_GH}/.gitignore"

"${AI_REPO}/scripts/bootstrap-project.sh" "${EXISTING_GH}" >${LOGDIR}/boot-existing-github.log 2>&1

assert_grep "UNIQUE_PR_TEMPLATE_MARKER" "${EXISTING_GH}/.github/PULL_REQUEST_TEMPLATE.md" \
  "existing PR template was not overwritten"
assert_grep "UNIQUE_ISSUE_TEMPLATE_MARKER" "${EXISTING_GH}/.github/ISSUE_TEMPLATE/bug.md" \
  "existing Issue template was not overwritten"
assert_grep "UNIQUE_WORKING_MODE_MARKER" "${EXISTING_GH}/docs/working-mode.md" \
  "existing working-mode was not overwritten"
assert_grep "UNIQUE_GITIGNORE_MARKER" "${EXISTING_GH}/.gitignore" \
  "existing gitignore contents were preserved"
assert_grep '^\.DS_Store$' "${EXISTING_GH}/.gitignore" \
  "existing-project gitignore gained .DS_Store"
assert_not_grep '^\*\*/\.DS_Store$' "${EXISTING_GH}/.gitignore" \
  "existing-project gitignore did not gain redundant nested .DS_Store"
assert_grep '^\.ai/?$' "${EXISTING_GH}/.gitignore" \
  "existing-project gitignore gained .ai/"
assert_grep "does not copy or overwrite .github/" ${LOGDIR}/boot-existing-github.log \
  "existing-project bootstrap states it does not overwrite GitHub templates"
assert_not_grep 'gh auth' ${LOGDIR}/boot-existing-github.log \
  "bootstrap does not authenticate GitHub CLI"

echo ""
echo "--- macOS metadata gitignore coverage ---"
DS_MISSING="${WORKDIR}/ds-missing"
mkdir -p "${DS_MISSING}"
printf 'vendor/\nresources/.DS_Store\n' > "${DS_MISSING}/.gitignore"
"${AI_REPO}/scripts/bootstrap-project.sh" "${DS_MISSING}" >${LOGDIR}/boot-ds-missing.log 2>&1
"${AI_REPO}/scripts/bootstrap-project.sh" "${DS_MISSING}" >${LOGDIR}/boot-ds-missing-2.log 2>&1
assert_grep '^vendor/$' "${DS_MISSING}/.gitignore" \
  "existing gitignore without a global .DS_Store rule keeps its contents"
assert_grep '^resources/\.DS_Store$' "${DS_MISSING}/.gitignore" \
  "path-specific .DS_Store rules are preserved"
ds_missing_count="$(grep -cE '^\.DS_Store$' "${DS_MISSING}/.gitignore" || true)"
if [[ "${ds_missing_count}" -eq 1 ]]; then
  pass "missing global .DS_Store rule is added once across two bootstraps"
else
  fail "missing global .DS_Store rule is added once across two bootstraps (count=${ds_missing_count})"
fi
assert_not_grep '^\*\*/\.DS_Store$' "${DS_MISSING}/.gitignore" \
  "path-specific coverage does not cause a redundant nested rule"

DS_PRESENT="${WORKDIR}/ds-present"
mkdir -p "${DS_PRESENT}"
printf 'keep-me\n.DS_Store\n' > "${DS_PRESENT}/.gitignore"
"${AI_REPO}/scripts/bootstrap-project.sh" "${DS_PRESENT}" >${LOGDIR}/boot-ds-present.log 2>&1
"${AI_REPO}/scripts/bootstrap-project.sh" "${DS_PRESENT}" >${LOGDIR}/boot-ds-present-2.log 2>&1
assert_grep '^keep-me$' "${DS_PRESENT}/.gitignore" \
  "gitignore that already ignores .DS_Store keeps its contents"
ds_present_count="$(grep -cE '^\.DS_Store$' "${DS_PRESENT}/.gitignore" || true)"
if [[ "${ds_present_count}" -eq 1 ]]; then
  pass "existing .DS_Store rule is not duplicated"
else
  fail "existing .DS_Store rule is not duplicated (count=${ds_present_count})"
fi
assert_not_grep '^\*\*/\.DS_Store$' "${DS_PRESENT}/.gitignore" \
  "existing .DS_Store rule does not gain a nested variant"

DS_GLOB="${WORKDIR}/ds-glob"
mkdir -p "${DS_GLOB}"
printf '**/.DS_Store\n' > "${DS_GLOB}/.gitignore"
"${AI_REPO}/scripts/bootstrap-project.sh" "${DS_GLOB}" >${LOGDIR}/boot-ds-glob.log 2>&1
"${AI_REPO}/scripts/bootstrap-project.sh" "${DS_GLOB}" >${LOGDIR}/boot-ds-glob-2.log 2>&1
assert_not_grep '^\.DS_Store$' "${DS_GLOB}/.gitignore" \
  "existing **/.DS_Store coverage does not add a second global rule"
ds_glob_count="$(grep -cE '^\*\*/\.DS_Store$' "${DS_GLOB}/.gitignore" || true)"
if [[ "${ds_glob_count}" -eq 1 ]]; then
  pass "existing **/.DS_Store rule is not duplicated"
else
  fail "existing **/.DS_Store rule is not duplicated (count=${ds_glob_count})"
fi

DS_STAR="${WORKDIR}/ds-star"
mkdir -p "${DS_STAR}"
printf '*.DS_Store\n' > "${DS_STAR}/.gitignore"
"${AI_REPO}/scripts/bootstrap-project.sh" "${DS_STAR}" >${LOGDIR}/boot-ds-star.log 2>&1
assert_not_grep '^\.DS_Store$' "${DS_STAR}/.gitignore" \
  "existing *.DS_Store coverage does not add a second global rule"
assert_grep '^\*\.DS_Store$' "${DS_STAR}/.gitignore" \
  "existing *.DS_Store rule is preserved"

DS_NONE="${WORKDIR}/ds-none"
mkdir -p "${DS_NONE}"
"${AI_REPO}/scripts/bootstrap-project.sh" "${DS_NONE}" >${LOGDIR}/boot-ds-none.log 2>&1
"${AI_REPO}/scripts/bootstrap-project.sh" "${DS_NONE}" >${LOGDIR}/boot-ds-none-2.log 2>&1
assert_file "${DS_NONE}/.gitignore" \
  "project without a .gitignore receives one"
ds_none_count="$(grep -cE '^\.DS_Store$' "${DS_NONE}/.gitignore" || true)"
if [[ "${ds_none_count}" -eq 1 ]]; then
  pass "created .gitignore contains one .DS_Store rule after two bootstraps"
else
  fail "created .gitignore contains one .DS_Store rule after two bootstraps (count=${ds_none_count})"
fi
assert_not_grep '^\*\*/\.DS_Store$' "${DS_NONE}/.gitignore" \
  "created .gitignore does not add redundant nested .DS_Store"

echo ""
echo "--- Idempotent re-run (generic) ---"
"${AI_REPO}/scripts/bootstrap-project.sh" "${GENERIC}" >${LOGDIR}/boot-generic-2.log 2>&1
build_count="$(grep -cE '^\.build/?$' "${GENERIC}/.gitignore" || true)"
if [[ "${build_count}" -eq 1 ]]; then
  pass "re-run does not duplicate .build/ gitignore"
else
  fail "re-run does not duplicate .build/ gitignore (count=${build_count})"
fi
ds_count="$(grep -cE '^\.DS_Store$' "${GENERIC}/.gitignore" || true)"
if [[ "${ds_count}" -eq 1 ]]; then
  pass "re-run does not duplicate .DS_Store gitignore"
else
  fail "re-run does not duplicate .DS_Store gitignore (count=${ds_count})"
fi
nested_ds_count="$(grep -cE '^\*\*/\.DS_Store$' "${GENERIC}/.gitignore" || true)"
if [[ "${nested_ds_count}" -eq 0 ]]; then
  pass "re-run does not add redundant nested .DS_Store gitignore"
else
  fail "re-run does not add redundant nested .DS_Store gitignore (count=${nested_ds_count})"
fi
ai_count="$(grep -cE '^\.ai/?$' "${GENERIC}/.gitignore" || true)"
if [[ "${ai_count}" -eq 1 ]]; then
  pass "re-run does not duplicate .ai/ gitignore"
else
  fail "re-run does not duplicate .ai/ gitignore (count=${ai_count})"
fi
assert_file "${GENERIC}/docs/contracts/foundational/platform-reconciliation.md" \
  "re-bootstrap of a new project adds reconciliation (known limitation: docs index present)"
assert_grep "Existing project" ${LOGDIR}/boot-generic-2.log \
  "re-bootstrap of a new project is classified as existing (known limitation)"
assert_grep "core/prompts/project-adoption.md" ${LOGDIR}/boot-generic-2.log \
  "re-bootstrap of a new project prints the existing-project adoption prompt (known limitation)"

echo ""
echo "--- Deployer capability ---"
assert_file "${AI_REPO}/templates/deployer/laravel/deploy.php" \
  "Laravel Deployer recipe template exists"
assert_file "${AI_REPO}/templates/deployer/roots/deploy.php" \
  "Roots Deployer recipe template exists"
assert_file "${AI_REPO}/templates/deployer/bedrock/deploy.php" \
  "Bedrock Deployer recipe template exists"
assert_file "${AI_REPO}/templates/deployer/wordpress/deploy.php" \
  "WordPress Deployer recipe template exists"
assert_grep 'AI_PLATFORM_DEPLOYER_STACK=laravel' \
  "${AI_REPO}/templates/deployer/laravel/deploy.php" \
  "Laravel recipe is marked harness-managed"
assert_not_grep 'password' "${AI_REPO}/templates/deployer/hosts.yaml.example" \
  "hosts example does not contain password"
assert_not_grep 'BEGIN OPENSSH' "${AI_REPO}/templates/deployer/hosts.yaml.example" \
  "hosts example does not contain a private key"
assert_grep 'CHANGE_ME' "${AI_REPO}/templates/deployer/hosts.yaml.example" \
  "hosts example uses placeholders"
assert_grep 'with-deployer' "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap documents --with-deployer"
assert_grep 'without-deployer' "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap documents --without-deployer"
assert_grep 'capability-on-demand' \
  "${AI_REPO}/docs/contracts/features/deployer.md" \
  "Deployer contract states capability-on-demand"
assert_grep 'does not authorize deployment' \
  "${AI_REPO}/docs/contracts/features/deployer.md" \
  "Deployer contract repeats the authorization boundary"
assert_grep 'restorable production backup' \
  "${AI_REPO}/docs/contracts/features/deployer.md" \
  "Deployer contract preserves the production backup requirement"
assert_grep 'keep_releases' \
  "${AI_REPO}/docs/contracts/features/deployer.md" \
  "Deployer contract documents release retention"

DEP_PROMPT="${WORKDIR}/deployer-prompt"
mkdir -p "${DEP_PROMPT}"
write_laravel_composer "${DEP_PROMPT}" 0
unset AI_BOOTSTRAP_NONINTERACTIVE
printf '\n' | "${AI_REPO}/scripts/bootstrap-project.sh" "${DEP_PROMPT}" \
  >"${LOGDIR}/boot-deployer-prompt-n.log" 2>&1
export AI_BOOTSTRAP_NONINTERACTIVE=1
assert_grep 'Install Deployer deployment stack\? \[y/N\]' \
  "${LOGDIR}/boot-deployer-prompt-n.log" \
  "interactive bootstrap offers Deployer when appropriate"
assert_missing "${DEP_PROMPT}/deploy.php" \
  "default answer does not install Deployer"
assert_grep 'Skipping Deployer' "${LOGDIR}/boot-deployer-prompt-n.log" \
  "default N skips Deployer"

DEP_YES="${WORKDIR}/deployer-prompt-yes"
mkdir -p "${DEP_YES}"
write_laravel_composer "${DEP_YES}" 0
unset AI_BOOTSTRAP_NONINTERACTIVE
printf 'y\n' | "${AI_REPO}/scripts/bootstrap-project.sh" "${DEP_YES}" \
  >"${LOGDIR}/boot-deployer-prompt-y.log" 2>&1
export AI_BOOTSTRAP_NONINTERACTIVE=1
assert_file "${DEP_YES}/deploy.php" \
  "answering yes installs the Laravel Deployer recipe"
assert_grep 'AI_PLATFORM_DEPLOYER_STACK=laravel' "${DEP_YES}/deploy.php" \
  "yes-install uses the Laravel harness marker"
assert_grep 'Installing Deployer does not authorize deployment' \
  "${LOGDIR}/boot-deployer-prompt-y.log" \
  "yes-install reports that deployment is not authorized"

DEP_WITH="${WORKDIR}/deployer-with-flag"
mkdir -p "${DEP_WITH}"
write_laravel_composer "${DEP_WITH}" 0
"${AI_REPO}/scripts/bootstrap-project.sh" --with-deployer "${DEP_WITH}" \
  >"${LOGDIR}/boot-deployer-with.log" 2>&1
assert_file "${DEP_WITH}/deploy.php" \
  "--with-deployer installs Deployer"
assert_not_grep 'Install Deployer deployment stack' \
  "${LOGDIR}/boot-deployer-with.log" \
  "--with-deployer does not prompt"
assert_file "${DEP_WITH}/deploy/hosts.yaml.example" \
  "--with-deployer writes the hosts example"
assert_file "${DEP_WITH}/deploy/hosts.yaml" \
  "--with-deployer writes a local hosts file from the example"
assert_file "${DEP_WITH}/docs/contracts/features/deployment.md" \
  "--with-deployer writes project-local deployment notes"
assert_grep 'deployer/deployer' "${DEP_WITH}/composer.json" \
  "--with-deployer declares deployer/deployer"
assert_grep '/\.dep/' "${DEP_WITH}/.gitignore" \
  "--with-deployer gitignores .dep/"
assert_grep 'deploy/hosts\.yaml' "${DEP_WITH}/.gitignore" \
  "--with-deployer gitignores deploy/hosts.yaml"
assert_grep 'CHANGE_ME' "${DEP_WITH}/deploy/hosts.yaml" \
  "generated hosts file uses placeholders"
assert_not_grep 'password' "${DEP_WITH}/deploy.php" \
  "generated recipe contains no password"
assert_not_grep 'password' "${DEP_WITH}/deploy/hosts.yaml" \
  "generated hosts file contains no password"
assert_not_grep 'BEGIN ' "${DEP_WITH}/deploy/hosts.yaml" \
  "generated hosts file contains no key material"
assert_grep 'does not deploy' "${LOGDIR}/boot-deployer-with.log" \
  "--with-deployer reports that it does not deploy"
assert_not_grep 'vendor/bin/dep ' "${LOGDIR}/boot-deployer-with.log" \
  "--with-deployer does not execute Deployer"

DEP_WITH_TRAIL="${WORKDIR}/deployer-with-flag-trail"
mkdir -p "${DEP_WITH_TRAIL}"
write_laravel_composer "${DEP_WITH_TRAIL}" 0
"${AI_REPO}/scripts/bootstrap-project.sh" "${DEP_WITH_TRAIL}" --with-deployer \
  >"${LOGDIR}/boot-deployer-with-trail.log" 2>&1
assert_file "${DEP_WITH_TRAIL}/deploy.php" \
  "path then --with-deployer still installs"

DEP_WITHOUT="${WORKDIR}/deployer-without-flag"
mkdir -p "${DEP_WITHOUT}"
write_laravel_composer "${DEP_WITHOUT}" 0
"${AI_REPO}/scripts/bootstrap-project.sh" --without-deployer "${DEP_WITHOUT}" \
  >"${LOGDIR}/boot-deployer-without.log" 2>&1
assert_missing "${DEP_WITHOUT}/deploy.php" \
  "--without-deployer skips Deployer"
assert_not_grep 'Install Deployer deployment stack' \
  "${LOGDIR}/boot-deployer-without.log" \
  "--without-deployer does not prompt"
assert_grep 'Skipping Deployer' \
  "${LOGDIR}/boot-deployer-without.log" \
  "--without-deployer reports the skip"

printf 'UNIQUE_RECIPE_MARKER\n' >> "${DEP_WITH}/deploy.php"
"${AI_REPO}/scripts/bootstrap-project.sh" --with-deployer "${DEP_WITH}" \
  >"${LOGDIR}/boot-deployer-idempotent.log" 2>&1
assert_grep 'UNIQUE_RECIPE_MARKER' "${DEP_WITH}/deploy.php" \
  "repeated installation does not overwrite an existing harness recipe"
assert_grep 'already present' "${LOGDIR}/boot-deployer-idempotent.log" \
  "repeated installation reports the stack is already present"

if "${AI_REPO}/scripts/doctor.sh" "${DEP_WITH}" \
  >"${LOGDIR}/doctor-deployer-ok.log" 2>&1; then
  : # Boost missing will fail doctor on Laravel; Deployer lines still matter
fi
assert_grep 'Harness-managed Deployer stack is present' \
  "${LOGDIR}/doctor-deployer-ok.log" \
  "doctor recognizes a healthy harness-managed Deployer install"
assert_grep 'Deployer profile: laravel' \
  "${LOGDIR}/doctor-deployer-ok.log" \
  "doctor reports the Laravel Deployer profile"

DEP_ROOTS="${WORKDIR}/deployer-roots"
mkdir -p "${DEP_ROOTS}/web/app/themes/sage"
write_radicle_composer "${DEP_ROOTS}"
printf '{"name":"sage"}\n' > "${DEP_ROOTS}/web/app/themes/sage/package.json"
"${AI_REPO}/scripts/bootstrap-project.sh" --with-deployer "${DEP_ROOTS}" \
  >"${LOGDIR}/boot-deployer-roots.log" 2>&1
assert_grep 'AI_PLATFORM_DEPLOYER_STACK=roots' "${DEP_ROOTS}/deploy.php" \
  "Roots profile installs the roots Deployer recipe"
assert_grep 'web/app/themes/sage' "${DEP_ROOTS}/deploy.php" \
  "Roots installer detects the Sage theme path"
assert_grep 'sage:build' "${DEP_ROOTS}/deploy.php" \
  "Roots recipe includes a Sage build task"

DEP_BEDROCK="${WORKDIR}/deployer-bedrock"
mkdir -p "${DEP_BEDROCK}"
write_bedrock_composer "${DEP_BEDROCK}"
"${AI_REPO}/scripts/bootstrap-project.sh" --with-deployer "${DEP_BEDROCK}" \
  >"${LOGDIR}/boot-deployer-bedrock.log" 2>&1
assert_grep 'AI_PLATFORM_DEPLOYER_STACK=bedrock' "${DEP_BEDROCK}/deploy.php" \
  "Bedrock without Sage installs the bedrock Deployer recipe"
assert_not_grep 'sage:build' "${DEP_BEDROCK}/deploy.php" \
  "Bedrock-only recipe does not include a Sage build"

DEP_WP="${WORKDIR}/deployer-wordpress"
mkdir -p "${DEP_WP}"
write_wordpress_root "${DEP_WP}"
"${AI_REPO}/scripts/bootstrap-project.sh" --with-deployer "${DEP_WP}" \
  >"${LOGDIR}/boot-deployer-wp.log" 2>&1
assert_grep 'AI_PLATFORM_DEPLOYER_STACK=wordpress' "${DEP_WP}/deploy.php" \
  "conventional WordPress installs the wordpress Deployer recipe"
assert_grep 'recipe/wordpress.php' "${DEP_WP}/deploy.php" \
  "WordPress recipe uses Deployer's native wordpress recipe"
assert_grep 'deployer/deployer' "${DEP_WP}/composer.json" \
  "WordPress install creates a Composer require-dev for Deployer"

DEP_FOREIGN="${WORKDIR}/deployer-foreign"
mkdir -p "${DEP_FOREIGN}"
write_laravel_composer "${DEP_FOREIGN}" 0
printf '<?php\n// CUSTOM_FOREIGN_DEPLOYER\n' > "${DEP_FOREIGN}/deploy.php"
"${AI_REPO}/scripts/bootstrap-project.sh" --with-deployer "${DEP_FOREIGN}" \
  >"${LOGDIR}/boot-deployer-foreign.log" 2>&1
assert_grep 'CUSTOM_FOREIGN_DEPLOYER' "${DEP_FOREIGN}/deploy.php" \
  "existing Deployer configuration is preserved"
assert_grep 'Existing Deployer configuration detected' \
  "${LOGDIR}/boot-deployer-foreign.log" \
  "bootstrap reports an existing non-harness Deployer strategy"
assert_not_grep 'AI_PLATFORM_DEPLOYER_STACK' "${DEP_FOREIGN}/deploy.php" \
  "existing non-harness recipe is not rewritten with the harness marker"

if "${AI_REPO}/scripts/doctor.sh" "${DEP_FOREIGN}" \
  >"${LOGDIR}/doctor-deployer-foreign.log" 2>&1; then
  :
fi
assert_grep 'Existing non-harness Deployer configuration preserved' \
  "${LOGDIR}/doctor-deployer-foreign.log" \
  "doctor handles existing non-harness Deployer appropriately"

DEP_CONFLICT="${WORKDIR}/deployer-conflict"
mkdir -p "${DEP_CONFLICT}"
write_laravel_composer "${DEP_CONFLICT}" 0
printf 'hosts: {}\n' > "${DEP_CONFLICT}/deploy.yaml"
"${AI_REPO}/scripts/bootstrap-project.sh" --with-deployer "${DEP_CONFLICT}" \
  >"${LOGDIR}/boot-deployer-conflict.log" 2>&1
assert_missing "${DEP_CONFLICT}/deploy.php" \
  "conflicting deploy.yaml is not overwritten with a harness recipe"
assert_grep 'Existing Deployer configuration detected' \
  "${LOGDIR}/boot-deployer-conflict.log" \
  "conflicting deployment configuration stops the install path"

DEP_DOCS="${WORKDIR}/deployer-docs"
mkdir -p "${DEP_DOCS}/docs/contracts/features"
write_laravel_composer "${DEP_DOCS}" 0
printf 'UNIQUE_DEPLOYMENT_DOC\n' > "${DEP_DOCS}/docs/contracts/features/deployment.md"
"${AI_REPO}/scripts/install-deployer.sh" "${DEP_DOCS}" \
  >"${LOGDIR}/install-deployer-docs.log" 2>&1
assert_grep 'UNIQUE_DEPLOYMENT_DOC' \
  "${DEP_DOCS}/docs/contracts/features/deployment.md" \
  "project-owned deployment docs are preserved"
assert_grep 'already present' "${LOGDIR}/install-deployer-docs.log" \
  "standalone installer reports the existing deployment document"

DEP_STANDALONE="${WORKDIR}/deployer-standalone"
mkdir -p "${DEP_STANDALONE}"
write_laravel_composer "${DEP_STANDALONE}" 0
"${AI_REPO}/scripts/bootstrap-project.sh" --without-deployer "${DEP_STANDALONE}" \
  >"${LOGDIR}/boot-deployer-standalone-prep.log" 2>&1
"${AI_REPO}/scripts/install-deployer.sh" "${DEP_STANDALONE}" \
  >"${LOGDIR}/install-deployer-standalone.log" 2>&1
assert_file "${DEP_STANDALONE}/deploy.php" \
  "standalone installer works against a bootstrapped Laravel fixture"
assert_grep 'AI_PLATFORM_DEPLOYER_STACK=laravel' "${DEP_STANDALONE}/deploy.php" \
  "standalone installer uses the Laravel profile"
assert_grep 'does not deploy' "${LOGDIR}/install-deployer-standalone.log" \
  "standalone installer reports that it does not deploy"

if "${AI_REPO}/scripts/install-deployer.sh" "${AI_REPO}" \
  >"${LOGDIR}/install-deployer-self.log" 2>&1; then
  fail "standalone installer refuses the harness clone"
else
  pass "standalone installer refuses the harness clone"
fi

DEP_PARTIAL="${WORKDIR}/deployer-partial"
mkdir -p "${DEP_PARTIAL}"
write_laravel_composer "${DEP_PARTIAL}" 0
"${AI_REPO}/scripts/install-deployer.sh" "${DEP_PARTIAL}" \
  >"${LOGDIR}/install-deployer-partial-prep.log" 2>&1
rm -f "${DEP_PARTIAL}/deploy/hosts.yaml.example"
if "${AI_REPO}/scripts/doctor.sh" "${DEP_PARTIAL}" \
  >"${LOGDIR}/doctor-deployer-partial.log" 2>&1; then
  :
fi
assert_grep 'Harness-managed Deployer stack is incomplete' \
  "${LOGDIR}/doctor-deployer-partial.log" \
  "doctor fails a partial harness-managed Deployer install"

DEP_GENERIC_WITH="${WORKDIR}/deployer-generic-with"
mkdir -p "${DEP_GENERIC_WITH}"
printf 'hello\n' > "${DEP_GENERIC_WITH}/README.md"
"${AI_REPO}/scripts/bootstrap-project.sh" --with-deployer "${DEP_GENERIC_WITH}" \
  >"${LOGDIR}/boot-deployer-generic-with.log" 2>&1
assert_missing "${DEP_GENERIC_WITH}/deploy.php" \
  "--with-deployer on an unsupported profile does not invent a recipe"
assert_grep 'No supported Deployer profile' \
  "${LOGDIR}/boot-deployer-generic-with.log" \
  "unsupported profile is reported instead of guessed"

if "${AI_REPO}/scripts/doctor.sh" "${GENERIC}" \
  >"${LOGDIR}/doctor-generic-deployer.log" 2>&1; then
  pass "doctor on generic project without Deployer still exits 0"
else
  fail "doctor on generic project without Deployer still exits 0"
  cat "${LOGDIR}/doctor-generic-deployer.log"
fi
assert_grep 'Public submissions record present' \
  "${LOGDIR}/doctor-generic-deployer.log" \
  "doctor accepts a project public-submissions record"

echo ""
echo "--- Public submission protection ---"
SPAM_CONTRACT="${AI_REPO}/docs/contracts/features/spam-and-abuse-protection.md"
assert_file "${SPAM_CONTRACT}" \
  "spam and abuse protection contract exists"
assert_grep 'A browser widget, JavaScript check, or CSRF token alone does not count as spam protection' \
  "${SPAM_CONTRACT}" \
  "canonical contract rejects widget, JavaScript, and CSRF-only protection"
assert_grep 'Cloudflare Turnstile' "${SPAM_CONTRACT}" \
  "canonical contract recommends Turnstile when a challenge is warranted"
assert_grep 'Do not require Turnstile, WPForms' "${SPAM_CONTRACT}" \
  "canonical contract does not mandate Turnstile or WPForms"
assert_grep 'Custom HTTP APIs and other stacks' "${SPAM_CONTRACT}" \
  "canonical contract covers custom APIs"
assert_grep 'not applicable' "${SPAM_CONTRACT}" \
  "canonical contract records not applicable"
assert_grep 'must not silently retrofit' "${SPAM_CONTRACT}" \
  "canonical contract forbids silent adoption retrofit"
assert_grep '36-wordpress-theme.mdc' "${SPAM_CONTRACT}" \
  "canonical contract keeps theme.json out of submission protection"
for spam_pointer in \
  "${AI_REPO}/.cursor/rules/00-platform.mdc" \
  "${AI_REPO}/.cursor/rules/20-coding.mdc" \
  "${AI_REPO}/.cursor/rules/30-laravel.mdc" \
  "${AI_REPO}/.cursor/rules/35-roots.mdc" \
  "${AI_REPO}/.cursor/rules/50-workflows.mdc" \
  "${AI_REPO}/core/agent-core.md" \
  "${AI_REPO}/core/project-profiles/laravel-webapp.md" \
  "${AI_REPO}/core/project-profiles/roots-radicle.md" \
  "${AI_REPO}/core/prompts/project-adoption.md"
do
  assert_grep 'docs/contracts/features/spam-and-abuse-protection.md' \
    "${spam_pointer}" \
    "$(basename "${spam_pointer}") points at the spam contract"
  assert_not_grep 'Turnstile' "${spam_pointer}" \
    "$(basename "${spam_pointer}") does not restate the Turnstile recommendation"
done
assert_not_grep 'Turnstile' "${AI_REPO}/.cursor/rules/36-wordpress-theme.mdc" \
  "wordpress theme rule does not define a challenge vendor"
assert_not_grep 'spam-and-abuse-protection' \
  "${AI_REPO}/.cursor/rules/36-wordpress-theme.mdc" \
  "wordpress theme rule does not own submission protection"
assert_grep 'not applicable' "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption records not applicable"
assert_grep 'Do not install or enable protection' \
  "${AI_REPO}/core/prompts/project-adoption.md" \
  "adoption does not install protection during inspection"
assert_not_grep 'Turnstile' "${AI_REPO}/scripts/bootstrap-project.sh" \
  "bootstrap script does not mention Turnstile"

rm -f "${GENERIC}/docs/contracts/features/public-submissions.md"
if "${AI_REPO}/scripts/doctor.sh" "${GENERIC}" \
  >"${LOGDIR}/doctor-missing-public-submissions.log" 2>&1; then
  pass "doctor warns instead of failing when the public-submissions record is missing"
else
  fail "doctor warns instead of failing when the public-submissions record is missing"
  cat "${LOGDIR}/doctor-missing-public-submissions.log"
fi
assert_grep 'Public submissions record missing' \
  "${LOGDIR}/doctor-missing-public-submissions.log" \
  "doctor warns when the public-submissions record is missing"

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
assert_dir "${AI_REPO}/.build/chatgpt-context/.agents/skills/impeccable" \
  "export includes Impeccable"
assert_grep '^Version 1\.3\.0$' \
  "${AI_REPO}/.build/chatgpt-context/docs/00-project-context.md" \
  "export project context is v1.3.0"
assert_file "${AI_REPO}/.build/chatgpt-context/CHANGELOG.md" \
  "export includes changelog"
assert_file "${AI_REPO}/.build/chatgpt-context/README.md" \
  "export includes README"
assert_grep '^Version 1\.3\.0$' \
  "${AI_REPO}/.build/chatgpt-context/README.md" \
  "export README is v1.3.0"
assert_file "${AI_REPO}/.build/chatgpt-context/docs/contracts/features/deployer.md" \
  "export includes the Deployer contract"
assert_file "${AI_REPO}/.build/chatgpt-context/docs/contracts/features/spam-and-abuse-protection.md" \
  "export includes the spam and abuse protection contract"
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
