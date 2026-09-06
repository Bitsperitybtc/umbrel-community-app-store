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

### How umbrelOS updates this app

Two layers. Refreshing the community store only git-clones this repo (catalog). The installed app stays on the old compose and `umbrel-app.yml` until its **Update** button is used.

Umbrel shows **Update** when `version` in the catalog `umbrel-app.yml` differs from the copy in `app-data`. String inequality, not semver. Changing `icon.png` without bumping `version` does nothing on an already-installed app.

The desktop/store icon is the `icon:` HTTP URL, not the file in the clone. `raw.githubusercontent.com/.../master/...` is cached: after replacing `icon.png`, point `icon:` at the commit that contains the new PNG (not `master`).

Update copies only `docker-compose.yml` (then `umbrel-app.yml` after start). Same image pin → pull is a no-op; the running SPA does not change.

### Image pin

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`), not an architecture-specific blob:

```text
ghcr.io/bitsperitybtc/bitspark:sha-32593df@sha256:a8cc4e3fe797d9ccc80301caa44aeb953ee19c736d4887b445002ecfc9cc54e1
```

To ship a new SPA (Umbrel: community store refresh, then **Update** on BitSpark):

1. Publish `ghcr.io/bitsperitybtc/bitspark` (push `chore/open-source-readiness` / `main` / `v*`, or `workflow_dispatch`). Do not use `latest` in compose.
2. `docker buildx imagetools inspect ghcr.io/bitsperitybtc/bitspark:<tag>` — copy the **index** digest (`linux/amd64` + `linux/arm64`), not a blob digest.
3. Pin `image: ghcr.io/bitsperitybtc/bitspark:<tag>@sha256:<index-digest>`
4. Set `version` in `umbrel-app.yml` to that tag (must differ from the installed version)
5. Fill `releaseNotes`. If `icon.png` changed, set `icon:` to `.../<commit>/bitsperity-bitspark/icon.png`
6. Push this store repo

Listing-only (icon/copy, same container): bump `version` (e.g. `sha-32593df.1`), keep the image pin, cache-bust `icon:` if the PNG changed.

Do not use compose `build:`. `APP_PORT` stays `80`.

### Official App Store PR

Copy `bitsperity-bitspark/` to a `bitspark/` folder in a fork of [getumbrel/umbrel-apps](https://github.com/getumbrel/umbrel-apps):

- `id` and directory name become `bitspark`
- `APP_HOST` becomes `bitspark_web_1`
- Drop `icon:` — Umbrel hosts official icons
- Keep `gallery: []` in the package; attach screenshots and the logo in the PR body
- Fill `submission` with the umbrel-apps PR URL
- Run `npm run lint:apps -- bitspark --check-images`


## Nostr Signer

| | |
|---|---|
| Community app ID | `bitsperity-nostr-signer` |
| Official app ID (later) | `nostr-signer` |
| UI | `http://umbrel.local:8740` (Umbrel login) |
| Mailbox | `ws://umbrel.local:8741` (no Umbrel cookie) |
| Source | [Bitsperitybtc/nostr_signer](https://github.com/Bitsperitybtc/nostr_signer) |

Standalone NIP-46 remote signer. Holds identities on the node, approves clients
per identity, signs over a bundled kind-24133 mailbox. Any compliant NIP-46
client can pair.

### Image pin

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`), not an architecture-specific blob:

```text
ghcr.io/bitsperitybtc/nostr-signer:0.1.0@sha256:9640d2a79d268810628d7f02e4ee3f63538fca5bc519422e95f5c0418bbf50d9
```

To bump:

1. Tag `vX.Y.Z` on `nostr_signer` `main` (GHCR workflow publishes the image)
2. `docker buildx imagetools inspect ghcr.io/bitsperitybtc/nostr-signer:<tag>`
3. Pin `image: ghcr.io/bitsperitybtc/nostr-signer:<tag>@sha256:<index-digest>`
4. Set `version` in `umbrel-app.yml` to that tag

Do not use `latest` for the signer. Do not use compose `build:`. Keep the mailbox sidecar digest-pinned. After the first GHCR push, the package must be **public** or Umbrel cannot pull it.

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
bitsperity-nostr-signer/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + signer + mailbox relay
  relay-config.toml           Kind 24133 only
  icon.png                    512×512 square PNG, no rounded corners (umbrelOS masks)
```
