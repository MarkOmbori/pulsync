# Hackathon Workspace

Multi-repo workspace for Ombori hackathon.

## Key Rules

1. **Plan-mode-first**: ALL features start with spec creation in `specs/` folder
2. **TDD where applicable**: Write tests before implementation
3. **Specs in workspace**: All specs centralized in `specs/` folder
4. **Evolve the config**: Update CLAUDE.md and agents with learnings as you build

## Continuous Improvement

As you build, update these files with learnings:
- `CLAUDE.md` - Add new patterns, gotchas, project-specific conventions
- `.claude/agents/*.md` - Refine agent instructions based on what works
- `apps/macos-client/CLAUDE.md` - Swift-specific learnings
- `services/api/CLAUDE.md` - Python/FastAPI-specific learnings

Examples of things to capture:
- "Always use X pattern for Y"
- "Don't forget to run Z after changing W"
- "API endpoint naming follows this convention..."
- "Database migrations require this step..."

## Quick Start

```bash
# Start database
docker compose up -d

# Run API (in new terminal)
cd services/api && uv run fastapi dev

# Run Swift client (in new terminal)
cd apps/macos-client && swift run PulsyncClient
```

## Structure
- `apps/macos-client/` - SwiftUI desktop app (submodule)
- `services/api/` - FastAPI Python backend (submodule)
- `specs/` - Feature specifications (plan-mode output)
- `docker-compose.yml` - PostgreSQL database

## Skills (Commands)
Available in `.claude/skills/`:
- `/feature` - **Start here!** Asks questions → creates spec → TDD implementation

## Agents
Available in `.claude/agents/`:
- `/architect` - System design, API contracts → outputs to `specs/`
- `/swift-coder` - Swift client development
- `/python-coder` - FastAPI backend development
- `/reviewer` - Code review across all repos
- `/debugger` - Issue investigation
- `/tester` - Test-driven development
- `/qa-orchestrator` - Coordinates E2E testing cycles, analyzes results, hands off issues
- `/qa-runner` - Executes E2E test scenarios
- `/qa-monitor` - Monitors backend health during tests

## Development Workflow

### New Features (MANDATORY)
1. **Plan mode first** - Create spec in `specs/YYYY-MM-DD-feature-name.md`
2. **Write tests** - TDD: tests before implementation
3. **Implement** - Use coder agents (can run in parallel)
4. **Review** - Use reviewer agent
5. **Commit** - Submodules first, then workspace

### Git Workflow (use `gh` CLI, not GitHub web)
Always use feature branches and `gh pr create`:
```bash
# In each submodule
git checkout -b feature/<name>
git add . && git commit -m "feat: ..."
git push -u origin feature/<name>
gh pr create --title "feat: ..." --body "Description"

# After PRs merged, update workspace
cd ../..
git add . && git commit -m "Update submodules"
git push
```

## API Reference
- Swagger: http://localhost:8000/docs
- Health: http://localhost:8000/health
- Items: http://localhost:8000/items (from database)

## QA Testing

### Running E2E Tests
```bash
# Run all E2E tests
cd services/api && uv run pytest tests/e2e/ -v

# Run specific test suite
cd services/api && uv run pytest tests/e2e/test_user_journey_auth.py -v
cd services/api && uv run pytest tests/e2e/test_user_journey_feed.py -v
cd services/api && uv run pytest tests/e2e/test_user_journey_messaging.py -v
cd services/api && uv run pytest tests/e2e/test_user_journey_ai_chat.py -v
```

### QA Health Endpoints
```bash
# Basic health
curl http://localhost:8000/health

# Detailed health with metrics
curl http://localhost:8000/qa/health-detailed

# Recent logs (filterable)
curl "http://localhost:8000/qa/logs?limit=50"
curl "http://localhost:8000/qa/logs?level=error"
```

### QA Infrastructure
- `qa/scenarios/` - YAML test scenario definitions
- `qa/issues/` - Issue reports from failed tests
- `qa/reports/` - Test run reports

### QA Workflow
1. **Pre-flight**: Check backend health via `/qa/health-detailed`
2. **Run tests**: Execute E2E tests via pytest
3. **Analyze**: Review failures and logs
4. **Handoff**: Create issue report, hand off to debugger/coder agents
5. **Verify**: Re-run failed tests after fixes (max 3 retries)
