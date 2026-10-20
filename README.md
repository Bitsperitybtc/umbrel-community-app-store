# Bitsperity App Store

Community app store for umbrelOS. Add this repository URL in umbrelOS: **App Store → Community App Stores**.

Apps in this store use the `bitsperity-` ID prefix. That prefix is required by umbrelOS for community listings. The official Umbrel App Store package will use `horizon` with the same compose shape.

## bitsperity Horizon

| | |
|---|---|
| Community app ID | `bitsperity-horizon` |
| Official app ID (later) | `horizon` |
| Host URL | `http://umbrel.local:3847` |
| Source | [Bitsperitybtc/horizon](https://github.com/Bitsperitybtc/horizon) |

bitsperity Horizon is a static Nostr client. The container serves the production SPA. Sign-in is NIP-46. Lightning is NWC in Settings. Umbrel login is not wrapped in front of the app.

The container image is `ghcr.io/bitsperitybtc/horizon`. The package is still private; Umbrel can pull it after the owner makes it public. The community app id and display name do not alias the previous listing.

### How umbrelOS updates this app

Two layers. Refreshing the community store only git-clones this repo (catalog). The installed app stays on the old compose and `umbrel-app.yml` until its **Update** button is used.

Umbrel shows **Update** when `version` in the catalog `umbrel-app.yml` differs from the copy in `app-data`. String inequality, not semver. Changing `icon.png` without bumping `version` does nothing on an already-installed app.

The desktop/store icon is the `icon:` HTTP URL, not the file in the clone. `raw.githubusercontent.com/.../master/...` is cached: after replacing `icon.png`, point `icon:` at the commit that contains the new PNG (not `master`).

Update copies only `docker-compose.yml` (then `umbrel-app.yml` after start). Same image pin → pull is a no-op; the running SPA does not change.

### Image pin

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`), not an architecture-specific blob:

```text
ghcr.io/bitsperitybtc/horizon:0.0.1@sha256:42cd0b317612e30bdd1ffc1be5b78e165c8ef578b5ea6717cb61386e136df281
```

To ship a new SPA (Umbrel: community store refresh, then **Update** on bitsperity Horizon):

1. Publish `ghcr.io/bitsperitybtc/horizon` (push `main` / `v*`, or `workflow_dispatch`). Do not use `latest` in compose. The package must be public or Umbrel cannot pull it.
2. `docker buildx imagetools inspect ghcr.io/bitsperitybtc/horizon:<tag>` — copy the **index** digest (`linux/amd64` + `linux/arm64`), not a blob digest.
3. Pin `image: ghcr.io/bitsperitybtc/horizon:<tag>@sha256:<index-digest>`
4. Set `version` in `umbrel-app.yml` to that tag (must differ from the installed version)
5. Fill `releaseNotes`. If `icon.png` changed, set `icon:` to `.../<commit>/bitsperity-horizon/icon.png`
6. Push this store repo

Listing-only (icon/copy, same container): bump `version` (e.g. `sha-32593df.1`), keep the image pin, cache-bust `icon:` if the PNG changed.

Do not use compose `build:`. `APP_PORT` stays `80`.

### Official App Store PR

Copy `bitsperity-horizon/` to a `horizon/` folder in a fork of [getumbrel/umbrel-apps](https://github.com/getumbrel/umbrel-apps):

- `id` and directory name become `horizon`
- `APP_HOST` becomes `horizon_web_1`
- Drop `icon:` — Umbrel hosts official icons
- Keep `gallery: []` in the package; attach screenshots and the logo in the PR body
- Fill `submission` with the umbrel-apps PR URL
- Run `npm run lint:apps -- horizon --check-images`


## bitsperity Moonstone

| | |
|---|---|
| Community app ID | `bitsperity-moonstone` |
| Official app ID (later) | `moonstone` |
| UI | `http://umbrel.local:8740` (Umbrel login) |
| Mailbox | `ws://umbrel.local:8741` (no Umbrel cookie) |
| Source | [Bitsperitybtc/moonstone](https://github.com/Bitsperitybtc/moonstone) |

Standalone NIP-46 remote signer. Holds identities on the node, approves clients
per identity, signs over a bundled kind-24133 mailbox. Any compliant NIP-46
client can pair.

Existing installs do not migrate. Umbrel keeps the data directory under the previous app id `bitsperity-nostr-signer`.

### Image pin

Compose uses `ghcr.io/bitsperitybtc/moonstone:0.1.0`. The package is not publicly readable yet, so this listing does not pin a digest copied from `nostr-signer`. After the first GHCR push, make the package **public** or Umbrel cannot pull it, then pin the multi-arch index digest:

```text
ghcr.io/bitsperitybtc/moonstone:0.1.0
```

To bump:

1. Tag `vX.Y.Z` on `moonstone` `main` (GHCR workflow publishes the image)
2. Make `ghcr.io/bitsperitybtc/moonstone` public
3. `docker buildx imagetools inspect ghcr.io/bitsperitybtc/moonstone:<tag>`
4. Pin `image: ghcr.io/bitsperitybtc/moonstone:<tag>@sha256:<index-digest>`
5. Set `version` in `umbrel-app.yml` to that tag

Do not use `latest`. Do not use compose `build:`. Keep the mailbox sidecar digest-pinned.

## Lunation

| | |
|---|---|
| Community app ID | `bitsperity-lunation` |
| UI | `http://umbrel.local:8748` |
| Source | [Bitsperitybtc/lunation](https://github.com/Bitsperitybtc/lunation) |

Lunation is the Bitsperity planning server. It keeps one SQLite database under `${APP_DATA_DIR}/data` and serves the plan over HTTP. Sign-in is Nostr. Umbrel login is not put in front of the app (`PROXY_AUTH_ADD: "false"`). umbrelOS sets `APP_SEED`, and compose passes it through unchanged.

Sign in via `http://umbrel.local:8748` or `http://<device hostname>:8748` (Tailscale MagicDNS). A raw IP is not an allowed origin in 0.1.0.

The canonical copy is `umbrel/bitsperity-lunation/` in `Bitsperitybtc/lunation`. This folder has an identical copy, plus `icon.png` rendered from that repo's `icon.svg`.

### Image pin

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`) of the `v0.1.0` tag build:

```text
ghcr.io/bitsperitybtc/lunation:0.1.0@sha256:1aad777dbccec2c30b3cece5739808d54cf024dbe0beccb69b3d177ccb0f60bc
```

The package `ghcr.io/bitsperitybtc/lunation` must be public, or Umbrel cannot pull it.

To bump:

1. Tag `vX.Y.Z` on `lunation` `main` (the Docker workflow publishes the image)
2. Pin `image: ghcr.io/bitsperitybtc/lunation:<tag>@sha256:<index-digest>`
3. Set `version` in `umbrel-app.yml` to that tag and fill `releaseNotes`

Do not use `latest`. Do not use compose `build:`. `APP_PORT` stays `8080`.

## Layout

```text
umbrel-app-store.yml          Store id + display name
bitsperity-horizon/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + web image
  icon.png                    512×512 square PNG, no rounded corners (umbrelOS masks)
  gallery/1.png               Landing
  gallery/2.png               Ideas
  gallery/3.png               Job detail
bitsperity-moonstone/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + signer + mailbox relay
  relay-config.toml           Kind 24133 only
  icon.png                    512×512 square PNG, no rounded corners (umbrelOS masks)
bitsperity-lunation/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + web image
  icon.png                    512×512 square PNG, no rounded corners (umbrelOS masks)
```
