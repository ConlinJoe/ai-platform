# Documentation Index

This file is the dependency graph and contract registry for the
AI Development Harness repository (`ai-platform`).

## Overview

The AI Platform repository documents its own standards under `docs/`. Individual
development projects maintain their own `docs/` directory using the same
contract model and templates from `templates/docs/`.

## Contract Registry

| Contract | Type | Status | Source of Truth For |
| --- | --- | --- | --- |
| `00-project-context.md` | foundational | active | Harness summary for ChatGPT and agents |
| `working-mode.md` | continuation | active | Current working mode and agent continuation |
| `99-project-status.md` | status | active | Implementation status and validation |
| `documentation-philosophy.md` | foundational | active | Documentation contract standard |
| `chatgpt-projects.md` | foundational | active | ChatGPT Projects export workflow |
| `contracts/adrs/0001-two-layer-browser-qa.md` | adr | accepted | Decision to use Mode A/B browser QA |
| `contracts/adrs/0002-laravel-boost-ownership.md` | adr | accepted | Decision that Boost is project-native |
| `contracts/adrs/0003-work-item-lifecycle.md` | adr | accepted | Decision to use a provider-neutral work-item lifecycle with GitHub as reference |
| `contracts/adrs/0004-design-stack-and-ui-visual-verification.md` | adr | accepted | Decision that Hallmark is the only managed design skill and significant UI authorizes bounded Mode B visual verification |
| `contracts/adrs/0005-agent-continuation-and-concise-reporting.md` | adr | accepted | Decision to store agent continuation in working-mode.md and default to concise completion reporting |
| `contracts/features/browser-qa.md` | feature | active | Browser QA policy, invocation, capability-aware visual verification, Playwright vs interactive distinction, applicability, isolation |
| `contracts/features/laravel-boost.md` | feature | active | Boost capability, detection, bootstrap/doctor |
| `contracts/features/work-item-lifecycle.md` | feature | active | Capture-don't-expand, Issues/PRs, approval boundaries, optional gh |

## Dependency Graph

```mermaid
flowchart TD
  context[00-project-context.md]
  workingMode[working-mode.md]
  status[99-project-status.md]
  philosophy[documentation-philosophy.md]
  chatgpt[chatgpt-projects.md]
  browserAdr[contracts/adrs/0001-two-layer-browser-qa.md]
  boostAdr[contracts/adrs/0002-laravel-boost-ownership.md]
  workAdr[contracts/adrs/0003-work-item-lifecycle.md]
  designAdr[contracts/adrs/0004-design-stack-and-ui-visual-verification.md]
  continuationAdr[contracts/adrs/0005-agent-continuation-and-concise-reporting.md]
  browserQa[contracts/features/browser-qa.md]
  boost[contracts/features/laravel-boost.md]
  workItems[contracts/features/work-item-lifecycle.md]

  chatgpt --> philosophy
  chatgpt --> context
  philosophy --> context
  workingMode --> context
  workingMode --> status
  status --> context
  continuationAdr --> philosophy
  browserAdr --> browserQa
  boostAdr --> boost
  workAdr --> workItems
  designAdr --> browserQa
  browserQa --> browserAdr
  boost --> boostAdr
  workItems --> workAdr
```

## Loading Guide

| Task type | Start with |
| --- | --- |
| ChatGPT / platform overview | `00-project-context.md` |
| Fresh agent / resume | `working-mode.md`, `../core/prompts/resume.md` |
| Documentation standard | `documentation-philosophy.md` |
| ChatGPT export setup | `chatgpt-projects.md` |
| First-time clone / onboarding | `../README.md`, `mcp/README.md` |
| UI / design preferences | `.cursor/rules/40-ui.mdc`, `contracts/adrs/0004-design-stack-and-ui-visual-verification.md` |
| Multi-agent adapters | `core/adapters/README.md` |
| New or existing project bootstrap | `scripts/bootstrap-project.sh`, `.cursor/rules/50-workflows.mdc` |
| Existing project adoption | `core/prompts/project-adoption.md` |
| Browser QA / Playwright | `contracts/features/browser-qa.md` |
| Laravel Boost / MCP | `contracts/features/laravel-boost.md`, `mcp/README.md` |
| Issues, PRs, discovered work | `contracts/features/work-item-lifecycle.md` |
| Laravel web app profile | `core/project-profiles/laravel-webapp.md` |
| Roots/Radicle/Sage profile | `core/project-profiles/roots-radicle.md` |

## ChatGPT Export

```bash
scripts/export-chatgpt-context.sh
```

Produces `.build/chatgpt-context.zip` with documentation, Cursor rules, agent
skills, `AGENTS.md` / `CLAUDE.md`, and project AI metadata.
