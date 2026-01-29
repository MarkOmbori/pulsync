# QA Testing Infrastructure

Automated QA testing for the Pulsync platform.

## Directory Structure

```
qa/
├── scenarios/    # YAML test scenario definitions
├── issues/       # Issue reports from failed tests
├── reports/      # Test run reports
└── README.md     # This file
```

## Running Tests

### Via pytest (Recommended)
```bash
cd services/api
uv run pytest tests/e2e/ -v
```

### Run specific test suite
```bash
cd services/api
uv run pytest tests/e2e/test_user_journey_auth.py -v
uv run pytest tests/e2e/test_user_journey_feed.py -v
uv run pytest tests/e2e/test_user_journey_messaging.py -v
uv run pytest tests/e2e/test_user_journey_ai_chat.py -v
```

## QA Agents

### qa-orchestrator
Coordinates test cycles, analyzes results, and hands off issues.

```bash
# Invoke via Claude Code
/qa-orchestrator
```

### qa-runner
Executes test scenarios.

```bash
# Invoke via Claude Code
/qa-runner
```

### qa-monitor
Monitors backend health during test runs.

```bash
# Invoke via Claude Code
/qa-monitor
```

## Health Endpoints

```bash
# Basic health
curl http://localhost:8000/health

# Detailed health with metrics
curl http://localhost:8000/qa/health-detailed

# Recent logs
curl "http://localhost:8000/qa/logs?limit=50"

# Error logs only
curl "http://localhost:8000/qa/logs?level=error"
```

## Issue Report Format

Issue reports are created in `qa/issues/` with the following format:

```markdown
# Issue: {Test Name}

## Severity
Critical | High | Medium

## Failed Test
`{test_file}::{test_name}`

## Error
{error message}

## Logs
{relevant logs}

## Suggested Fix
{analysis}

## Handoff
- Agent: debugger → python-coder / swift-coder
- Status: Open | In Progress | Fixed | Verified
```

## Severity Levels

| Level | Criteria |
|-------|----------|
| Critical | HTTP 5xx, client crashes, data corruption |
| High | HTTP 401 (auth failure), data not persisting |
| Medium | Slow responses (>2s), minor UI issues |
