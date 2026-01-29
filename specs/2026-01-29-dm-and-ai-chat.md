# Pulsync DM and AI Chat Implementation

**Date:** 2026-01-29
**Status:** Implemented

## Summary

This spec covers the implementation of two major features for Pulsync:
1. Direct Messaging (DMs) - Private 1:1 and group conversations
2. AI Agent Chat - Claude-powered assistant with streaming responses

## Files Created/Modified

### Backend (services/api/)

#### New Models
- `app/models/conversation.py` - Conversation and ConversationParticipant models
- `app/models/message.py` - Message model for DM conversations
- `app/models/ai_chat.py` - AIChatSession and AIChatMessage models

#### New Schemas
- `app/schemas/message.py` - Pydantic schemas for DM feature
- `app/schemas/ai_chat.py` - Pydantic schemas for AI Chat feature

#### New Routers
- `app/routers/messages.py` - DM API endpoints
- `app/routers/ai_chat.py` - AI Chat API endpoints with SSE streaming

#### New Services
- `app/services/ai_service.py` - Anthropic Claude integration with streaming

#### Modified Files
- `app/config.py` - Added Anthropic configuration settings
- `app/main.py` - Registered new routers
- `pyproject.toml` - Added anthropic dependency

### Frontend (apps/macos-client/)

#### New Models
- `Sources/Models/Message.swift` - Message, Conversation, ConversationParticipant
- `Sources/Models/AIChat.swift` - AIChatSession, AIChatMessage, SSE event parsing

#### New Services
- `Sources/Services/SSEClient.swift` - Server-Sent Events client for streaming

#### Modified Services
- `Sources/Services/APIClient.swift` - Added DM and AI Chat API methods

#### New Views - Messages
- `Sources/Views/Messages/InboxView.swift` - Main inbox with NavigationSplitView
- `Sources/Views/Messages/ConversationListView.swift` - Sidebar conversation list
- `Sources/Views/Messages/ChatView.swift` - Message thread view
- `Sources/Views/Messages/MessageBubble.swift` - Individual message display
- `Sources/Views/Messages/MessageInputView.swift` - Text input with send button
- `Sources/Views/Messages/NewConversationSheet.swift` - User search to start DM

#### New Views - AI Chat
- `Sources/Views/AIChat/AIChatView.swift` - Main AI chat with session list
- `Sources/Views/AIChat/AIChatSessionList.swift` - Past conversations sidebar
- `Sources/Views/AIChat/AIChatConversationView.swift` - Active chat with streaming
- `Sources/Views/AIChat/AIChatBubble.swift` - Message bubble with markdown
- `Sources/Views/AIChat/AIChatInputView.swift` - Multi-line input with send/stop
- `Sources/Views/AIChat/AIChatWelcomeView.swift` - Empty state with suggestions
- `Sources/Views/AIChat/MarkdownView.swift` - Markdown rendering with code blocks
- `Sources/Views/AIChat/TypingIndicator.swift` - Animated typing dots

## API Endpoints

### Direct Messaging
| Method | Path | Description |
|--------|------|-------------|
| GET | `/messages/conversations` | List user's conversations |
| POST | `/messages/conversations` | Create conversation |
| GET | `/messages/conversations/{id}` | Get conversation with messages |
| DELETE | `/messages/conversations/{id}` | Leave conversation |
| GET | `/messages/conversations/{id}/messages` | Get messages (paginated) |
| POST | `/messages/conversations/{id}/messages` | Send message |
| GET | `/messages/users/search?q=` | Search users for new DM |

### AI Chat
| Method | Path | Description |
|--------|------|-------------|
| GET | `/ai-chat/sessions` | List user's chat sessions |
| POST | `/ai-chat/sessions` | Create new session |
| GET | `/ai-chat/sessions/{id}` | Get session with messages |
| DELETE | `/ai-chat/sessions/{id}` | Delete session |
| POST | `/ai-chat/sessions/{id}/messages` | Send message, stream response (SSE) |

## Configuration

Add to `.env`:
```
ANTHROPIC_API_KEY=your-api-key-here
```

## Testing

### Direct Messaging
1. Create two test users
2. Start conversation from one user
3. Send messages back and forth
4. Verify real-time updates
5. Check unread counts

### AI Chat
1. Add `ANTHROPIC_API_KEY` to `.env`
2. Create new AI session
3. Send message, verify streaming response
4. Check markdown rendering
5. Test stop button mid-stream
6. Verify session persistence

## Future Enhancements (Placeholder)

- Dictation (speech-to-text)
- Text-to-Speech
- App Integrations (Calendar, Slack, Teams)
- @Mentions & Notifications
- Kudos & Recognition
- Advanced Search
