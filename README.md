# Pulsync

Internal company communications platform with a TikTok-style immersive experience. Think Slack/Teams reimagined as a social media feed - making company updates engaging rather than another inbox to check.

## The Four Pillars

| Pillar | Description |
|--------|-------------|
| **Home** | Algorithm-curated personal feed with TikTok-style vertical scroll |
| **Discover** | Trending content, popular announcements, and company-wide search |
| **Define** | Outcome-focused daily briefing with meeting prep |
| **Deliver** | Weekly accomplishments and project synthesis |

## Features

- **Content Feed** - Full-screen immersive cards with like, comment, bookmark interactions
- **Direct Messaging** - Private 1:1 and group conversations
- **AI Chat** - Claude-powered assistant with streaming responses
- **Role-based Content** - Target content to specific roles/departments

## Tech Stack

- **Client:** SwiftUI macOS app
- **Backend:** FastAPI (Python)
- **Database:** PostgreSQL
- **AI:** Anthropic Claude API

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Python 3.12+ with [uv](https://docs.astral.sh/uv/)
- Xcode 15+ (for macOS client)

### Setup

```bash
# Clone the repository
git clone https://github.com/MarkOmbori/pulsync.git
cd pulsync

# Start database
docker compose up -d

# Run API (in new terminal)
cd services/api
cp .env.example .env  # Add your ANTHROPIC_API_KEY
uv sync
uv run fastapi dev

# Run Swift client (in new terminal)
cd apps/macos-client
swift run PulsyncClient
```

## Project Structure

```
pulsync/
├── apps/
│   └── macos-client/       # SwiftUI desktop app
│       └── Sources/
│           ├── Models/     # Data models
│           ├── Views/      # SwiftUI views
│           └── Services/   # API client, SSE client
├── services/
│   └── api/                # FastAPI backend
│       └── app/
│           ├── models/     # SQLAlchemy ORM models
│           ├── schemas/    # Pydantic schemas
│           ├── routers/    # API endpoints
│           └── services/   # Business logic
├── specs/                  # Feature specifications
└── docker-compose.yml      # PostgreSQL database
```

## API Reference

Once running, access the API documentation at:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### Key Endpoints

| Category | Endpoint | Description |
|----------|----------|-------------|
| Auth | `POST /auth/login` | User authentication |
| Feed | `GET /feed` | Personalized content feed |
| Content | `POST /content` | Create new content |
| Messages | `GET /messages/conversations` | List DM conversations |
| AI Chat | `POST /ai-chat/sessions/{id}/messages` | Send message with SSE streaming |

## Configuration

Create a `.env` file in `services/api/`:

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/hackathon
ANTHROPIC_API_KEY=your-api-key-here
```

## Development

This project uses a plan-mode-first approach:

1. Create spec in `specs/YYYY-MM-DD-feature-name.md`
2. Write tests (TDD)
3. Implement feature
4. Code review
5. Commit

## License

Private - Ombori Hackathon 2026
