# Steam Air

Steam Air is an iOS companion app for Steam players. It lets users sign in with Steam, view their game library, browse store highlights, inspect game details, read Steam news and reviews, track wishlist prices, and explore historical price data in a mobile-friendly interface.

The project is built with UIKit and Storyboards, with most feature screens implemented programmatically for easier layout control and visual consistency.

## Features

- Steam login through `ASWebAuthenticationSession`
- Home page with featured store recommendations and latest game news
- Library page with owned games, search, and achievement progress
- Store page with featured deals, top sellers, new releases, and global Steam store search
- Wishlist page synced from the logged-in Steam account
- Game detail page with Steam links, native iOS sharing, review summary, and recent review list
- News detail page with latest Steam news entries and links to full articles
- Price history page with ITAD-backed Steam price history and a scrollable step chart
- Local image caching for game covers and icons
- Custom tab bar icons and app icon assets

## Tech Stack

- Swift
- UIKit
- Storyboard + programmatic Auto Layout
- `URLSession` for API requests
- `ASWebAuthenticationSession` for Steam authentication
- `WKWebView` for Steam wishlist session support
- SF Symbols for tab and interface icons
- Xcode asset catalogs for app icons and image assets

## Main Screens

- `LoginViewController`: Steam-only login flow and Steam account sign-up link
- `HomeViewController`: featured recommendations and update/news feed
- `LibraryViewController`: owned game library and achievement collection view
- `StoreViewController`: Steam store browsing and global search
- `WishlistViewController`: Steam wishlist items and deal list
- `DetailViewController`: game detail, Steam reviews, sharing, and price history entry
- `NewsDetailViewController`: game news list and external Steam news links
- `PriceHistoryViewController`: historical Steam pricing visualization

## Data Sources

The app combines several Steam and third-party data sources:

- Steam OpenID/backend login callback for account authentication
- Custom backend endpoint for owned games:
  - `http://18.136.66.102/owned-games`
- Steam Web API:
  - `IWishlistService/GetWishlist`
  - `ISteamUserStats/GetPlayerAchievements`
  - `ISteamNews/GetNewsForApp`
  - `ISteamUser/GetPlayerSummaries`
- Steam Store public endpoints:
  - `store.steampowered.com/api/featuredcategories`
  - `store.steampowered.com/api/storesearch`
  - `store.steampowered.com/api/appdetails`
  - `store.steampowered.com/appreviews`
- IsThereAnyDeal API:
  - `games/lookup/v1`
  - `games/history/v2`

## Configuration

Before running the app, configure these values in `Steam_Air/Info.plist`:

```xml
<key>SteamWebAPIKey</key>
<string>YOUR_STEAM_WEB_API_KEY</string>

<key>ITADAPIKey</key>
<string>YOUR_ITAD_API_KEY</string>
```

The app also uses a custom URL scheme for Steam login callbacks:

```xml
<string>steamair</string>
```

During development, the project includes an ATS exception for the backend IP address because the backend currently uses HTTP. For production, the backend should be moved to HTTPS and the ATS exception should be removed.

## How to Run

1. Open `Steam_Air.xcodeproj` in Xcode.
2. Select the `Steam_Air` target.
3. Update `Signing & Capabilities` with your Apple Developer team.
4. Add valid `SteamWebAPIKey` and `ITADAPIKey` values in `Info.plist`.
5. Build and run on the iOS Simulator or a trusted iPhone device.

If running on a physical iPhone, make sure Developer Mode is enabled and the signing certificate is available in your local keychain.

## Project Structure

```text
Steam_Air/
├── Login_Page/        # Steam login and login UI
├── Main_Page/         # Home, detail, and news screens
├── Library_Page/      # Library and achievement screens
├── Store_Page/        # Store browsing and search
├── Wishlist_Page/     # Wishlist, deals, notifications, and price history
├── Network/           # API models and fetchers
├── Models/            # Shared data models
├── Services/          # Auth, cache, and local wishlist helpers
├── UI/                # Reusable UI components
└── Assets.xcassets/   # App icons, Steam icon, and app assets
```

## Notes

- Some Steam data depends on the user's privacy settings. Private profiles or private wishlists may return empty or partial results. So, your steam privacy setting should be public if you want to access the full function of this app.
- Some games do not expose achievements, review data, or public price data.
- Price history is provided by IsThereAnyDeal, not by Steam directly.
- Wishlist prices are resolved by fetching app IDs from the Steam wishlist API and then requesting Steam Store app details for each app.
- The current backend IP is configured for development use and should be replaced with a production HTTPS endpoint before release.


