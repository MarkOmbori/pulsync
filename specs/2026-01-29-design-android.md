# Design: Android Platform Adaptations

## Summary

Platform-specific design guidelines for Pulsync on Android, following Material Design 3 guidelines and leveraging modern Jetpack Compose patterns.

---

## Platform Characteristics

- Touch-first with gesture navigation
- System-wide theming (Material You)
- Dynamic color extraction
- Bottom navigation or navigation rail
- Back gesture (predictive back)
- Flexible screen sizes (phones, foldables, tablets)

---

## Typography

### Font Stack
```kotlin
// Roboto (system default) with Google Sans for display
val PulsyncTypography = Typography(
    displayLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 57.sp,
        lineHeight = 64.sp
    ),
    // ...
)
```

### Type Mapping

| Design Token | Material 3 | Size |
|--------------|------------|------|
| Display | displayMedium | 45sp |
| Headline | headlineLarge | 32sp |
| Title 1 | titleLarge | 22sp |
| Title 2 | titleMedium | 16sp |
| Body Large | bodyLarge | 16sp |
| Body | bodyMedium | 14sp |
| Label | labelLarge | 14sp |
| Caption | bodySmall | 12sp |
| Micro | labelSmall | 11sp |

---

## Colors

### Material You Integration
```kotlin
@Composable
fun PulsyncTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = PulsyncTypography,
        content = content
    )
}
```

### Color Scheme Definition
```kotlin
private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFF6366F1),
    onPrimary = Color.White,
    primaryContainer = Color(0xFF4F46E5),
    secondary = Color(0xFF14B8A6),
    background = Color(0xFF0A0A0B),
    surface = Color(0xFF141416),
    surfaceVariant = Color(0xFF1C1C1E),
    onBackground = Color.White,
    onSurface = Color.White,
    error = Color(0xFFEF4444)
)

private val LightColorScheme = lightColorScheme(
    primary = Color(0xFF6366F1),
    onPrimary = Color.White,
    background = Color.White,
    surface = Color(0xFFF8F9FA),
    onBackground = Color.Black,
    onSurface = Color.Black
)
```

---

## Icons

### Material Icons Usage

| Action | Icon Name | Filled Variant |
|--------|-----------|----------------|
| Home | Icons.Outlined.Home | Icons.Filled.Home |
| Discover | Icons.Outlined.Explore | Icons.Filled.Explore |
| Define | Icons.Outlined.GpsFixed | Icons.Filled.GpsFixed |
| Deliver | Icons.Outlined.CheckCircle | Icons.Filled.CheckCircle |
| Like | Icons.Outlined.Favorite | Icons.Filled.Favorite |
| Comment | Icons.Outlined.ModeComment | Icons.Filled.ModeComment |
| Share | Icons.Outlined.Share | - |
| Bookmark | Icons.Outlined.Bookmark | Icons.Filled.Bookmark |
| Profile | Icons.Outlined.AccountCircle | Icons.Filled.AccountCircle |
| Settings | Icons.Outlined.Settings | Icons.Filled.Settings |
| Search | Icons.Outlined.Search | - |
| Close | Icons.Outlined.Close | - |

### Icon Implementation
```kotlin
Icon(
    imageVector = if (isLiked) Icons.Filled.Favorite else Icons.Outlined.Favorite,
    contentDescription = "Like",
    tint = if (isLiked) Color(0xFFEF4444) else MaterialTheme.colorScheme.onSurface,
    modifier = Modifier.size(24.dp)
)
```

---

## Components

### Bottom Navigation Bar
```kotlin
NavigationBar(
    containerColor = MaterialTheme.colorScheme.surface,
    tonalElevation = 0.dp
) {
    NavigationBarItem(
        icon = {
            Icon(
                if (selected) Icons.Filled.Home else Icons.Outlined.Home,
                contentDescription = "Home"
            )
        },
        label = { Text("Home") },
        selected = currentRoute == "home",
        onClick = { navController.navigate("home") }
    )
    // ... other items
}
```

### Bottom Sheet
```kotlin
val sheetState = rememberModalBottomSheetState()

ModalBottomSheet(
    onDismissRequest = { showSheet = false },
    sheetState = sheetState,
    dragHandle = { BottomSheetDefaults.DragHandle() },
    containerColor = MaterialTheme.colorScheme.surface
) {
    CommentsContent()
}
```

### Cards
```kotlin
Card(
    modifier = Modifier.fillMaxWidth(),
    shape = RoundedCornerShape(12.dp),
    colors = CardDefaults.cardColors(
        containerColor = MaterialTheme.colorScheme.surface
    ),
    elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
) {
    // Content
}
```

### Buttons
```kotlin
// Primary button
Button(
    onClick = { },
    colors = ButtonDefaults.buttonColors(
        containerColor = MaterialTheme.colorScheme.primary
    ),
    shape = RoundedCornerShape(50)
) {
    Text("Follow")
}

// Follow/Following toggle
FilledTonalButton(
    onClick = { },
    shape = RoundedCornerShape(50)
) {
    Text("Following")
}
```

---

## Gestures

### Double Tap to Like
```kotlin
Modifier.pointerInput(Unit) {
    detectTapGestures(
        onDoubleTap = { offset ->
            isLiked = true
            showHeartAnimation = true
            // Haptic feedback
            hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
        }
    )
}
```

### Swipe Actions
```kotlin
SwipeToDismiss(
    state = dismissState,
    background = {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.errorContainer)
        )
    },
    dismissContent = {
        // Content
    }
)
```

### Pull to Refresh
```kotlin
val pullRefreshState = rememberPullRefreshState(
    refreshing = isRefreshing,
    onRefresh = { viewModel.refresh() }
)

Box(
    modifier = Modifier.pullRefresh(pullRefreshState)
) {
    LazyColumn { }
    PullRefreshIndicator(
        refreshing = isRefreshing,
        state = pullRefreshState,
        modifier = Modifier.align(Alignment.TopCenter)
    )
}
```

---

## Animations

### Animation Specs
```kotlin
// Bouncy spring
val bounceSpec = spring<Float>(
    dampingRatio = 0.6f,
    stiffness = Spring.StiffnessMedium
)

// Smooth tween
val smoothSpec = tween<Float>(
    durationMillis = 250,
    easing = FastOutSlowInEasing
)
```

### Animated Visibility
```kotlin
AnimatedVisibility(
    visible = showContent,
    enter = fadeIn() + slideInVertically(),
    exit = fadeOut() + slideOutVertically()
) {
    // Content
}
```

### Heart Animation
```kotlin
@Composable
fun HeartAnimation(show: Boolean, onComplete: () -> Unit) {
    val scale by animateFloatAsState(
        targetValue = if (show) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.6f),
        finishedListener = { onComplete() }
    )

    if (show) {
        Icon(
            Icons.Filled.Favorite,
            contentDescription = null,
            tint = Color(0xFFEF4444),
            modifier = Modifier
                .scale(scale)
                .size(80.dp)
        )
    }
}
```

---

## Haptics

### Haptic Feedback
```kotlin
val hapticFeedback = LocalHapticFeedback.current

// Light click
hapticFeedback.performHapticFeedback(HapticFeedbackType.TextHandleMove)

// Medium impact
hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
```

### Ripple Effects
```kotlin
// Default ripple on clickable
Modifier.clickable { }

// Custom ripple
Modifier.clickable(
    interactionSource = remember { MutableInteractionSource() },
    indication = rememberRipple(
        bounded = true,
        color = MaterialTheme.colorScheme.primary
    )
) { }
```

---

## Layout

### Adaptive Layout
```kotlin
@Composable
fun AdaptiveLayout() {
    val windowSizeClass = calculateWindowSizeClass()

    when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact -> {
            // Phone layout
            CompactLayout()
        }
        WindowWidthSizeClass.Medium -> {
            // Tablet portrait / foldable
            MediumLayout()
        }
        WindowWidthSizeClass.Expanded -> {
            // Tablet landscape / desktop
            ExpandedLayout()
        }
    }
}
```

### Navigation Rail (Tablets)
```kotlin
NavigationRail(
    containerColor = MaterialTheme.colorScheme.surface
) {
    NavigationRailItem(
        icon = { Icon(Icons.Outlined.Home, null) },
        label = { Text("Home") },
        selected = currentRoute == "home",
        onClick = { }
    )
    // ...
}
```

### Edge-to-Edge
```kotlin
// In Activity
WindowCompat.setDecorFitsSystemWindows(window, false)

// In Compose
Scaffold(
    modifier = Modifier.systemBarsPadding(),
    // ...
)
```

---

## Accessibility

### Content Descriptions
```kotlin
Icon(
    Icons.Filled.Favorite,
    contentDescription = "Like, currently ${if (isLiked) "liked" else "not liked"}"
)
```

### Semantic Properties
```kotlin
Modifier.semantics {
    contentDescription = "Post by @username"
    stateDescription = if (isLiked) "Liked" else "Not liked"
    onClick(label = "Like this post") { true }
}
```

### Touch Targets
```kotlin
// Minimum 48dp touch target
IconButton(
    onClick = { },
    modifier = Modifier.size(48.dp)
) {
    Icon(Icons.Outlined.Favorite, contentDescription = "Like")
}
```

---

## Performance

### Lazy Lists
```kotlin
LazyColumn(
    state = listState,
    contentPadding = PaddingValues(16.dp),
    verticalArrangement = Arrangement.spacedBy(8.dp)
) {
    items(
        items = posts,
        key = { it.id }
    ) { post ->
        PostCard(post)
    }
}
```

### Image Loading (Coil)
```kotlin
AsyncImage(
    model = ImageRequest.Builder(LocalContext.current)
        .data(imageUrl)
        .crossfade(true)
        .build(),
    contentDescription = null,
    modifier = Modifier.fillMaxSize(),
    contentScale = ContentScale.Crop,
    placeholder = painterResource(R.drawable.placeholder),
    error = painterResource(R.drawable.error)
)
```

### Remember Expensive Calculations
```kotlin
val formattedCount = remember(likeCount) {
    when {
        likeCount >= 1_000_000 -> "${likeCount / 1_000_000}M"
        likeCount >= 1_000 -> "${likeCount / 1_000}K"
        else -> likeCount.toString()
    }
}
```

---

## Platform-Specific Features

### Predictive Back Gesture
```kotlin
// Opt-in to predictive back
BackHandler(enabled = showSheet) {
    showSheet = false
}
```

### Edge Panels
```kotlin
// Support for Galaxy Edge panels
// Implement via Samsung SDK if needed
```

### App Widget
```kotlin
// Glance for Compose widgets
class PulsyncWidget : GlanceAppWidget() {
    @Composable
    override fun Content() {
        // Widget content
    }
}
```

### Foldable Support
```kotlin
// Detect fold state
val foldingFeature = LocalFoldingFeature.current

when (foldingFeature?.state) {
    FoldingFeature.State.HALF_OPENED -> {
        // Table-top mode
    }
    FoldingFeature.State.FLAT -> {
        // Fully open
    }
    else -> {
        // Normal
    }
}
```
