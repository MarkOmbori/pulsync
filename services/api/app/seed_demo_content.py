"""
Demo content seed data for Pulsync.

Contains 20 short video posts with royalty-free videos from Pexels,
along with realistic corporate titles, descriptions, and text transcripts.

All videos are from Pexels.com under Creative Commons Zero (CC0) license.
"""

import random
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.models.content import Content, ContentType, SharingPolicy
from app.models.tag import Tag
from app.models.user import User, UserRole

# Demo users representing different departments
DEMO_USERS = [
    {
        "email": "sarah.chen@pulsync.io",
        "display_name": "Sarah Chen",
        "role": UserRole.COMMS.value,
        "department": "Communications",
        "is_comms_team": True,
        "avatar_url": "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=150",
    },
    {
        "email": "marcus.johnson@pulsync.io",
        "display_name": "Marcus Johnson",
        "role": UserRole.ENGINEERING.value,
        "department": "Engineering",
        "is_comms_team": False,
        "avatar_url": "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=150",
    },
    {
        "email": "emily.rodriguez@pulsync.io",
        "display_name": "Emily Rodriguez",
        "role": UserRole.HR.value,
        "department": "Human Resources",
        "is_comms_team": False,
        "avatar_url": "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=150",
    },
    {
        "email": "david.kim@pulsync.io",
        "display_name": "David Kim",
        "role": UserRole.MARKETING.value,
        "department": "Marketing",
        "is_comms_team": False,
        "avatar_url": "https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=150",
    },
    {
        "email": "lisa.thompson@pulsync.io",
        "display_name": "Lisa Thompson",
        "role": UserRole.EXECUTIVE.value,
        "department": "Executive",
        "is_comms_team": False,
        "avatar_url": "https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=150",
    },
]

# 20 demo video posts with Pexels royalty-free videos
# All videos are CC0 licensed from pexels.com
DEMO_VIDEOS = [
    # Company News & Announcements (4 videos)
    {
        "title": "Q1 2025 All-Hands Highlights",
        "body": "Key moments from our quarterly all-hands meeting. Watch CEO Lisa share our achievements and roadmap for the coming quarter.",
        "transcript": """Welcome everyone to our Q1 all-hands! I'm thrilled to share that we've exceeded our targets by 15%.
Our customer satisfaction scores are at an all-time high. The product team shipped 12 major features.
Engineering reduced our deployment time by 40%. Looking ahead, we're investing heavily in AI capabilities.
Thank you all for your incredible work. Let's make Q2 even better!""",
        "media_url": "https://videos.pexels.com/video-files/3129671/3129671-uhd_2560_1440_30fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/3129671/free-video-3129671.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 28,
        "tags": ["company-news", "events"],
        "is_company_important": True,
        "author_role": "executive",
    },
    {
        "title": "New Office Tour - San Francisco",
        "body": "Take a virtual tour of our newly renovated SF headquarters! Modern spaces designed for collaboration and creativity.",
        "transcript": """Welcome to our brand new San Francisco office! We've completely redesigned the space.
Here's the open collaboration area with standing desks and pods. The kitchen has been upgraded with a coffee bar.
Check out our new quiet rooms for focused work. And here's the rooftop terrace for team events.
We can't wait to see you all here!""",
        "media_url": "https://videos.pexels.com/video-files/7534234/7534234-uhd_2732_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/7534234/pexels-photo-7534234.jpeg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 25,
        "tags": ["company-news", "culture"],
        "is_company_important": True,
        "author_role": "comms",
    },
    {
        "title": "Welcome Our New VP of Engineering",
        "body": "Please join us in welcoming James Park as our new VP of Engineering! Learn about his background and vision.",
        "transcript": """Hi everyone, I'm James Park, your new VP of Engineering. I'm excited to be here!
I come from a background in distributed systems and have led teams at several tech companies.
My focus will be on developer experience and shipping faster while maintaining quality.
Looking forward to meeting each of you. My door is always open!""",
        "media_url": "https://videos.pexels.com/video-files/4427612/4427612-uhd_2560_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/4427612/free-video-4427612.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 22,
        "tags": ["company-news", "engineering"],
        "is_company_important": True,
        "author_role": "hr",
    },
    {
        "title": "Sustainability Initiative Launch",
        "body": "We're proud to announce our carbon-neutral commitment. Learn about our new green initiatives.",
        "transcript": """Today we're launching our sustainability program. By 2026, we aim to be carbon neutral.
We're switching to renewable energy in all offices. Remote work has already reduced our footprint by 30%.
We're also introducing electric vehicle benefits and bike-to-work incentives.
Together, we can make a difference. Sign up for the green team in the portal!""",
        "media_url": "https://videos.pexels.com/video-files/3571264/3571264-uhd_2560_1440_30fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/3571264/free-video-3571264.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 26,
        "tags": ["company-news", "culture"],
        "is_company_important": True,
        "author_role": "comms",
    },
    # Tech Talks & Engineering (4 videos)
    {
        "title": "Microservices Migration Update",
        "body": "Quick update on our monolith-to-microservices journey. See our progress and what's coming next.",
        "transcript": """Hey team, quick update on our microservices migration. We've now split out 8 core services.
Latency has improved by 40% on the checkout flow. Deployments are now independent per service.
Next up: we're tackling the user service. Expect some brief maintenance windows.
Check the wiki for the full architecture docs. Questions? Drop by the engineering channel!""",
        "media_url": "https://videos.pexels.com/video-files/5483077/5483077-uhd_2560_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/5483077/free-video-5483077.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 24,
        "tags": ["tech-talks", "engineering"],
        "is_company_important": False,
        "author_role": "engineering",
    },
    {
        "title": "AI Feature Demo - Smart Search",
        "body": "Check out our new AI-powered search feature! Natural language queries are now possible.",
        "transcript": """Excited to demo our new smart search feature! Watch this.
Instead of keywords, just type naturally: 'Show me sales from last quarter in Europe.'
The AI understands context and intent. It even suggests related queries.
This ships next week. Try it in staging now and give us feedback!""",
        "media_url": "https://videos.pexels.com/video-files/8720757/8720757-uhd_2560_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/8720757/pexels-photo-8720757.jpeg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 20,
        "tags": ["tech-talks", "product"],
        "is_company_important": False,
        "author_role": "engineering",
    },
    {
        "title": "Security Best Practices Reminder",
        "body": "A quick refresher on security practices. Protect yourself and our customers.",
        "transcript": """Quick security reminder from the infosec team. Phishing attempts are increasing.
Always check the sender's email carefully. Never share credentials, even with IT.
Use your password manager and enable 2FA everywhere. Report suspicious emails immediately.
Stay vigilant! Security is everyone's responsibility.""",
        "media_url": "https://videos.pexels.com/video-files/5473093/5473093-uhd_2560_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/5473093/free-video-5473093.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 23,
        "tags": ["tech-talks", "learning"],
        "is_company_important": True,
        "author_role": "engineering",
    },
    {
        "title": "New CI/CD Pipeline Overview",
        "body": "We've revamped our deployment pipeline! Faster builds, better testing, easier rollbacks.",
        "transcript": """Big news for developers! Our new CI/CD pipeline is live.
Build times are down from 20 minutes to 5 minutes. We've added automatic rollbacks.
Feature flags are now built-in. Preview environments spin up for every PR.
Check the engineering blog for the full deep-dive. Happy deploying!""",
        "media_url": "https://videos.pexels.com/video-files/6963744/6963744-uhd_2732_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/6963744/pexels-photo-6963744.jpeg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 21,
        "tags": ["tech-talks", "engineering"],
        "is_company_important": False,
        "author_role": "engineering",
    },
    # Culture & Team (4 videos)
    {
        "title": "Team Building Day Recap",
        "body": "Highlights from our amazing team building day at the park. Great weather, great team!",
        "transcript": """What an incredible team building day! Perfect weather and even better company.
We had over 200 people join us for games, food, and fun. The tug-of-war was legendary.
The engineering vs marketing volleyball match ended in a tie. Sure it did.
Thanks to everyone who came. Can't wait for the next one!""",
        "media_url": "https://videos.pexels.com/video-files/3252127/3252127-uhd_2560_1440_30fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/3252127/free-video-3252127.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 25,
        "tags": ["culture", "events"],
        "is_company_important": False,
        "author_role": "hr",
    },
    {
        "title": "Employee Spotlight: Maria's Journey",
        "body": "Meet Maria from our Support team! Learn about her path from intern to team lead.",
        "transcript": """Hi, I'm Maria! I started here as a support intern three years ago.
The mentorship program changed everything for me. My manager believed in my potential.
Now I lead a team of 8 and I've never been happier. The culture here is truly special.
If you're thinking about your career path, reach out! I love helping others grow.""",
        "media_url": "https://videos.pexels.com/video-files/4427545/4427545-uhd_2560_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/4427545/free-video-4427545.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 27,
        "tags": ["culture", "hr"],
        "is_company_important": False,
        "author_role": "hr",
    },
    {
        "title": "Diversity Month Celebration",
        "body": "Celebrating our diverse team during Diversity Month. Unity in our differences.",
        "transcript": """This month we celebrate what makes us unique. Our team spans 42 countries and speaks 28 languages.
Diversity isn't just a goal, it's our strength. Different perspectives drive innovation.
Join our ERG events throughout the month. The cultural food fair is next Friday!
Together, we're building a more inclusive workplace.""",
        "media_url": "https://videos.pexels.com/video-files/3252118/3252118-uhd_2560_1440_30fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/3252118/free-video-3252118.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 24,
        "tags": ["culture", "events"],
        "is_company_important": True,
        "author_role": "hr",
    },
    {
        "title": "Work From Anywhere Policy Update",
        "body": "Exciting news about our flexible work policy! More freedom, same great collaboration.",
        "transcript": """Big update on our remote work policy! We're now officially work-from-anywhere.
You can work from any location for up to 8 weeks per year. International hubs are opening.
Core collaboration hours remain 10am-2pm local time. The rest is up to you!
Check the HR portal for the full policy details. Questions? Ask me in the thread!""",
        "media_url": "https://videos.pexels.com/video-files/4065388/4065388-uhd_2560_1440_30fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/4065388/free-video-4065388.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 26,
        "tags": ["culture", "hr"],
        "is_company_important": True,
        "author_role": "hr",
    },
    # Learning & Development (4 videos)
    {
        "title": "Quick Tip: Keyboard Shortcuts",
        "body": "Boost your productivity with these essential keyboard shortcuts for our tools.",
        "transcript": """Want to work faster? Here are shortcuts you need to know.
Command-K opens quick search anywhere in the app. Shift-Enter sends without leaving the input.
G then I takes you to inbox. G then P to projects. These work everywhere!
Try them out and let me know your favorites in the comments!""",
        "media_url": "https://videos.pexels.com/video-files/5483071/5483071-uhd_2560_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/5483071/free-video-5483071.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 22,
        "tags": ["learning", "product"],
        "is_company_important": False,
        "author_role": "engineering",
    },
    {
        "title": "Leadership Course Announcement",
        "body": "New leadership development program launching! Grow your management skills.",
        "transcript": """Announcing our new leadership development program! Applications open today.
It's an 8-week cohort-based course covering communication, feedback, and team building.
You'll get a mentor and join a peer group. Previous participants rated it 4.9 out of 5.
Space is limited to 20 people. Apply through the learning portal by Friday!""",
        "media_url": "https://videos.pexels.com/video-files/7688137/7688137-uhd_2732_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/7688137/pexels-photo-7688137.jpeg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 25,
        "tags": ["learning", "hr"],
        "is_company_important": False,
        "author_role": "hr",
    },
    {
        "title": "Slack Etiquette Tips",
        "body": "Best practices for async communication. Be respectful of everyone's time.",
        "transcript": """Let's talk about Slack etiquette. First: don't just say 'hi' and wait. State your question.
Use threads for discussions. Respect notification settings. Avoid after-hours messages unless urgent.
Use emoji reactions instead of reply-all 'thanks'. The thumbs up is your friend!
Good async communication makes remote work better for everyone.""",
        "media_url": "https://videos.pexels.com/video-files/5473085/5473085-uhd_2560_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/5473085/free-video-5473085.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 24,
        "tags": ["learning", "culture"],
        "is_company_important": False,
        "author_role": "comms",
    },
    {
        "title": "Mentorship Program Info",
        "body": "Learn about our mentorship program and how to sign up as a mentor or mentee.",
        "transcript": """Our mentorship program has helped over 500 employees grow their careers.
As a mentee, you get 1-on-1 guidance from experienced team members. As a mentor, you develop leadership skills.
Matches are based on goals and interests. Commitment is just 2 hours per month.
Sign up in the HR portal. First cohort starts next month!""",
        "media_url": "https://videos.pexels.com/video-files/4427628/4427628-uhd_2560_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/4427628/free-video-4427628.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 23,
        "tags": ["learning", "hr"],
        "is_company_important": False,
        "author_role": "hr",
    },
    # Product & Marketing (4 videos)
    {
        "title": "Product Roadmap Preview",
        "body": "Sneak peek at what's coming in the next quarter. Exciting features ahead!",
        "transcript": """Here's a preview of what the product team is building. Dark mode is finally coming!
We're also launching mobile notifications and offline support. The dashboard is getting redesigned.
Customer-requested features make up 60% of this roadmap. We're listening!
Full roadmap review is next Tuesday. Mark your calendars!""",
        "media_url": "https://videos.pexels.com/video-files/7579965/7579965-uhd_2732_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/7579965/pexels-photo-7579965.jpeg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 22,
        "tags": ["product", "company-news"],
        "is_company_important": False,
        "author_role": "marketing",
    },
    {
        "title": "Customer Success Story",
        "body": "How Acme Corp transformed their workflow with our platform. Amazing results!",
        "transcript": """Acme Corp has been using our platform for 6 months. Here are their results.
They reduced manual work by 70%. Team productivity is up 45%. Employee satisfaction increased 30%.
Quote from their CEO: 'This tool has transformed how we work.'
More case studies coming soon. Share these with prospects!""",
        "media_url": "https://videos.pexels.com/video-files/3130284/3130284-uhd_2560_1440_30fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/3130284/free-video-3130284.jpg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 24,
        "tags": ["marketing", "company-news"],
        "is_company_important": False,
        "author_role": "marketing",
    },
    {
        "title": "Brand Guidelines Update",
        "body": "We've refreshed our brand! New colors, fonts, and guidelines for everyone.",
        "transcript": """Our brand has evolved! Here's what you need to know.
We have new primary colors: this blue and this coral. The font is now Inter.
New logo variations are available in the brand portal. Please update your presentations.
Training sessions are available this week. Sign up on the marketing channel!""",
        "media_url": "https://videos.pexels.com/video-files/6774519/6774519-uhd_2732_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/6774519/pexels-photo-6774519.jpeg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 21,
        "tags": ["marketing", "design"],
        "is_company_important": False,
        "author_role": "marketing",
    },
    {
        "title": "User Feedback Highlights",
        "body": "This month's top user feedback and how we're responding. Your voice matters!",
        "transcript": """Let's look at this month's user feedback. Search speed was the top request. Done!
Dark mode is second most requested. It's in development. Mobile app improvements are third.
NPS score is at 72, up from 65. Customer satisfaction at all-time high!
Keep the feedback coming. Every comment is read by the product team.""",
        "media_url": "https://videos.pexels.com/video-files/7688199/7688199-uhd_2732_1440_25fps.mp4",
        "thumbnail_url": "https://images.pexels.com/videos/7688199/pexels-photo-7688199.jpeg?auto=compress&cs=tinysrgb&w=800",
        "duration_seconds": 25,
        "tags": ["product", "company-news"],
        "is_company_important": False,
        "author_role": "marketing",
    },
]


def get_user_by_role(db: Session, role: str) -> User | None:
    """Find a user by their role."""
    return db.query(User).filter(User.role == role).first()


def get_tag_by_slug(db: Session, slug: str) -> Tag | None:
    """Find a tag by its slug."""
    return db.query(Tag).filter(Tag.slug == slug).first()


def seed_demo_users(db: Session) -> dict[str, User]:
    """Create demo users if they don't exist."""
    users = {}
    for user_data in DEMO_USERS:
        existing = db.query(User).filter(User.email == user_data["email"]).first()
        if existing:
            users[user_data["role"]] = existing
        else:
            user = User(**user_data)
            db.add(user)
            db.flush()
            users[user_data["role"]] = user
            print(f"Created demo user: {user.display_name}")
    db.commit()
    return users


def seed_demo_content(db: Session) -> list[Content]:
    """Create demo video content."""
    # Check if we already have demo content
    existing_count = (
        db.query(Content)
        .filter(Content.content_type == ContentType.VIDEO.value)
        .count()
    )
    if existing_count >= 20:
        print(f"Demo content already exists ({existing_count} videos). Skipping.")
        return []

    # Ensure demo users exist
    users = seed_demo_users(db)

    # Create content with varying timestamps (last 30 days)
    created_content = []
    base_time = datetime.now(timezone.utc)

    for i, video_data in enumerate(DEMO_VIDEOS):
        # Find author by role
        author_role = video_data.pop("author_role")
        author = users.get(author_role)
        if not author:
            author = users.get(UserRole.COMMS.value)  # Fallback to comms

        # Get tags
        tag_slugs = video_data.pop("tags")
        tags = []
        for slug in tag_slugs:
            tag = get_tag_by_slug(db, slug)
            if tag:
                tags.append(tag)

        # Pop transcript (stored in body along with description)
        transcript = video_data.pop("transcript")
        description = video_data.pop("body")
        full_body = f"{description}\n\n---\n\n**Transcript:**\n{transcript}"

        # Create content with random timestamp in last 30 days
        random_days = random.randint(0, 29)
        random_hours = random.randint(0, 23)
        created_at = base_time - timedelta(days=random_days, hours=random_hours)

        content = Content(
            author_id=author.id,
            content_type=ContentType.VIDEO.value,
            title=video_data["title"],
            body=full_body,
            media_url=video_data["media_url"],
            thumbnail_url=video_data["thumbnail_url"],
            duration_seconds=video_data["duration_seconds"],
            is_company_important=video_data["is_company_important"],
            sharing_policy=SharingPolicy.INTERNAL_ONLY.value,
            comments_enabled=True,
            created_at=created_at,
            updated_at=created_at,
        )
        content.tags = tags
        db.add(content)
        created_content.append(content)
        print(f"Created demo video: {video_data['title']}")

    db.commit()
    print(f"\nSuccessfully created {len(created_content)} demo videos!")
    return created_content


def clear_demo_content(db: Session):
    """Remove all demo content (for testing/reset)."""
    # Delete content from demo users
    for user_data in DEMO_USERS:
        user = db.query(User).filter(User.email == user_data["email"]).first()
        if user:
            db.query(Content).filter(Content.author_id == user.id).delete()
    db.commit()
    print("Cleared demo content")
