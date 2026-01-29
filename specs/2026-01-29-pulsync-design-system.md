# Design: Pulsync Unified Design System

## Summary

A comprehensive cross-platform design system for Pulsync - an enterprise social communication platform. This system blends the best UX patterns from TikTok (immersive content), Instagram (engagement), and LinkedIn (professional credibility) while maintaining platform-native experiences across Web, iOS, Android, macOS, and Windows.

**Design Philosophy**: Clean, sparse, intuitive - where social media natives feel at home and enterprise users understand every function.

---

## Design Tokens

### Color Palette

#### Semantic Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--color-background` | #FFFFFF | #0A0A0B | App background |
| `--color-surface` | #F8F9FA | #141416 | Card backgrounds |
| `--color-surface-elevated` | #FFFFFF | #1C1C1E | Elevated surfaces |
| `--color-surface-overlay` | rgba(0,0,0,0.4) | rgba(0,0,0,0.6) | Modal overlays |

#### Text Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--color-text-primary` | #000000 | #FFFFFF | Primary text |
| `--color-text-secondary` | #6B7280 | #9CA3AF | Secondary text |
| `--color-text-muted` | #9CA3AF | #6B7280 | Muted/caption text |
| `--color-text-inverse` | #FFFFFF | #000000 | Text on colored bg |

#### Brand Colors

| Token | Value | Usage |
|-------|-------|-------|
| `--color-primary` | #6366F1 | Primary actions, links |
| `--color-primary-light` | #818CF8 | Hover states |
| `--color-primary-dark` | #4F46E5 | Active states |
| `--color-secondary` | #14B8A6 | Secondary actions |

#### Semantic Action Colors

| Token | Value | Usage |
|-------|-------|-------|
| `--color-like` | #EF4444 | Like/heart actions |
| `--color-follow` | #3B82F6 | Follow button |
| `--color-success` | #22C55E | Success states |
| `--color-warning` | #F59E0B | Warning states |
| `--color-error` | #EF4444 | Error states |

#### Gradient Definitions

```css
--gradient-primary: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%);
--gradient-surface-fade: linear-gradient(to top, rgba(0,0,0,0.7) 0%, transparent 100%);
--gradient-glass: linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%);
```

---

### Typography Scale

#### Type Ramp

| Style | Size | Weight | Line Height | Tracking | Usage |
|-------|------|--------|-------------|----------|-------|
| Display | 36pt | Bold (700) | 1.1 | -0.02em | Hero sections |
| Headline | 28pt | Semibold (600) | 1.2 | -0.01em | Page titles |
| Title 1 | 22pt | Semibold (600) | 1.3 | 0 | Section headers |
| Title 2 | 18pt | Medium (500) | 1.3 | 0 | Card titles |
| Body Large | 17pt | Regular (400) | 1.5 | 0 | Primary content |
| Body | 15pt | Regular (400) | 1.5 | 0.01em | Standard content |
| Label | 14pt | Medium (500) | 1.4 | 0.02em | Buttons, tabs |
| Caption | 12pt | Regular (400) | 1.4 | 0.02em | Meta information |
| Micro | 10pt | Medium (500) | 1.2 | 0.03em | Badges, counts |

#### Platform Font Stacks

| Platform | Font Family |
|----------|-------------|
| Apple (iOS/macOS) | SF Pro Text, SF Pro Display |
| Android | Roboto, Google Sans |
| Windows | Segoe UI Variable |
| Web | system-ui, -apple-system, Segoe UI, Roboto, sans-serif |

---

### Spacing Scale

Based on 4pt grid system.

| Token | Value | Usage |
|-------|-------|-------|
| `--space-0` | 0 | No spacing |
| `--space-1` | 4px | Tight spacing |
| `--space-2` | 8px | Component internal |
| `--space-3` | 12px | Small gaps |
| `--space-4` | 16px | Standard padding |
| `--space-5` | 20px | Card padding |
| `--space-6` | 24px | Section gaps |
| `--space-8` | 32px | Large gaps |
| `--space-10` | 40px | Container padding |
| `--space-12` | 48px | Section spacing |
| `--space-16` | 64px | Major sections |
| `--space-20` | 80px | Page sections |

---

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `--radius-none` | 0 | Square corners |
| `--radius-sm` | 4px | Small elements |
| `--radius-md` | 8px | Buttons, inputs |
| `--radius-lg` | 12px | Cards |
| `--radius-xl` | 16px | Large cards |
| `--radius-2xl` | 24px | Modals |
| `--radius-full` | 9999px | Pills, avatars |

---

### Elevation (Shadows)

| Level | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| 0 | none | none | Flat elements |
| 1 | 0 1px 3px rgba(0,0,0,0.1) | 0 1px 3px rgba(0,0,0,0.3) | Cards |
| 2 | 0 4px 12px rgba(0,0,0,0.1) | 0 4px 12px rgba(0,0,0,0.4) | Floating buttons |
| 3 | 0 8px 24px rgba(0,0,0,0.15) | 0 8px 24px rgba(0,0,0,0.5) | Modals |
| 4 | 0 16px 48px rgba(0,0,0,0.2) | 0 16px 48px rgba(0,0,0,0.6) | Overlays |

---

### Animation Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `--duration-instant` | 50ms | Immediate feedback |
| `--duration-fast` | 150ms | Micro-interactions |
| `--duration-normal` | 250ms | Standard transitions |
| `--duration-slow` | 400ms | Complex animations |
| `--duration-slower` | 600ms | Page transitions |
| `--easing-default` | cubic-bezier(0.4, 0, 0.2, 1) | Standard ease |
| `--easing-in` | cubic-bezier(0.4, 0, 1, 1) | Enter animations |
| `--easing-out` | cubic-bezier(0, 0, 0.2, 1) | Exit animations |
| `--easing-bounce` | cubic-bezier(0.175, 0.885, 0.32, 1.275) | Bouncy effects |

---

## Core Components

### 1. ContentCard (Full-Screen Immersive)

The primary content unit, inspired by TikTok's full-screen video cards.

**Structure:**
```
┌─────────────────────────────────┐
│                                 │
│         [Content Area]          │
│      (Image/Video/Text)         │
│                                 │
│  ┌──────────────────────┐ ┌───┐ │
│  │ Author Info          │ │ A │ │
│  │ @username · 2h       │ │ c │ │
│  │ Description text...  │ │ t │ │
│  │                      │ │ i │ │
│  │ #tag #tag #tag       │ │ o │ │
│  └──────────────────────┘ │ n │ │
│                           │ s │ │
└───────────────────────────┴───┘
```

**Specifications:**
- Full viewport height (minus navigation)
- Content fills with `object-fit: cover` (images/video)
- Bottom gradient overlay for text readability
- Author info bottom-left, max-width 70%
- Action buttons bottom-right, vertical stack

**States:**
- Default: Content visible
- Playing: Video/audio playing indicator
- Paused: Tap-to-play overlay
- Liked: Heart animation overlay

---

### 2. ActionBar (Floating Vertical)

Right-side floating actions, inspired by TikTok/Instagram Reels.

**Structure:**
```
┌─────┐
│  👤 │  Profile (tap = view user)
│ 42K │
├─────┤
│  ❤️ │  Like (tap = like, double-tap content also)
│ 3.2K│
├─────┤
│  💬 │  Comment (tap = open sheet)
│  847│
├─────┤
│  ↗️ │  Share (tap = share sheet)
│  231│
├─────┤
│  🔖 │  Bookmark (tap = save)
└─────┘
```

**Specifications:**
- Button size: 48x48pt (touch target)
- Icon size: 24pt
- Button spacing: 16pt vertical gap
- Count typography: Caption style
- Background: Glass material (0.15 opacity white)
- Corner radius: Full (circular)
- Position: 16pt from right edge, centered vertically

**States:**
- Default: White icon, muted count
- Active (liked/bookmarked): Filled icon, colored
- Pressed: Scale 0.9, 100ms duration
- Disabled: 0.5 opacity

---

### 3. TabNavigation (Bottom Tabs)

Four-pillar navigation system.

**Tabs:**
1. **Home** (house icon) - Feed content
2. **Discover** (compass icon) - Explore/search
3. **Define** (target icon) - Goals/OKRs
4. **Deliver** (check-circle icon) - Accomplishments

**Specifications:**
- Height: 84pt (includes safe area on mobile)
- Background: Surface color with glass effect
- Icon size: 24pt
- Label: Caption style
- Active indicator: Filled icon + primary color label
- Touch target: Full tab width, minimum 64pt height

**States:**
- Default: Muted icon and label
- Active: Primary color icon (filled), primary label
- Pressed: Scale 0.95

---

### 4. FeedItem (Card Style)

For text-heavy content in scrolling feeds.

**Structure:**
```
┌─────────────────────────────────┐
│ 👤 Name · @handle · 2h    ···   │
├─────────────────────────────────┤
│                                 │
│ Content text that can span      │
│ multiple lines...               │
│                                 │
│ [Optional: Image/Link Preview]  │
│                                 │
├─────────────────────────────────┤
│ ❤️ 123   💬 45   ↗️ Share      │
└─────────────────────────────────┘
```

**Specifications:**
- Padding: 16pt all sides
- Background: Surface color
- Corner radius: 12pt
- Border: 1pt subtle border (0.1 opacity)
- Avatar: 40pt circular
- Actions: Horizontal row, spaced evenly

---

### 5. UserAvatar

Circular profile image with status.

**Sizes:**
- XS: 24pt (inline mentions)
- SM: 32pt (comments, lists)
- MD: 40pt (feed items)
- LG: 56pt (profiles)
- XL: 80pt (profile headers)

**Specifications:**
- Shape: Circular (full radius)
- Border: Optional 2pt primary gradient (following users)
- Online indicator: 12pt green dot, positioned bottom-right
- Fallback: Initials on gradient background

---

### 6. FollowButton

Primary action for user following.

**Variants:**
- **Follow** (default): Primary fill, "Follow" label
- **Following**: Outline style, "Following" label
- **Requested** (private): Outline, "Requested" label

**Specifications:**
- Height: 36pt
- Padding: 16pt horizontal
- Corner radius: Full (pill)
- Typography: Label style, Medium weight

**States:**
- Default: Full background
- Hover: Slight darken
- Pressed: Scale 0.95
- Loading: Spinner replaces label

---

### 7. CommentSheet

Bottom sheet for comments, inspired by Instagram.

**Structure:**
```
┌─────────────────────────────────┐
│ ──── (drag indicator)           │
│ Comments (847)              ✕   │
├─────────────────────────────────┤
│                                 │
│ [Scrollable comment list]       │
│                                 │
├─────────────────────────────────┤
│ 👤 │ Add a comment...    [Post] │
└─────────────────────────────────┘
```

**Specifications:**
- Default height: 60% viewport
- Max height: 90% viewport
- Background: Surface color
- Corner radius: 24pt top corners
- Drag indicator: 36pt wide, 4pt height
- Input: Sticky at bottom

---

### 8. SearchBar

Universal search with filters.

**Structure:**
```
┌─────────────────────────────────┐
│ 🔍 │ Search Pulsync...    [🎤]  │
└─────────────────────────────────┘
```

**Specifications:**
- Height: 44pt
- Corner radius: Full (pill)
- Background: Surface elevated
- Icon: 20pt, muted color
- Placeholder: Secondary text

**States:**
- Default: Collapsed
- Focused: Expanded, cancel button appears
- Active: Search results overlay

---

### 9. CardGrid (Bento)

Dashboard-style grid layout for Discover/Define sections.

**Structure:**
```
┌────────┬────────┬────────┐
│   2x2  │   1x1  │   1x1  │
│        ├────────┴────────┤
│        │       2x1       │
├────────┴─────────────────┤
│          3x1             │
└──────────────────────────┘
```

**Specifications:**
- Grid gap: 8pt
- Card radius: 12pt
- Responsive: Reflows based on viewport

---

## Interaction Patterns

### Gesture Language

| Gesture | Action | Feedback |
|---------|--------|----------|
| Tap | Select/activate | Ripple (Android), Highlight (iOS) |
| Double-tap | Like content | Heart animation |
| Long-press | Context menu | Haptic + menu |
| Swipe up/down | Navigate content | Smooth scroll/snap |
| Swipe right | Go back (iOS) | Edge pan gesture |
| Pull down | Refresh | Custom refresh indicator |
| Pinch | Zoom (images) | Scale transform |

### Micro-interactions

#### Like Animation
1. Heart icon scales 1.0 → 1.3 → 1.0 (bounce)
2. Color transitions white → red
3. Particles emit from center
4. Duration: 400ms total

#### Button Press
1. Scale 1.0 → 0.95
2. Duration: 100ms
3. Easing: ease-out

#### Follow Button Transition
1. Background fill fades out
2. Border appears
3. Label cross-fades "Follow" → "Following"
4. Duration: 250ms

#### Loading States
- Skeleton screens for content (shimmer animation)
- Inline spinners for actions (20pt, primary color)
- Progress bars for uploads (linear, primary color)

---

## Navigation Patterns

### Tab-based (Primary)
- 4 main tabs always visible
- Active tab indicator
- Tap to switch, no swipe between tabs
- Each tab maintains own navigation stack

### Stack Navigation (Secondary)
- Push/pop for drill-down
- Swipe from left edge to go back (iOS)
- Back button in header (Android)
- Modal presentation for isolated flows

### Sheet Presentation
- Bottom sheets for auxiliary content
- Drag to dismiss
- Multiple detents (50%, 75%, 100%)
- Dismisses on outside tap

---

## Accessibility Requirements

### Color Contrast
- Text on background: 4.5:1 minimum
- Large text (18pt+): 3:1 minimum
- Interactive elements: 3:1 minimum
- Icons: 3:1 minimum

### Touch Targets
- Minimum: 44x44pt
- Recommended: 48x48pt
- Spacing between targets: 8pt minimum

### Focus Management
- Visible focus indicators
- Logical tab order
- Skip navigation links (web)
- Focus trap in modals

### Motion
- Respect `prefers-reduced-motion`
- Provide static alternatives
- No autoplay video with sound
- Pause/stop controls for animations

### Screen Readers
- Semantic markup
- ARIA labels where needed
- Alt text for all images
- Live regions for updates
- Announce state changes

### Typography
- Support Dynamic Type (iOS)
- Support font scaling (Android)
- Minimum 16px body text (web)
- Line height 1.5 minimum for body

---

## Responsive Breakpoints

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Mobile S | 320px | Single column |
| Mobile M | 375px | Single column |
| Mobile L | 425px | Single column |
| Tablet | 768px | Two column |
| Laptop | 1024px | Two/three column |
| Desktop | 1440px | Three column + sidebar |
| Wide | 1920px+ | Three column + sidebar, max-width container |

### Layout Adaptations
- **Mobile**: Full-screen cards, bottom navigation
- **Tablet**: Split view option, larger cards
- **Desktop**: Sidebar navigation, multi-column feeds

---

## Dark Mode

Dark mode is the default. Light mode is fully supported.

### Implementation
- Use semantic color tokens
- Automatic switching based on system preference
- Manual toggle in settings
- Persist user preference

### Dark Mode Adjustments
- Reduce elevation shadows
- Increase surface contrast slightly
- Adjust image brightness (optional filter)
- Ensure sufficient contrast ratios

---

## Implementation Guidelines

### CSS Custom Properties (Web)
```css
:root {
  --color-primary: #6366F1;
  --color-background: #0A0A0B;
  --color-surface: #141416;
  --space-4: 16px;
  --radius-lg: 12px;
  /* ... */
}

[data-theme="light"] {
  --color-background: #FFFFFF;
  --color-surface: #F8F9FA;
  /* ... */
}
```

### SwiftUI (Apple)
```swift
enum PulsyncColors {
    static let primary = Color("Primary")
    static let background = Color("Background")
    // Use asset catalogs for light/dark variants
}
```

### Compose (Android)
```kotlin
val PulsyncColors = lightColors(
    primary = Color(0xFF6366F1),
    background = Color(0xFFFFFFFF),
    // ...
)
```

---

## Assets Required

### Icons
- SF Symbols mappings (Apple)
- Material Icons mappings (Android)
- Fluent Icons mappings (Windows)
- Lucide/Phosphor set (Web)

### Illustrations
- Empty states (no content, no connection, error)
- Onboarding screens
- Success celebrations

### Animations
- Like heart (Lottie/Core Animation)
- Loading skeleton shimmer
- Pull-to-refresh
- Tab transition

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-29 | Initial design system |
