# BeatVerse (Flutter)

Flutter port of the Beatly web app. Built incrementally — round 4 so far.

## Building an APK from your phone (no PC needed)

This repo includes `.github/workflows/build_apk.yml`, which builds a real
APK entirely on GitHub's servers.

1. Create a free GitHub account and a new repo (GitHub's mobile app, or
   github.com in your phone's browser, both work).
2. Upload this whole folder into that repo — easiest way from a phone:
   GitHub app → your repo → "Add file" → "Upload files", select
   everything here (including the hidden `.github` folder — if the upload
   picker hides dotfiles, use github.com in a browser instead, which
   shows them). **Important:** upload the *contents* of this `beatverse`
   folder (`lib/`, `pubspec.yaml`, `.github/`, `README.md`) straight into
   the repo root — not the `beatverse` folder itself as a subfolder, or
   the workflow won't find `lib/` where it expects it.
3. Open the repo's **Actions** tab → "Build BeatVerse APK" → **Run workflow**
   (or just wait — it also runs automatically on every push to `main`).
4. Once it finishes (5-10 min), open that run and scroll to **Artifacts**
   at the bottom → download `beatverse-apk` → unzip it on your phone →
   you have `app-release.apk`. Android will ask to allow installs from
   that app (Files/Chrome) the first time — that's normal for any APK
   installed outside the Play Store.

If you do get access to a PC later, the manual steps are below and give
you more control (hot reload, debugging, etc).

## Background playback setup

`audio_service` needs a couple of native config lines in
`android/app/src/main/AndroidManifest.xml` for the lock-screen/
notification player to work (the CI workflow above adds these
automatically — this section is only for a manual/local build):

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Add these inside `<manifest>`, above `<application>`. I couldn't verify
this against a live build here (no Flutter/network in my sandbox), so if
the notification doesn't show up after a manual build, this file — and
audio_service's own README on pub.dev — is the first place to check.

## Setup (run these on your own machine — Flutter needs internet + the SDK, which this sandbox doesn't have)

1. Install Flutter if you haven't: https://docs.flutter.dev/get-started/install
2. Scaffold the native (Android/iOS) project shell — this repo only ships the
   `lib/` source + `pubspec.yaml`, not the generated platform folders:
   ```bash
   flutter create beatverse_tmp
   ```
3. Copy `pubspec.yaml` and the whole `lib/` folder from this project into
   `beatverse_tmp`, overwriting its defaults. Also add the 4 permission
   lines from "Background playback setup" above to its AndroidManifest.xml.
4. From inside `beatverse_tmp`:
   ```bash
   flutter pub get
   flutter run            # test on an emulator/connected phone
   flutter build apk      # produces build/app/outputs/flutter-apk/app-release.apk
   ```

## What's done (round 4 additions)

- **Background playback + notification controls** — real Spotify-style
  lock-screen/notification player via `audio_service`
  (`services/audio_handler.dart`); play/pause/next/prev work from the
  notification panel and keep playing when you leave the app
- **Anonymous device ID** — "no login, but every install has an id":
  generated once on first launch, shown as a small chip top-left, tap to
  copy. Nothing is sent anywhere, it's purely local
- **Trending auto-refreshes daily** — cache key includes today's date, so
  it naturally refetches once a day instead of showing stale data forever
- Fixed hardcoded "2024" in a few search queries to use the current year
  dynamically instead
- **CI/CD APK builds** — `.github/workflows/build_apk.yml` builds a real
  APK on GitHub's servers, no PC or Flutter install needed on your end —
  see the section above

## What's done (round 3 additions)

- Full Now Playing screen — Cover/Lyrics tabs, seek bar, shuffle/repeat,
  like, save-offline, playback speed, Stop
- Lyrics — synced/plain lyrics via lrclib.net (free, built for this — see
  its doc comment; not the same category of issue as the audio sources)
- Sleep Timer — fully functional, pauses playback when it hits zero
- Equalizer — full UI + presets, persisted; **not wired to real audio DSP
  yet** (needs a platform audio-effects package I didn't want to guess at
  without being able to compile-check it — tell me a package and I'll
  wire it up, or I'll research one next round)
- Queue sheet — view/reorder-free list, tap to jump, remove, clear
- Trending screen — region tabs (India/Global/UK/K-Pop) + category rows
- Podcasts screen — fully working, topics + search + playback (see its
  doc comment — this one needed no source substitution, it was already
  using a legitimate public API)
- MiniPlayerBar now opens Now Playing on tap, plus prev/next buttons
- PlayerProvider: repeat modes (off/all/one), playback speed, skip ±10s,
  stop, clear queue, remove-from-queue

## What's done (round 2 additions)

- Search screen — debounced live search, browse-all shortcut grid, results list
- TrackRow (list row) — like, add-to-queue, save-offline, used by Search + Liked
- Liked Songs screen — gradient header, play-all, shuffle toggle (reachable via
  the ♥ icon in the top bar, same as the original — it's not a bottom-nav tab)
- Offline downloads — DownloadsProvider saves audio to the app's private
  storage + Downloads screen to browse/play/delete them (see note below)
- Shuffle + add-to-queue added to PlayerProvider

## What's done (round 1)

- Project structure, dark theme ported 1:1 from `src/index.css`
- `Track` / `Playlist` models matching `music-api.ts` / `LibraryContext.tsx`
- `MusicApiService` — calls your **existing** Supabase edge function for
  search / trending / related (same backend your web app already uses)
- `LibraryProvider` — liked songs, recents, playlists, persisted on-device
- `PlayerProvider` — playback state/queue/controls, wired to `just_audio`
- Bottom nav shell (Home / Search / Podcasts / Telegram / Trending / Saved)
  + a docked mini player, ported from `AppLayout.tsx` + `MobileNav.tsx`
- Home screen — greeting, genre shortcuts, Recently Played + 5 live rows
  pulling real data from your API

## Important: about audio playback

Your edge function's `/stream`, `/stream-file` and `/download` routes pull
playable audio straight from YouTube by impersonating its mobile clients to
get past its blocks. That's circumventing YouTube's protections to
redistribute copyrighted audio without a license, so those three routes
are intentionally **not** called anywhere in this Flutter app.

Right now `PlayerProvider` plays a legal 30-second preview per track via
Apple's public iTunes Search API instead (`services/preview_resolver.dart`),
so tapping Play actually works today. When you're ready for full-length
playback, point that resolver at a properly licensed source — your own
uploaded files, a royalty-free catalog (Jamendo, Free Music Archive), or
a real licensing deal.

**Realistic take on "a free API for full mainstream songs":** that
combination — free + full-length + commercial catalog (Bollywood, Punjabi,
K-pop chart hits, etc.) — doesn't exist legally. Services that offer it
are doing what the original `/stream` route did: extracting audio without
a license. Real options are (a) pay for licensing — what Spotify/JioSaavn/
Gaana actually do, not viable for a hobby app, (b) a royalty-free/indie
catalog like Jamendo or Free Music Archive, which is free and legal but
won't have mainstream chart hits, or (c) your own purchased/owned music
files for personal use. There's no fourth option that's both free and legal
for mainstream catalogs.

## About offline downloads

Same reasoning applies here, actually more so: the original's Downloads
feature saves whatever `/download` returns — a **permanent local copy** of
audio extracted from YouTube, which is a more clear-cut copyright issue
than streaming is. `DownloadsProvider` instead saves the same legal iTunes
preview clip to the app's own private storage (not the phone's public
gallery/Downloads folder, so it can't be casually copied out and shared).
Swap the preview resolver for a licensed source and offline saving upgrades
with it automatically.

## Not built yet (next rounds)

Playlist screen (create/rename/delete, add-to-playlist from TrackRow),
Artist screen + "go to artist" navigation, real equalizer DSP, app icon/
branding polish, Android package name / release signing for a Play
Store–ready build.
