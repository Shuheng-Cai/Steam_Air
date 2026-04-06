# Steam_Air — Project Memory

> Last updated by Claude Code · 2026-04-05

---

## 1. Project Overview

**Steam_Air** is an iOS app (UIKit + Storyboard, MVC) that connects to the Steam Web API and lets a user browse their Steam library, view game news, see achievements, and (eventually) browse the Steam Store and Wishlist.

- **Language**: Swift 6 / Xcode 16
- **UI Framework**: UIKit (Storyboard + programmatic views)
- **Architecture**: MVC
- **Min target**: iOS 18+ (uses `UIActivityIndicatorView(style: .medium)`, system colors, etc.)
- **SDK**: iOS 26 SDK (as of session date — `UIScreen.main` is deprecated, use `UIScreen.screens` or view bounds)

---

## 2. Hardcoded Credentials (Dev Only)

```
Steam API Key : CD89B4D216CF0A68E8970744826761AF
Steam ID      : 76561198803168956
```

These appear in `GameFetch.swift`, `NewsFetch.swift`, and `AchievementFetch.swift`.
**Do not commit to a public repo without moving to a config file / env var.**

---

## 3. Entry Point

`SceneDelegate.swift` loads `HomePageScreen.storyboard` and sets its initial view controller (a `UITabBarController`) as the window root.

`Main.storyboard` and `ViewController.swift` are legacy / unused.

---

## 4. File Structure

```
Steam_Air/
├── AppDelegate.swift
├── SceneDelegate.swift               ← loads HomePageScreen storyboard
├── ViewController.swift              ← UNUSED legacy file
│
├── HomePageScreen.storyboard         ← master storyboard; all scenes live here
│     TabBarController  (id: O0v-fI-HZt, storyboardID: "HomePageScreen")
│       ├── HomeNavigationController  (REa-6h-EcH)  → HomeViewController
│       ├── LibraryNavigationController (LIB-nc-v01) → LibraryViewController
│       ├── StoreNavigationController   (STR-nc-v01) → StoreViewController
│       └── WishlistNavigationController(WSH-nc-v01) → WishlistViewController
│     DetailViewController            (id: XEW-Ke-9om, storyboardID: "DetailViewController")
│
├── Data/
│   ├── Game.swift                    ← Model: Game struct
│   ├── GameAPI.swift                 ← DTO: OwnedGamesResponse / GameDTO / toGame()
│   ├── GameFetch.swift               ← Network: fetchGame class
│   ├── News.swift                    ← Model: News struct
│   ├── NewsAPI.swift                 ← DTO: NewsResponse / NewsDTO / toNews()
│   ├── NewsFetch.swift               ← Network: fetchNews class
│   ├── Achievement.swift             ← Model: Achievement + GameAchievements
│   ├── AchievementAPI.swift          ← DTO: PlayerAchievementsResponse / AchievementDTO
│   ├── AchievementFetch.swift        ← Network: AchievementFetch class
│   └── Cache.swift                   ← GameImageCache (NSCache singleton)
│
├── UI/
│   ├── CustomTabBar.swift            ← Transparent tab bar; text-only tabs (no icons)
│   ├── CardView.swift                ← UIView with corner radius + border
│   ├── CardImageView.swift           ← UIImageView with corner radius + border
│   ├── GameCell.swift                ← IBOutlet cell for Home recommended grid
│   └── NewsCell.swift                ← IBOutlet cell for Home news list
│
├── Main_Page/
│   ├── HomeViewController.swift      ← Home tab: recommended games + news
│   └── DetailViewController.swift   ← Game detail (poster, title, playtime, buttons)
│
├── Library_Page/
│   ├── LibraryViewController.swift   ← Library tab controller (programmatic UI)
│   ├── LibraryGameCell.swift         ← 2-column collection cell (cover 2:3 + name + status)
│   ├── CollectionsGameCell.swift     ← Table cell (cover + name + achievement progress bar)
│   └── GameAchievementsViewController.swift ← Achievement detail (unlocked/locked sections)
│
├── Store_Page/
│   └── StoreViewController.swift    ← Placeholder "Coming Soon"
│
└── Wishlist_Page/
    └── WishlistViewController.swift ← Placeholder "Coming Soon"
```

---

## 5. Data Models

### Game
```swift
struct Game {
    let appid: Int
    let name: String
    let playtime_forever: Int   // minutes
    let playtime_2weeks: Int    // minutes (recent)
    var iconURL: String         // https://cdn.cloudflare.steamstatic.com/steam/apps/{appid}/library_600x900.jpg
    let lastPlayedDate: Date?   // from rtime_last_played (Unix timestamp)
}
```

### News
```swift
struct News: Codable {
    let title: String
    let content: String
    let iconURL: String   // same library_600x900.jpg pattern
    let url: String
}
```

### Achievement / GameAchievements
```swift
struct Achievement {
    let apiName: String
    let name: String
    let description: String
    let achieved: Bool
    let unlockTime: Date?
}

struct GameAchievements {
    let appid: Int
    let gameName: String
    let achievements: [Achievement]
    // computed: unlockedCount, totalCount, progress: Float
}
```

---

## 6. Steam Web APIs Used

| API | Endpoint | Used in |
|-----|----------|---------|
| GetOwnedGames | `IPlayerService/GetOwnedGames/v0001/` | `GameFetch.swift` |
| GetNewsForApp | `ISteamNews/GetNewsForApp/v0002/` | `NewsFetch.swift` |
| GetPlayerAchievements | `ISteamUserStats/GetPlayerAchievements/v0001/` | `AchievementFetch.swift` |

All network callbacks dispatch decode + completion on `DispatchQueue.main` to satisfy Swift 6 actor-isolation rules.

---

## 7. Image Loading

`GameImageCache` (in `Cache.swift`) is the project-wide image cache:
```swift
GameImageCache.loadImage(from: urlString, into: imageView)
```
- Backed by `NSCache<NSString, UIImage>`
- Used everywhere: Home cells, Library cells, Collections cells

Cover image URL pattern:
```
https://cdn.cloudflare.steamstatic.com/steam/apps/{appid}/library_600x900.jpg
```

---

## 8. Tab Bar

`CustomTabBar` (`UI/CustomTabBar.swift`):
- Transparent background
- **No icons** (iconColor = .clear)
- Text only: gray (normal) / blue (selected)
- 4 tabs: **Home · Library · Store · Wishlist**

Tab bar items set via storyboard `tabBarItem` elements (title only).

---

## 9. Library Page Detail

`LibraryViewController` is fully programmatic (no storyboard UI). Layout:

```
SafeArea top
  UISearchBar          ← filters both Library and Collections
  UISegmentedControl   ← "Library" | "Collections"
  UILabel              ← "N games"
  UICollectionView     ← Library mode: 2-column grid (hidden in Collections)
  UITableView          ← Collections mode: achievement list (hidden in Library)
```

**Library mode**: 2-column `UICollectionView` with `UICollectionViewDelegateFlowLayout` for cell sizing (avoids deprecated `UIScreen.main`). Cells show portrait 2:3 cover + name + "Last played X ago" / "N hrs played".

**Collections mode**: `UITableView` with lazy achievement loading. Each game triggers `AchievementFetch` on first appearance; result cached in `achievementsStates: [Int: AchievementLoadState]`. Tapping a game pushes `GameAchievementsViewController`.

Sorting options (via "…" button): Recently Played / Name / Most Played.

---

## 10. Achievement Detail Page

`GameAchievementsViewController`:
- Two `insetGrouped` table sections: **Unlocked** (sorted by unlock date desc) | **Locked**
- Navigation title updates to "X/Y (N%)" after load
- Icons: ⭐ (systemYellow) = unlocked, 🔒 (systemGray3) = locked
- `AchievementRowCell` is `private` to the file

---

## 11. Known Issues / TODOs

- [ ] `Store_Page` and `Wishlist_Page` are placeholders — not yet implemented
- [ ] API key + Steam ID are hardcoded — should move to config / Keychain
- [ ] `ViewController.swift` is unused legacy file — can be deleted
- [ ] `HomeViewController` fetches news for EVERY owned game on load — could be slow with large libraries; consider limiting to top N games
- [ ] Achievement icons are SF Symbols (⭐/🔒) — real icons require `GetSchemaForGame` API call per game
- [ ] No offline / error state UI on Home or Library pages
- [ ] Search bar in Library doesn't show cancel button — consider `showsCancelButton = true`

---

## 12. Coding Conventions

- Swift 6 concurrency: all `URLSession` completions wrapped in `DispatchQueue.main.async` before decode
- `UIActivityIndicatorView` style: `.medium` (not `.small` — doesn't exist)
- TableView dequeue: `dequeueReusableCell(withIdentifier:for:)` (not `withReuseIdentifier` — that's CollectionView)
- New pages follow folder naming: `{PageName}_Page/`
- Storyboard scene IDs for new scenes use format `XXX-sc-v01` / `XXX-nc-v01` / etc.
- `GameImageCache.loadImage(from:into:)` for all image loading — do NOT create additional caches
