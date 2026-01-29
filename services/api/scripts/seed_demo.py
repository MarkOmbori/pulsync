#!/usr/bin/env python
"""
Standalone script to seed demo content into Pulsync.

Run with: uv run python scripts/seed_demo.py

Options:
  --clear    Remove all demo content before seeding
  --list     List all demo videos (don't seed)
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.db import Base, engine, get_db
from app.seed_demo_content import (
    DEMO_VIDEOS,
    clear_demo_content,
    seed_demo_content,
    seed_demo_users,
)


def main():
    # Create tables if they don't exist
    Base.metadata.create_all(bind=engine)

    db = next(get_db())

    if "--clear" in sys.argv:
        print("Clearing demo content...")
        clear_demo_content(db)
        print("Done!")
        return

    if "--list" in sys.argv:
        print("\n=== Demo Videos ===\n")
        for i, video in enumerate(DEMO_VIDEOS, 1):
            print(f"{i}. {video['title']}")
            print(f"   Duration: {video['duration_seconds']}s")
            print(f"   Tags: {', '.join(video['tags'])}")
            print(f"   URL: {video['media_url'][:60]}...")
            print()
        return

    print("Seeding demo content...")
    print("=" * 50)

    # First ensure tags exist (run main app seed first if needed)
    from app.models.tag import Tag

    if db.query(Tag).count() == 0:
        print("Error: Tags not found. Please run the API first to seed tags.")
        print("Run: uv run fastapi dev")
        return

    seed_demo_content(db)
    db.close()

    print("=" * 50)
    print("Demo content seeded successfully!")
    print("\nView the content at: http://localhost:8000/content")
    print("API docs at: http://localhost:8000/docs")


if __name__ == "__main__":
    main()
