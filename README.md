# Bitsperity App Store

Community app store for umbrelOS. Add this repository URL in umbrelOS: **App Store → Community App Stores**.

Apps in this store use the `bitsperity-` ID prefix. That prefix is required by umbrelOS for community listings. The official Umbrel App Store package will use `horizon` with the same compose shape.

## bitsperity Horizon

| | |
|---|---|
| Community app ID | `bitsperity-horizon` |
| Official app ID (later) | `horizon` |
| Host URL | `http://umbrel.local:3847` |
| Source | [Bitsperitybtc/bitspark_btc](https://github.com/Bitsperitybtc/bitspark_btc) |

bitsperity Horizon is a static Nostr client. The container serves the production SPA. Sign-in is NIP-46. Lightning is NWC in Settings. Umbrel login is not wrapped in front of the app.

The published container image is still `ghcr.io/bitsperitybtc/bitspark`. There is no separate Horizon image yet. The community app id and display name do not alias the previous `bitsperity-bitspark` listing.

### How umbrelOS updates this app

Two layers. Refreshing the community store only git-clones this repo (catalog). The installed app stays on the old compose and `umbrel-app.yml` until its **Update** button is used.

Umbrel shows **Update** when `version` in the catalog `umbrel-app.yml` differs from the copy in `app-data`. String inequality, not semver. Changing `icon.png` without bumping `version` does nothing on an already-installed app.

The desktop/store icon is the `icon:` HTTP URL, not the file in the clone. `raw.githubusercontent.com/.../master/...` is cached: after replacing `icon.png`, point `icon:` at the commit that contains the new PNG (not `master`).

Update copies only `docker-compose.yml` (then `umbrel-app.yml` after start). Same image pin → pull is a no-op; the running SPA does not change.

### Image pin

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`), not an architecture-specific blob:

```text
ghcr.io/bitsperitybtc/bitspark:sha-b2437ef@sha256:7d78486e32f26e671b77eb8b6e8ac79b280f08f6ffcf4112b321453686b46ae9
```

To ship a new SPA (Umbrel: community store refresh, then **Update** on bitsperity Horizon):

1. Publish `ghcr.io/bitsperitybtc/bitspark` (push `chore/open-source-readiness` / `main` / `v*`, or `workflow_dispatch`). Do not use `latest` in compose.
2. `docker buildx imagetools inspect ghcr.io/bitsperitybtc/bitspark:<tag>` — copy the **index** digest (`linux/amd64` + `linux/arm64`), not a blob digest.
3. Pin `image: ghcr.io/bitsperitybtc/bitspark:<tag>@sha256:<index-digest>`
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
```
