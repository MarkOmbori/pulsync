# Design: Apple Platform Adaptations (iOS/macOS)

## Summary

Platform-specific design guidelines for Pulsync on Apple platforms, following Human Interface Guidelines (HIG) and leveraging Liquid Glass design language (WWDC 2025).

---

## Platform Characteristics

### iOS
- Touch-first interaction
- Bottom navigation pattern
- Edge swipe gestures
- Dynamic Type support
- Safe areas (notch, home indicator)
- Haptic feedback

### macOS
- Mouse/trackpad + keyboard
- Menu bar and window chrome
- Sidebar navigation option
- Hover states
- Keyboard shortcuts
- Window resizing

---

## Typography

### Font Stack
```swift
// SF Pro (automatic weight optical sizing)
.font(.system(.body))      // SF Pro Text at smaller sizes
.font(.system(.title))     // SF Pro Display at larger sizes
```

### Type Mapping

| Design Token | SwiftUI Style | iOS | macOS |
|--------------|---------------|-----|-------|
| Display | .largeTitle | 34pt | 34pt |
| Headline | .title | 28pt | 28pt |
| Title 1 | .title2 | 22pt | 22pt |
| Title 2 | .title3 | 20pt | 20pt |
| Body Large | .body | 17pt | 17pt |
| Body | .callout | 16pt | 16pt |
| Label | .subheadline | 15pt | 15pt |
| Caption | .caption | 12pt | 12pt |
| Micro | .caption2 | 11pt | 11pt |

### Dynamic Type Support
```swift
// Enable automatic scaling
.dynamicTypeSize(.xxxLarge)
.minimumScaleFactor(0.8)
```

---

## Colors

### Asset Catalog Structure
```
Assets.xcassets/
├── Colors/
│   ├── Primary.colorset
│   │   ├── Contents.json (Any, Dark)
│   ├── Background.colorset
│   ├── Surface.colorset
│   ├── TextPrimary.colorset
│   └── ...
```

### SwiftUI Color Extensions
```swift
extension Color {
    static let pulsyncPrimary = Color("Primary")
    static let pulsyncBackground = Color("Background")
    static let pulsyncSurface = Color("Surface")
}
```

### System Colors Integration
```swift
// Use system semantic colors where appropriate
.foregroundColor(.primary)      // Adapts to light/dark
.foregroundColor(.secondary)    // Muted text
.background(.regularMaterial)   // Glass effects
```

---

## Materials & Depth

### Liquid Glass (iOS 26+, macOS 26+)
```swift
// Liquid Glass material for floating elements
.background(.liquidGlass)
.glassBackgroundEffect()

// Fallback for earlier versions
.background(.ultraThinMaterial)
```

### Material Hierarchy
| Use Case | Material | Fallback |
|----------|----------|----------|
| Tab bar | .glassBar | .bar |
| Action buttons | .ultraThinMaterial | - |
| Sheets | .regularMaterial | - |
| Overlays | .thickMaterial | - |

### Shadow Implementation
```swift
// Elevation levels
extension View {
    func elevation(_ level: Int) -> some View {
        switch level {
        case 1: shadow(color: .black.opacity(0.1), radius: 3, y: 1)
        case 2: shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        case 3: shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        default: self
        }
    }
}
```

---

## Icons

### SF Symbols Usage

| Action | Symbol Name | Filled Variant |
|--------|-------------|----------------|
| Home | house | house.fill |
| Discover | safari | safari.fill |
| Define | scope | scope |
| Deliver | checkmark.circle | checkmark.circle.fill |
| Like | heart | heart.fill |
| Comment | bubble.right | bubble.right.fill |
| Share | square.and.arrow.up | - |
| Bookmark | bookmark | bookmark.fill |
| Profile | person.circle | person.circle.fill |
| Settings | gearshape | gearshape.fill |
| Search | magnifyingglass | - |
| Close | xmark | xmark.circle.fill |

### Symbol Configuration
```swift
Image(systemName: "heart.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(.red)
    .font(.system(size: 24, weight: .medium))
```

### Symbol Effects
```swift
// Bounce on like
Image(systemName: "heart.fill")
    .symbolEffect(.bounce, value: isLiked)

// Pulse for loading
Image(systemName: "circle.fill")
    .symbolEffect(.pulse)
```

---

## Components

### TabView (Bottom Navigation)
```swift
TabView(selection: $selectedTab) {
    HomeView()
        .tabItem {
            Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
        }
        .tag(0)

    DiscoverView()
        .tabItem {
            Label("Discover", systemImage: selectedTab == 1 ? "safari.fill" : "safari")
        }
        .tag(1)

    // ...
}
.tint(.pulsyncPrimary)
```

### Sheets & Modals
```swift
// Bottom sheet (iOS 16+)
.sheet(isPresented: $showComments) {
    CommentsView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
}
```

### Context Menus
```swift
.contextMenu {
    Button(action: { }) {
        Label("Save", systemImage: "bookmark")
    }
    Button(action: { }) {
        Label("Share", systemImage: "square.and.arrow.up")
    }
    Divider()
    Button(role: .destructive, action: { }) {
        Label("Report", systemImage: "exclamationmark.triangle")
    }
}
```

### Pull to Refresh
```swift
List {
    // Content
}
.refreshable {
    await viewModel.refresh()
}
```

---

## Gestures

### Swipe Navigation (iOS)
```swift
.gesture(
    DragGesture()
        .onChanged { value in
            // Track horizontal swipe for back
        }
        .onEnded { value in
            if value.translation.width > 100 {
                dismiss()
            }
        }
)

// Or use native:
.navigationBarBackButtonHidden(false)
```

### Double Tap to Like
```swift
.onTapGesture(count: 2) {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
        isLiked = true
        showHeartAnimation = true
    }
    // Haptic feedback
    let impact = UIImpactFeedbackGenerator(style: .medium)
    impact.impactOccurred()
}
```

### Long Press Context
```swift
.onLongPressGesture(minimumDuration: 0.5) {
    showContextMenu = true
    let impact = UIImpactFeedbackGenerator(style: .heavy)
    impact.impactOccurred()
}
```

---

## Haptics

### Feedback Types
```swift
// Selection (tab changes, toggles)
UISelectionFeedbackGenerator().selectionChanged()

// Impact (button presses, likes)
UIImpactFeedbackGenerator(style: .medium).impactOccurred()

// Notification (success, error)
UINotificationFeedbackGenerator().notificationOccurred(.success)
```

### When to Use
| Action | Haptic Type |
|--------|-------------|
| Tab switch | Selection |
| Like/unlike | Impact (medium) |
| Button press | Impact (light) |
| Follow | Impact (medium) |
| Error | Notification (error) |
| Success | Notification (success) |
| Long press menu | Impact (heavy) |

---

## Animations

### Spring Animations
```swift
// Bouncy (buttons, likes)
.animation(.spring(response: 0.35, dampingFraction: 0.6), value: state)

// Smooth (transitions)
.animation(.easeInOut(duration: 0.25), value: state)

// Quick (micro-interactions)
.animation(.easeOut(duration: 0.15), value: state)
```

### Page Transitions
```swift
.transition(.push(from: .trailing))
.transition(.move(edge: .bottom))
.transition(.opacity.combined(with: .scale(scale: 0.95)))
```

### Matched Geometry
```swift
// Shared element transitions
@Namespace var animation

// Source
.matchedGeometryEffect(id: item.id, in: animation)

// Destination
.matchedGeometryEffect(id: item.id, in: animation)
```

---

## Layout

### Safe Areas
```swift
// Respect safe areas (default)
.safeAreaInset(edge: .bottom) {
    TabBar()
}

// Ignore for full-screen content
.ignoresSafeArea()
```

### Adaptive Layout
```swift
// Respond to size classes
@Environment(\.horizontalSizeClass) var sizeClass

var body: some View {
    if sizeClass == .compact {
        // iPhone layout
        VStack { }
    } else {
        // iPad/Mac layout
        HStack { }
    }
}
```

### Window Management (macOS)
```swift
WindowGroup {
    ContentView()
}
.windowStyle(.hiddenTitleBar)
.windowResizability(.contentSize)
.defaultSize(width: 400, height: 800)
```

---

## Accessibility

### VoiceOver
```swift
.accessibilityLabel("Like button")
.accessibilityValue(isLiked ? "Liked" : "Not liked")
.accessibilityHint("Double tap to \(isLiked ? "unlike" : "like")")
.accessibilityAddTraits(isLiked ? .isSelected : [])
```

### Dynamic Type
```swift
// Allow text to scale
@ScaledMetric var iconSize: CGFloat = 24

// Limit scaling
@ScaledMetric(relativeTo: .body) var spacing: CGFloat = 16
```

### Reduce Motion
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(reduceMotion ? nil : .spring(), value: state)
```

---

## Platform-Specific Features

### iOS Only
- Swipe-back gesture
- Home indicator
- Face ID / Touch ID
- Widget support
- App Clips

### macOS Only
- Menu bar app option
- Keyboard shortcuts
- Multiple windows
- Touch Bar (legacy)
- Drag and drop

### Shared
- Handoff continuity
- iCloud sync
- SharePlay
- Focus modes
- Widgets (iOS/macOS)

---

## Performance

### Image Loading
```swift
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image.resizable().scaledToFill()
    case .failure:
        Image(systemName: "photo")
    @unknown default:
        EmptyView()
    }
}
```

### List Optimization
```swift
List {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}
.listStyle(.plain)
```

### Lazy Loading
```swift
LazyVStack {
    ForEach(items) { item in
        ItemView(item: item)
            .onAppear {
                if item == items.last {
                    loadMore()
                }
            }
    }
}
```
