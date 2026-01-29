from collections.abc import AsyncGenerator

import anthropic

from app.config import settings

PULSYNC_SYSTEM_PROMPT = """You are a helpful AI assistant for Pulsync, an internal company communication platform.

Your role is to help employees with:
- Understanding company policies and procedures
- Drafting professional communications (emails, announcements, messages)
- Answering questions about how to use the Pulsync platform
- General workplace productivity assistance
- Summarizing and organizing information

Guidelines:
- Be professional, friendly, and concise
- If you don't know something specific to the company, say so and suggest who might help
- Respect confidentiality and don't make up company-specific information
- Format responses clearly with markdown when helpful
- Keep responses focused and actionable"""


async def stream_ai_response(messages: list[dict]) -> AsyncGenerator[str, None]:
    """
    Stream responses from Claude API with Pulsync system prompt.

    Args:
        messages: List of message dicts with 'role' and 'content' keys

    Yields:
        Text chunks from the streaming response
    """
    if not settings.anthropic_api_key:
        yield "Error: Anthropic API key is not configured. Please add ANTHROPIC_API_KEY to your environment."
        return

    client = anthropic.Anthropic(api_key=settings.anthropic_api_key)

    try:
        with client.messages.stream(
            model=settings.anthropic_model,
            max_tokens=settings.anthropic_max_tokens,
            system=PULSYNC_SYSTEM_PROMPT,
            messages=messages,
        ) as stream:
            for text in stream.text_stream:
                yield text
    except anthropic.APIError as e:
        yield f"\n\nError communicating with AI service: {str(e)}"
    except Exception as e:
        yield f"\n\nUnexpected error: {str(e)}"


def generate_session_title(first_message: str) -> str:
    """Generate a short title from the first message."""
    # Take first 50 chars, cut at last space if possible
    title = first_message[:50]
    if len(first_message) > 50:
        last_space = title.rfind(" ")
        if last_space > 20:
            title = title[:last_space]
        title += "..."
    return title
