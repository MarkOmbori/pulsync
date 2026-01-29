# Design: Web Platform Adaptations

## Summary

Platform-specific design guidelines for Pulsync on the Web, following modern web standards, accessibility guidelines (WCAG 2.2), and responsive design best practices.

---

## Platform Characteristics

- Mouse, keyboard, and touch input
- Responsive design (mobile to desktop)
- Progressive Web App (PWA) support
- Browser compatibility (Chrome, Safari, Firefox, Edge)
- Accessibility standards compliance
- SEO considerations

---

## Typography

### Font Stack
```css
:root {
  --font-family-sans: system-ui, -apple-system, BlinkMacSystemFont,
    "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-family-mono: ui-monospace, SFMono-Regular, "SF Mono", Menlo,
    Consolas, monospace;
}
```

### Type Scale (CSS Custom Properties)
```css
:root {
  /* Sizes */
  --text-xs: 0.75rem;      /* 12px */
  --text-sm: 0.875rem;     /* 14px */
  --text-base: 1rem;       /* 16px */
  --text-lg: 1.125rem;     /* 18px */
  --text-xl: 1.25rem;      /* 20px */
  --text-2xl: 1.5rem;      /* 24px */
  --text-3xl: 1.875rem;    /* 30px */
  --text-4xl: 2.25rem;     /* 36px */

  /* Line heights */
  --leading-tight: 1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;

  /* Font weights */
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
}
```

### Typography Classes
```css
.text-display {
  font-size: var(--text-4xl);
  font-weight: var(--font-bold);
  line-height: var(--leading-tight);
  letter-spacing: -0.02em;
}

.text-headline {
  font-size: var(--text-3xl);
  font-weight: var(--font-semibold);
  line-height: var(--leading-tight);
}

.text-body {
  font-size: var(--text-base);
  font-weight: var(--font-normal);
  line-height: var(--leading-normal);
}

.text-caption {
  font-size: var(--text-sm);
  font-weight: var(--font-normal);
  line-height: var(--leading-normal);
  color: var(--color-text-secondary);
}
```

---

## Colors

### CSS Custom Properties
```css
:root {
  /* Brand */
  --color-primary: #6366F1;
  --color-primary-light: #818CF8;
  --color-primary-dark: #4F46E5;
  --color-secondary: #14B8A6;

  /* Surfaces */
  --color-background: #FFFFFF;
  --color-surface: #F8F9FA;
  --color-surface-elevated: #FFFFFF;

  /* Text */
  --color-text-primary: #000000;
  --color-text-secondary: #6B7280;
  --color-text-muted: #9CA3AF;

  /* Semantic */
  --color-like: #EF4444;
  --color-follow: #3B82F6;
  --color-success: #22C55E;
  --color-warning: #F59E0B;
  --color-error: #EF4444;

  /* Borders */
  --color-border: rgba(0, 0, 0, 0.1);
  --color-border-strong: rgba(0, 0, 0, 0.2);
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  :root {
    --color-background: #0A0A0B;
    --color-surface: #141416;
    --color-surface-elevated: #1C1C1E;
    --color-text-primary: #FFFFFF;
    --color-text-secondary: #9CA3AF;
    --color-text-muted: #6B7280;
    --color-border: rgba(255, 255, 255, 0.1);
    --color-border-strong: rgba(255, 255, 255, 0.2);
  }
}

/* Manual theme toggle */
[data-theme="dark"] {
  --color-background: #0A0A0B;
  /* ... */
}
```

---

## Icons

### Icon Library (Lucide)
```html
<!-- Via CDN -->
<script src="https://unpkg.com/lucide@latest"></script>

<!-- Usage -->
<i data-lucide="heart"></i>
<i data-lucide="message-circle"></i>
```

### Icon Mapping

| Action | Lucide Icon | Filled (CSS) |
|--------|-------------|--------------|
| Home | home | --fill: currentColor |
| Discover | compass | --fill: currentColor |
| Define | target | --fill: currentColor |
| Deliver | check-circle | --fill: currentColor |
| Like | heart | --fill: var(--color-like) |
| Comment | message-circle | --fill: currentColor |
| Share | share-2 | - |
| Bookmark | bookmark | --fill: currentColor |
| Profile | user | --fill: currentColor |
| Settings | settings | - |
| Search | search | - |
| Close | x | - |

### Icon Sizing
```css
.icon-xs { width: 16px; height: 16px; }
.icon-sm { width: 20px; height: 20px; }
.icon-md { width: 24px; height: 24px; }
.icon-lg { width: 32px; height: 32px; }
.icon-xl { width: 48px; height: 48px; }
```

---

## Components

### Navigation (Bottom/Side)
```html
<!-- Mobile: Bottom nav -->
<nav class="bottom-nav" role="navigation" aria-label="Main">
  <a href="/" class="nav-item active" aria-current="page">
    <i data-lucide="home"></i>
    <span>Home</span>
  </a>
  <a href="/discover" class="nav-item">
    <i data-lucide="compass"></i>
    <span>Discover</span>
  </a>
  <!-- ... -->
</nav>

<!-- Desktop: Sidebar -->
<aside class="sidebar" role="navigation" aria-label="Main">
  <!-- Similar structure -->
</aside>
```

```css
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  justify-content: space-around;
  padding: 8px 0 calc(8px + env(safe-area-inset-bottom));
  background: var(--color-surface);
  border-top: 1px solid var(--color-border);
  z-index: 100;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 8px 16px;
  color: var(--color-text-secondary);
  text-decoration: none;
  transition: color 0.15s ease;
}

.nav-item.active {
  color: var(--color-primary);
}

@media (min-width: 768px) {
  .bottom-nav { display: none; }
  .sidebar { display: flex; }
}
```

### Cards
```html
<article class="card">
  <header class="card-header">
    <img src="avatar.jpg" alt="" class="avatar">
    <div class="card-meta">
      <span class="username">@handle</span>
      <time datetime="2026-01-29">2h ago</time>
    </div>
    <button class="btn-icon" aria-label="More options">
      <i data-lucide="more-horizontal"></i>
    </button>
  </header>
  <div class="card-content">
    <p>Post content...</p>
  </div>
  <footer class="card-actions">
    <button class="action-btn" aria-label="Like">
      <i data-lucide="heart"></i>
      <span>123</span>
    </button>
    <!-- ... -->
  </footer>
</article>
```

```css
.card {
  background: var(--color-surface);
  border-radius: 12px;
  border: 1px solid var(--color-border);
  overflow: hidden;
}

.card-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
}

.card-content {
  padding: 0 16px 16px;
}

.card-actions {
  display: flex;
  gap: 24px;
  padding: 12px 16px;
  border-top: 1px solid var(--color-border);
}
```

### Buttons
```html
<!-- Primary -->
<button class="btn btn-primary">Follow</button>

<!-- Secondary -->
<button class="btn btn-secondary">Following</button>

<!-- Icon button -->
<button class="btn-icon" aria-label="Like">
  <i data-lucide="heart"></i>
</button>
```

```css
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 8px 20px;
  font-size: var(--text-sm);
  font-weight: var(--font-semibold);
  border-radius: 9999px;
  border: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-primary {
  background: var(--color-primary);
  color: white;
}

.btn-primary:hover {
  background: var(--color-primary-dark);
}

.btn-primary:active {
  transform: scale(0.95);
}

.btn-secondary {
  background: transparent;
  border: 1px solid var(--color-border-strong);
  color: var(--color-text-primary);
}

.btn-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: transparent;
  border: none;
  cursor: pointer;
  transition: background 0.15s ease;
}

.btn-icon:hover {
  background: var(--color-surface);
}
```

### Modal/Sheet
```html
<dialog class="modal" id="comments-modal">
  <div class="modal-header">
    <h2>Comments</h2>
    <button class="btn-icon" onclick="this.closest('dialog').close()"
            aria-label="Close">
      <i data-lucide="x"></i>
    </button>
  </div>
  <div class="modal-body">
    <!-- Content -->
  </div>
</dialog>
```

```css
.modal {
  position: fixed;
  inset: auto 0 0 0;
  max-height: 90vh;
  width: 100%;
  margin: 0;
  padding: 0;
  border: none;
  border-radius: 24px 24px 0 0;
  background: var(--color-surface);
  animation: slideUp 0.3s ease;
}

.modal::backdrop {
  background: rgba(0, 0, 0, 0.5);
  animation: fadeIn 0.3s ease;
}

@keyframes slideUp {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}

@media (min-width: 768px) {
  .modal {
    inset: 50% auto auto 50%;
    transform: translate(-50%, -50%);
    max-width: 500px;
    border-radius: 24px;
    animation: fadeIn 0.2s ease, scaleIn 0.2s ease;
  }
}
```

---

## Animations

### CSS Transitions
```css
:root {
  --transition-fast: 0.15s ease;
  --transition-normal: 0.25s ease;
  --transition-slow: 0.4s ease;
}

/* Respect reduced motion */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Keyframe Animations
```css
@keyframes heartBounce {
  0% { transform: scale(1); }
  15% { transform: scale(1.3); }
  30% { transform: scale(0.9); }
  45% { transform: scale(1.1); }
  60% { transform: scale(0.95); }
  100% { transform: scale(1); }
}

.like-animation {
  animation: heartBounce 0.4s ease;
}

@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}

.skeleton {
  background: linear-gradient(
    90deg,
    var(--color-surface) 25%,
    var(--color-surface-elevated) 50%,
    var(--color-surface) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
```

### JavaScript Animation (for complex interactions)
```javascript
// Like animation with Web Animations API
function animateLike(element) {
  element.animate([
    { transform: 'scale(1)', color: 'currentColor' },
    { transform: 'scale(1.3)', color: 'var(--color-like)', offset: 0.15 },
    { transform: 'scale(1)', color: 'var(--color-like)' }
  ], {
    duration: 400,
    easing: 'cubic-bezier(0.175, 0.885, 0.32, 1.275)'
  });
}
```

---

## Responsive Design

### Breakpoints
```css
/* Mobile-first breakpoints */
:root {
  --breakpoint-sm: 640px;
  --breakpoint-md: 768px;
  --breakpoint-lg: 1024px;
  --breakpoint-xl: 1280px;
  --breakpoint-2xl: 1536px;
}

/* Usage */
@media (min-width: 768px) { /* Tablet */ }
@media (min-width: 1024px) { /* Desktop */ }
```

### Container Queries
```css
.card-container {
  container-type: inline-size;
}

@container (min-width: 400px) {
  .card {
    display: grid;
    grid-template-columns: 1fr 2fr;
  }
}
```

### Layout Patterns
```css
/* Mobile: Single column */
.feed {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 16px;
  padding-bottom: calc(80px + env(safe-area-inset-bottom));
}

/* Tablet: Two columns */
@media (min-width: 768px) {
  .feed {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 24px;
    padding: 24px;
    padding-bottom: 24px;
  }
}

/* Desktop: Three columns with sidebar */
@media (min-width: 1024px) {
  .app-layout {
    display: grid;
    grid-template-columns: 240px 1fr 300px;
  }

  .feed {
    grid-template-columns: repeat(1, 1fr);
  }
}
```

---

## Accessibility

### ARIA Patterns
```html
<!-- Live regions for updates -->
<div aria-live="polite" aria-atomic="true" class="sr-only" id="announcer">
  <!-- Dynamically updated -->
</div>

<!-- Tab list -->
<div role="tablist" aria-label="Feed tabs">
  <button role="tab" aria-selected="true" aria-controls="for-you">For You</button>
  <button role="tab" aria-selected="false" aria-controls="following">Following</button>
</div>

<!-- Modal dialog -->
<dialog role="dialog" aria-labelledby="modal-title" aria-modal="true">
  <h2 id="modal-title">Comments</h2>
  <!-- ... -->
</dialog>
```

### Focus Management
```css
/* Visible focus indicators */
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

/* Skip link */
.skip-link {
  position: absolute;
  top: -100%;
  left: 0;
  padding: 8px 16px;
  background: var(--color-primary);
  color: white;
  z-index: 1000;
}

.skip-link:focus {
  top: 0;
}
```

```javascript
// Trap focus in modal
function trapFocus(modal) {
  const focusable = modal.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  );
  const first = focusable[0];
  const last = focusable[focusable.length - 1];

  modal.addEventListener('keydown', (e) => {
    if (e.key === 'Tab') {
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    }
  });
}
```

### Color Contrast
```css
/* Ensure 4.5:1 contrast for text */
/* Use contrast checker tools during development */

/* High contrast mode support */
@media (prefers-contrast: high) {
  :root {
    --color-border: currentColor;
    --color-text-secondary: var(--color-text-primary);
  }
}
```

---

## PWA Features

### Web App Manifest
```json
{
  "name": "Pulsync",
  "short_name": "Pulsync",
  "description": "Enterprise social communication platform",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0A0A0B",
  "theme_color": "#6366F1",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

### Service Worker
```javascript
// Cache-first strategy for static assets
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});
```

---

## Performance

### Critical CSS
```html
<head>
  <style>
    /* Inline critical CSS */
    :root { /* ... */ }
    .app-shell { /* ... */ }
  </style>
  <link rel="preload" href="/styles/main.css" as="style"
        onload="this.onload=null;this.rel='stylesheet'">
</head>
```

### Image Optimization
```html
<!-- Responsive images -->
<img
  src="image-400.jpg"
  srcset="
    image-400.jpg 400w,
    image-800.jpg 800w,
    image-1200.jpg 1200w
  "
  sizes="(max-width: 600px) 100vw, 50vw"
  loading="lazy"
  decoding="async"
  alt="Description"
>

<!-- Modern formats -->
<picture>
  <source srcset="image.avif" type="image/avif">
  <source srcset="image.webp" type="image/webp">
  <img src="image.jpg" alt="">
</picture>
```

### Code Splitting
```javascript
// Dynamic imports
const CommentsModal = lazy(() => import('./CommentsModal'));

// Intersection Observer for lazy loading
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      // Load content
      observer.unobserve(entry.target);
    }
  });
});
```
