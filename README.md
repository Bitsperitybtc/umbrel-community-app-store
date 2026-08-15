# Bitsperity App Store

Community app store for umbrelOS. Add this repository URL in umbrelOS: **App Store → Community App Stores**.

Apps in this store use the `bitsperity-` ID prefix. That prefix is required by umbrelOS for community listings. The official Umbrel App Store package will use `bitspark` with the same compose shape.

## BitSpark

| | |
|---|---|
| Community app ID | `bitsperity-bitspark` |
| Official app ID (later) | `bitspark` |
| Host URL | `http://umbrel.local:3847` |
| Source | [Bitsperitybtc/bitspark_btc](https://github.com/Bitsperitybtc/bitspark_btc) |

BitSpark is a static Nostr client. The container serves the production SPA. Sign-in is NIP-46. Lightning is NWC in Settings. Umbrel login is not wrapped in front of the app.

### Image pin

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`), not an architecture-specific blob:

```text
ghcr.io/bitsperitybtc/bitspark:sha-32593df@sha256:a8cc4e3fe797d9ccc80301caa44aeb953ee19c736d4887b445002ecfc9cc54e1
```

To bump:

1. `docker buildx imagetools inspect ghcr.io/bitsperitybtc/bitspark:<tag>`
2. Pin `image: ghcr.io/bitsperitybtc/bitspark:<tag>@sha256:<index-digest>`
3. Set `version` in `umbrel-app.yml` to that tag

Do not use `latest`. Do not use compose `build:`. `APP_PORT` stays `80`.

### Official App Store PR

Copy `bitsperity-bitspark/` to a `bitspark/` folder in a fork of [getumbrel/umbrel-apps](https://github.com/getumbrel/umbrel-apps):

- `id` and directory name become `bitspark`
- `APP_HOST` becomes `bitspark_web_1`
- Drop `icon:` — Umbrel hosts official icons
- Keep `gallery: []` in the package; attach screenshots and the logo in the PR body
- Fill `submission` with the umbrel-apps PR URL
- Run `npm run lint:apps -- bitspark --check-images`

## Layout

```text
umbrel-app-store.yml          Store id + display name
bitsperity-bitspark/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + web image
  icon.png                    512×512 square PNG, no rounded corners (umbrelOS masks)
  gallery/1.png               Landing
  gallery/2.png               Ideas
  gallery/3.png               Job detail
```
