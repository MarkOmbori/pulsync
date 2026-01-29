# Design: Windows Platform Adaptations

## Summary

Platform-specific design guidelines for Pulsync on Windows, following Fluent Design System principles and WinUI 3 patterns.

---

## Platform Characteristics

- Mouse and keyboard primary input
- Touch support (tablets, 2-in-1s)
- Window management (resize, snap, multiple windows)
- System accent color integration
- Taskbar and Start menu integration
- Light/dark mode system setting

---

## Typography

### Font Stack
```xaml
<!-- Segoe UI Variable (Windows 11) -->
<FontFamily x:Key="ContentControlThemeFontFamily">Segoe UI Variable</FontFamily>

<!-- Fallback for Windows 10 -->
<FontFamily x:Key="FallbackFontFamily">Segoe UI</FontFamily>
```

### Type Mapping

| Design Token | WinUI 3 | Size |
|--------------|---------|------|
| Display | DisplayTextBlockStyle | 68px |
| Headline | TitleLargeTextBlockStyle | 40px |
| Title 1 | TitleTextBlockStyle | 28px |
| Title 2 | SubtitleTextBlockStyle | 20px |
| Body Large | BodyStrongTextBlockStyle | 14px bold |
| Body | BodyTextBlockStyle | 14px |
| Label | CaptionTextBlockStyle | 12px |
| Caption | CaptionTextBlockStyle | 12px |

---

## Colors

### System Integration
```csharp
// Get system accent color
var accentColor = (Color)Application.Current.Resources["SystemAccentColor"];

// Get system theme
var theme = Application.Current.RequestedTheme;
```

### Color Resources
```xaml
<ResourceDictionary>
    <!-- Primary Colors -->
    <Color x:Key="PulsyncPrimary">#6366F1</Color>
    <Color x:Key="PulsyncPrimaryLight">#818CF8</Color>
    <Color x:Key="PulsyncPrimaryDark">#4F46E5</Color>

    <!-- Surfaces -->
    <Color x:Key="PulsyncBackgroundLight">#FFFFFF</Color>
    <Color x:Key="PulsyncBackgroundDark">#0A0A0B</Color>
    <Color x:Key="PulsyncSurfaceLight">#F8F9FA</Color>
    <Color x:Key="PulsyncSurfaceDark">#141416</Color>

    <!-- Semantic -->
    <Color x:Key="PulsyncLike">#EF4444</Color>
    <Color x:Key="PulsyncFollow">#3B82F6</Color>
    <Color x:Key="PulsyncSuccess">#22C55E</Color>
    <Color x:Key="PulsyncError">#EF4444</Color>
</ResourceDictionary>
```

### Brushes with Light/Dark Support
```xaml
<SolidColorBrush x:Key="PulsyncBackgroundBrush"
                 Color="{ThemeResource PulsyncBackgroundColor}"/>
```

---

## Materials

### Mica
```xaml
<!-- Window background with Mica -->
<Window ...>
    <Window.SystemBackdrop>
        <MicaBackdrop/>
    </Window.SystemBackdrop>
</Window>
```

### Acrylic
```xaml
<!-- In-app acrylic for elevated surfaces -->
<Grid>
    <Grid.Background>
        <AcrylicBrush TintColor="{ThemeResource SystemAltHighColor}"
                      TintOpacity="0.8"
                      BackgroundSource="Backdrop"/>
    </Grid.Background>
</Grid>
```

### Reveal Effects (Windows 10)
```xaml
<Button Style="{StaticResource ButtonRevealStyle}"/>
```

---

## Icons

### Fluent UI Icons

| Action | Icon Name | Filled Variant |
|--------|-----------|----------------|
| Home | Home | HomeFilled |
| Discover | Compass | CompassFilled |
| Define | Target | TargetFilled |
| Deliver | CheckmarkCircle | CheckmarkCircleFilled |
| Like | Heart | HeartFilled |
| Comment | Comment | CommentFilled |
| Share | Share | - |
| Bookmark | Bookmark | BookmarkFilled |
| Profile | Person | PersonFilled |
| Settings | Settings | SettingsFilled |
| Search | Search | - |
| Close | Dismiss | - |

### Icon Implementation
```xaml
<FontIcon FontFamily="{StaticResource SymbolThemeFontFamily}"
          Glyph="&#xE80F;"/>

<!-- Or with Fluent Icons package -->
<local:FluentIcon Icon="Heart24Regular"/>
```

---

## Components

### NavigationView (Sidebar)
```xaml
<NavigationView PaneDisplayMode="Left"
                IsBackButtonVisible="Auto"
                IsSettingsVisible="True">
    <NavigationView.MenuItems>
        <NavigationViewItem Icon="Home" Content="Home" Tag="home"/>
        <NavigationViewItem Icon="Compass" Content="Discover" Tag="discover"/>
        <NavigationViewItem Icon="Target" Content="Define" Tag="define"/>
        <NavigationViewItem Icon="CheckmarkCircle" Content="Deliver" Tag="deliver"/>
    </NavigationView.MenuItems>

    <Frame x:Name="ContentFrame"/>
</NavigationView>
```

### TabView
```xaml
<TabView TabWidthMode="SizeToContent"
         IsAddTabButtonVisible="False"
         CloseButtonOverlayMode="OnPointerOver">
    <TabViewItem Header="For You"/>
    <TabViewItem Header="Following"/>
</TabView>
```

### ContentDialog (Modals)
```xaml
<ContentDialog x:Name="CommentsDialog"
               Title="Comments"
               PrimaryButtonText="Close"
               DefaultButton="Primary">
    <ScrollViewer>
        <!-- Comments list -->
    </ScrollViewer>
</ContentDialog>
```

### TeachingTip (Tooltips)
```xaml
<TeachingTip x:Name="LikeTip"
             Target="{x:Bind LikeButton}"
             Title="Double-click to like"
             Subtitle="You can also press L on your keyboard">
</TeachingTip>
```

---

## Buttons

### Standard Button
```xaml
<Button Content="Follow"
        Style="{StaticResource AccentButtonStyle}"
        CornerRadius="20"/>
```

### Icon Button
```xaml
<Button Style="{StaticResource IconButtonStyle}"
        ToolTipService.ToolTip="Like"
        AutomationProperties.Name="Like">
    <FontIcon Glyph="&#xE80F;" FontSize="20"/>
</Button>
```

### Toggle Button (Follow/Following)
```xaml
<ToggleButton x:Name="FollowToggle"
              IsChecked="{x:Bind IsFollowing, Mode=TwoWay}"
              Content="{x:Bind IsFollowing ? 'Following' : 'Follow'}"
              CornerRadius="20"/>
```

---

## Animations

### Implicit Animations
```csharp
// Enable implicit animations on elements
ElementCompositionPreview.SetIsTranslationEnabled(element, true);

// Create spring animation
var compositor = Window.Current.Compositor;
var springAnimation = compositor.CreateSpringScalarAnimation();
springAnimation.Period = TimeSpan.FromMilliseconds(50);
springAnimation.DampingRatio = 0.6f;
```

### Connected Animations
```csharp
// Source page
ConnectedAnimationService.GetForCurrentView()
    .PrepareToAnimate("PostImage", PostImage);

// Destination page
var animation = ConnectedAnimationService.GetForCurrentView()
    .GetAnimation("PostImage");
animation?.TryStart(DestinationImage);
```

### Storyboard Animations
```xaml
<Storyboard x:Name="LikeAnimation">
    <DoubleAnimationUsingKeyFrames Storyboard.TargetName="HeartIcon"
                                    Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)">
        <EasingDoubleKeyFrame KeyTime="0:0:0" Value="1"/>
        <EasingDoubleKeyFrame KeyTime="0:0:0.15" Value="1.3">
            <EasingDoubleKeyFrame.EasingFunction>
                <BackEase EasingMode="EaseOut"/>
            </EasingDoubleKeyFrame.EasingFunction>
        </EasingDoubleKeyFrame>
        <EasingDoubleKeyFrame KeyTime="0:0:0.4" Value="1">
            <EasingDoubleKeyFrame.EasingFunction>
                <BounceEase Bounces="2" Bounciness="2"/>
            </EasingDoubleKeyFrame.EasingFunction>
        </EasingDoubleKeyFrame>
    </DoubleAnimationUsingKeyFrames>
</Storyboard>
```

---

## Keyboard Navigation

### Access Keys
```xaml
<Button Content="Follow" AccessKey="F"/>
<Button Content="Like" AccessKey="L"/>
```

### Keyboard Shortcuts
```csharp
// Register keyboard accelerators
var likeAccelerator = new KeyboardAccelerator
{
    Key = VirtualKey.L,
    Modifiers = VirtualKeyModifiers.Control
};
likeAccelerator.Invoked += LikeAccelerator_Invoked;
KeyboardAccelerators.Add(likeAccelerator);
```

### Focus Management
```xaml
<Control IsTabStop="True"
         TabIndex="1"
         FocusVisualPrimaryBrush="{ThemeResource SystemAccentColor}"
         UseSystemFocusVisuals="True"/>
```

---

## Layout

### Adaptive Triggers
```xaml
<VisualStateManager.VisualStateGroups>
    <VisualStateGroup>
        <VisualState x:Name="Wide">
            <VisualState.StateTriggers>
                <AdaptiveTrigger MinWindowWidth="1200"/>
            </VisualState.StateTriggers>
            <VisualState.Setters>
                <Setter Target="NavigationView.PaneDisplayMode" Value="Left"/>
            </VisualState.Setters>
        </VisualState>
        <VisualState x:Name="Medium">
            <VisualState.StateTriggers>
                <AdaptiveTrigger MinWindowWidth="800"/>
            </VisualState.StateTriggers>
            <VisualState.Setters>
                <Setter Target="NavigationView.PaneDisplayMode" Value="LeftCompact"/>
            </VisualState.Setters>
        </VisualState>
        <VisualState x:Name="Narrow">
            <VisualState.StateTriggers>
                <AdaptiveTrigger MinWindowWidth="0"/>
            </VisualState.StateTriggers>
            <VisualState.Setters>
                <Setter Target="NavigationView.PaneDisplayMode" Value="LeftMinimal"/>
            </VisualState.Setters>
        </VisualState>
    </VisualStateGroup>
</VisualStateManager.VisualStateGroups>
```

### Window Management
```csharp
// Get app window
var appWindow = GetAppWindowForCurrentWindow();

// Set title bar
appWindow.Title = "Pulsync";

// Set minimum size
appWindow.SetPresenter(AppWindowPresenterKind.Overlapped);
var presenter = appWindow.Presenter as OverlappedPresenter;
presenter.SetBorderAndTitleBar(true, true);
```

### Title Bar Customization
```csharp
// Extend content into title bar
var titleBar = AppWindow.TitleBar;
titleBar.ExtendsContentIntoTitleBar = true;
titleBar.ButtonBackgroundColor = Colors.Transparent;
titleBar.ButtonInactiveBackgroundColor = Colors.Transparent;
```

---

## Accessibility

### UI Automation
```xaml
<Button AutomationProperties.Name="Like this post"
        AutomationProperties.HelpText="Press to like or unlike this post"
        AutomationProperties.LiveSetting="Polite"/>
```

### High Contrast
```xaml
<Style TargetType="Button">
    <Setter Property="Foreground" Value="{ThemeResource ButtonForegroundThemeBrush}"/>
</Style>

<!-- High contrast resources are automatic with theme resources -->
```

### Screen Reader
```csharp
// Announce changes
AutomationPeer.RaiseAutomationEvent(AutomationEvents.LiveRegionChanged);
```

---

## Platform-Specific Features

### Jump Lists
```csharp
var jumpList = await JumpList.LoadCurrentAsync();
jumpList.Items.Clear();

var item = JumpListItem.CreateWithArguments("feed", "Open Feed");
item.GroupName = "Quick Access";
jumpList.Items.Add(item);

await jumpList.SaveAsync();
```

### Toast Notifications
```csharp
var toastContent = new ToastContentBuilder()
    .AddText("New post from @username")
    .AddText("Check out the latest update...")
    .AddButton(new ToastButton()
        .SetContent("View")
        .AddArgument("action", "view"))
    .Build();

ToastNotificationManager.CreateToastNotifier().Show(
    new ToastNotification(toastContent.GetXml()));
```

### Live Tiles
```csharp
var tileContent = new TileContent()
{
    Visual = new TileVisual()
    {
        TileMedium = new TileBinding() { /* ... */ },
        TileWide = new TileBinding() { /* ... */ },
        TileLarge = new TileBinding() { /* ... */ }
    }
};

TileUpdateManager.CreateTileUpdaterForApplication()
    .Update(new TileNotification(tileContent.GetXml()));
```

### Share Contract
```csharp
DataTransferManager.GetForCurrentView().DataRequested += (s, e) =>
{
    e.Request.Data.SetText(postContent);
    e.Request.Data.SetWebLink(new Uri(postUrl));
    e.Request.Data.Properties.Title = "Share post";
};
```

---

## Performance

### ListView Virtualization
```xaml
<ListView ItemsSource="{x:Bind Posts}"
          VirtualizingStackPanel.VirtualizationMode="Recycling"
          SelectionMode="None"
          IsItemClickEnabled="True">
    <ListView.ItemsPanel>
        <ItemsPanelTemplate>
            <ItemsStackPanel/>
        </ItemsPanelTemplate>
    </ListView.ItemsPanel>
</ListView>
```

### Image Caching
```csharp
// Use Windows Community Toolkit ImageCache
var image = await ImageCache.Instance.GetFromCacheAsync(new Uri(imageUrl));
```

### Deferred Loading
```xaml
<Grid x:DeferLoadStrategy="Lazy"
      x:Load="{x:Bind ShowAdvancedOptions}">
    <!-- Heavy content -->
</Grid>
```
