# Pulsync Vision

## What is Pulsync?
Internal company communications platform with a TikTok-style immersive experience.
Think Slack/Teams reimagined as a social media feed - making company updates
engaging rather than another inbox to check.

## The Four Pillars

### Home - Your Personal Feed
- Algorithm-curated content relevant to you
- Content from people/topics you follow
- TikTok-style vertical scroll, full-screen cards
- Like, comment, bookmark, share interactions

### Discover - What's Happening
- Trending content within the company
- Popular announcements and updates
- External relevant news/content
- Search and explore

### Define - Your Daily Briefing
- Personal outcome-focused todo list
- What you need to accomplish TODAY
- Meeting briefings and prep
- Focus on OUTCOMES not just tasks
- Shows what needs to be done AND how

### Deliver - Weekly Accomplishments
- Synthesis of projects you're involved in
- Projects you follow, work on, or stakeholder in (RACI)
- Focus on what was ACCOMPLISHED each week
- Weekly retrospective view

## Design Philosophy
- Immersive, full-screen content consumption
- No chrome during viewing (TikTok-style)
- Floating action buttons with blur effects
- Bottom navigation, dark theme
- Engagement-first: make work content as engaging as social media

## Technical Architecture
- macOS SwiftUI client (future: iOS, web)
- FastAPI Python backend
- PostgreSQL database
- RESTful API with cursor-based pagination

## Quality Standards
- Every feature starts with a spec in /specs
- TDD where applicable
- Plan-mode first for non-trivial changes
- Code review before merge
