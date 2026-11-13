# Bitsperity App Store

Community app store for umbrelOS. Add this repository URL in umbrelOS: **App Store → Community App Stores**.

Apps in this store use the `bitsperity-` ID prefix. That prefix is required by umbrelOS for community listings. The official Umbrel App Store package will use `horizon` with the same compose shape.

## Apps

| App | Community app ID | Host port | Source | Depends on |
|---|---|---|---|---|
| Beacon | `bitsperity-beacon` | `8749` (Nostr relay, `ws://umbrel.local:8749`) | [Bitsperitybtc/beacon](https://github.com/Bitsperitybtc/beacon) | none |
| Horizon | `bitsperity-horizon` | `3847` (SPA, `/relay` and `/mcp`) | [Bitsperitybtc/horizon](https://github.com/Bitsperitybtc/horizon) | `bitsperity-beacon` |
| Lunation | `bitsperity-lunation` | `8748` | [Bitsperitybtc/lunation](https://github.com/Bitsperitybtc/lunation) | none |
| Studio | `bitsperity-studio` | `8750` | [Bitsperitybtc/bitsperity](https://github.com/Bitsperitybtc/bitsperity) `apps/canopy` | none |
| Moonstone | `bitsperity-moonstone` | `8740` (UI, Umbrel login) and `8741` (mailbox relay, published) | [Bitsperitybtc/moonstone](https://github.com/Bitsperitybtc/moonstone) | none |
| Notus | `bitsperity-notus` | `8796` (the container listens on `8096`) | [Bitsperitybtc/notus](https://github.com/Bitsperitybtc/notus) | none |

The ports are the `port:` of each `umbrel-app.yml`, plus `8741` published by the Moonstone compose file. Moonstone's mailbox relay runs the Beacon image, but it is not the Beacon app and has no dependency on it. No other compose file in this store publishes a host port. Studio listens on container port `3000`; the host port is `8750`.

## Requirements: umbrelOS, manifest, architectures

Every package declares `manifestVersion: 1`. umbreld normalizes it to `1.0.0` (`tryNormalizeVersion` in `modules/apps/schema.ts`) and, since umbrelOS 2.0.0, marks an app incompatible only when that version is newer than the OS (`manifest-compatibility.ts`), so `1` installs on every umbrelOS release.

The minimum supported umbrelOS is **2.0.0** for every app here. Beacon, Horizon, Lunation, Moonstone and Studio declare `environment:` settings (App Settings → Environment); umbrelOS 1.7.4 has no `environment` field in its manifest schema, and 2.0.0 is the first release with it (read from `packages/umbreld/source/modules/apps/schema.ts` at tags `1.7.4` and `2.0.0`). Moonstone also needs the 2.0 app gateway: its session cookie is issued for `MOONSTONE_PROXY_HOST=10.21.0.1`. Notus uses no 2.0-only field, but it is tested only on 2.0.x.

Architectures of the pinned images. Beacon, Moonstone and Notus were read on 3 Nov 2026. Horizon `0.15.0`, Lunation `2.0.0` and Studio `v3.0.0` were read on 13 Nov 2026 from the registry API without a login (the platforms of each pinned index digest, see [Check an image digest](#check-an-image-digest)):

| App | Image | linux/amd64 | linux/arm64 |
|---|---|---|---|
| Beacon | `ghcr.io/bitsperitybtc/beacon:0.2.0` | yes | yes |
| Horizon | `ghcr.io/bitsperitybtc/horizon:0.15.0` | yes | yes |
| Lunation | `ghcr.io/bitsperitybtc/lunation:2.0.0` | yes | yes |
| Studio | `ghcr.io/bitsperitybtc/canopy-studio:v3.0.0` | yes | yes |
| Moonstone | `ghcr.io/bitsperitybtc/moonstone:0.7.1`, mailbox `ghcr.io/bitsperitybtc/beacon:0.1.1` | yes | yes |
| Notus | `ghcr.io/bitsperitybtc/notus:v3.1.7` | yes | **no** (single-arch manifest; the listing says "Runs on amd64 only") |
| Notus | `postgres:16-alpine`, `ghcr.io/ggml-org/llama.cpp:server-b11946` | yes | yes |

Icons and screenshots: every package has an `icon.png` (square, no rounded corners; Beacon 256×256, the others 512×512) drawn from the bitsperity brand artwork (CC BY-SA 4.0). Studio uses the Starling mark until Canopy has its own icon. Horizon and Moonstone have 1440×900 gallery screenshots. Beacon is a relay without a UI and Notus, Lunation and Studio list `gallery: []`; umbrelOS shows such a listing without screenshots.

Port check (13 Nov 2026, [getumbrel/umbrel-apps](https://github.com/getumbrel/umbrel-apps)): `8750` appears only inside image digests, not as an app `port:`. The earlier check (2 Nov 2026, `7a94db0`) found none of `3847`, `8740`, `8741`, `8748`, `8749` or `8796` as a `port:`. Re-run it with:

```sh
grep -rn -w -E '3847|8740|8741|8748|8749|8750|8796' --include='*.yml' --include='*.yaml' --include='*.sh' --include='*.env*' .
```

## bitsperity Horizon

| | |
|---|---|
| Community app ID | `bitsperity-horizon` |
| Official app ID (later) | `horizon` |
| Host URL | `http://umbrel.local:3847` |
| Source | [Bitsperitybtc/horizon](https://github.com/Bitsperitybtc/horizon) |

bitsperity Horizon is a Nostr client. The `web` container serves the production SPA and its `/relay`, which by default forwards to the Beacon app. Sign-in is NIP-46. Lightning is NWC in Settings. The `mcp` container, from the same image, serves the Horizon MCP at `/mcp` on the app port; it needs a bearer token. `PROXY_AUTH_WHITELIST` is `*` and only `/mcp-token` is blocked, so `/mcp-token` is the one path behind the Umbrel login and everything else is open.

The container image is `ghcr.io/bitsperitybtc/horizon`. The images of all apps in this store that are built from the bitsperity repos (`beacon`, `horizon`, `lunation`, `moonstone`) pull anonymously: on 2 Nov 2026 each index digest pinned here was read from GHCR without a login and listed `linux/amd64` and `linux/arm64`. The community app id and display name do not alias the previous listing.

#### Check an image digest

Run this after every pin change, with no login. A `401` or `404` means the package is private or the digest is wrong.

```sh
repo=bitsperitybtc/horizon   # package name under ghcr.io
ref=0.14.0                   # a tag, or the sha256:… digest from docker-compose.yml
token=$(curl -s "https://ghcr.io/token?scope=repository:$repo:pull" | jq -r .token)
accept='Accept: application/vnd.oci.image.index.v1+json'
# The index digest of the tag (this is the value to pin):
curl -sI -H "Authorization: Bearer $token" -H "$accept" "https://ghcr.io/v2/$repo/manifests/$ref" | grep -i docker-content-digest
# The platforms in that index; both linux/amd64 and linux/arm64 must be there:
curl -s -H "Authorization: Bearer $token" -H "$accept" "https://ghcr.io/v2/$repo/manifests/$ref" \
  | jq -r '.manifests[].platform | select(.architecture != "unknown") | "\(.os)/\(.architecture)"'
```

The digest printed for a tag must equal the one in `docker-compose.yml`. `docker buildx imagetools inspect ghcr.io/$repo:$ref` shows the same index.

### How umbrelOS updates this app

Two layers. Refreshing the community store only git-clones this repo (catalog). The installed app stays on the old compose and `umbrel-app.yml` until its **Update** button is used.

Umbrel shows **Update** when `version` in the catalog `umbrel-app.yml` differs from the copy in `app-data`. `version` is compared as a string (`!==`), not as semver, so any different value counts, a lower one too. Changing `icon.png` without bumping `version` does nothing on an already-installed app.

The desktop/store icon is the `icon:` HTTP URL, not the file in the clone. `raw.githubusercontent.com/.../master/...` is cached: after replacing `icon.png`, point `icon:` at the commit that contains the new PNG (not `master`).

Update stops the app, runs the installed `hooks/pre-update`, and copies only `docker-compose.yml`, `*.template`, `exports.sh`, `torrc` and `hooks/` into `app-data`. It then pulls the images, and only after that copies `umbrel-app.yml`. Every other file in the folder (`icon.png`, `gallery/`, config files) is not copied, and the data directories stay. A package that needs a changed file outside that list must rewrite it itself in a hook (Horizon's `hooks/pre-start` does this for its two JSON config files). Same image pin → pull is a no-op; the running app does not change.

Source: [`app-script`](https://github.com/getumbrel/umbrel/blob/821cca5/packages/umbreld/source/modules/apps/legacy-compat/app-script) (`UPDATE_FILES_WHITELIST_PRE` and `UPDATE_FILES_WHITELIST_POST` in the `update` and `pre-patch-update` commands) and `updates` in [`apps/routes.ts`](https://github.com/getumbrel/umbrel/blob/821cca5/packages/umbreld/source/modules/apps/routes.ts), both read at commit `821cca5`.

### Image pin

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`), not an architecture-specific blob:

```text
ghcr.io/bitsperitybtc/horizon:<version>@sha256:<index digest>
```

Both services (`web`, `mcp`) use the same image line; keep them identical. The current pin is in `bitsperity-horizon/docker-compose.yml`.

To ship a new Horizon, follow the [release checklist](#release-checklist), then on the Umbrel: community store refresh, then **Update** on bitsperity Horizon. Do not use `latest` in compose. The package must be public or Umbrel cannot pull it.

Listing-only (icon/copy, same container): bump `version`, keep the image pin, and set `icon:` to the commit that holds the PNG if the PNG changed.

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

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`) of the Moonstone tag build for `signer`, and the Beacon image `ghcr.io/bitsperitybtc/beacon:<version>@sha256:<index digest>` for the `relay` mailbox sidecar:

```text
ghcr.io/bitsperitybtc/moonstone:<version>@sha256:<index digest>
```

Both packages are public. The current pins are in `bitsperity-moonstone/docker-compose.yml`. To bump, follow the [release checklist](#release-checklist). Do not use `latest`. Do not use compose `build:`. Keep the mailbox sidecar digest-pinned.

## bitsperity Beacon

| | |
|---|---|
| Community app ID | `bitsperity-beacon` |
| Relay for clients on the network | `ws://umbrel.local:8749` |
| Relay for other apps on this Umbrel | `ws://bitsperity-beacon_relay_1:7777` |
| Source | [Bitsperitybtc/beacon](https://github.com/Bitsperitybtc/beacon) |

Nostr relay (strfry) for the apps on this Umbrel. The Umbrel login is not put in front of the app (`PROXY_AUTH_ADD: "false"`) because Nostr clients cannot do it; the relay gates writes itself: empty `RELAY_WRITE_PUBKEYS` (the default) accepts every author, a list accepts only those keys. The database is the strfry LMDB in `${APP_DATA_DIR}/data`. The healthcheck reads the NIP-11 document on `127.0.0.1:7777`.

Horizon declares `dependencies: [bitsperity-beacon]`, so install Beacon first.

### Image pin

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`) of the Beacon tag build:

```text
ghcr.io/bitsperitybtc/beacon:<version>@sha256:<index digest>
```

The current pin is in `bitsperity-beacon/docker-compose.yml`. To bump, follow the [release checklist](#release-checklist).

## Lunation

| | |
|---|---|
| Community app ID | `bitsperity-lunation` |
| UI | `http://umbrel.local:8748` |
| Source | [Bitsperitybtc/lunation](https://github.com/Bitsperitybtc/lunation) |

Lunation is the Bitsperity planning server. It keeps one SQLite database under `${APP_DATA_DIR}/data` and serves the plan over HTTP. Sign-in is Nostr. Umbrel login is not put in front of the app: `PROXY_AUTH_WHITELIST` is `*` and only `/mcp-token` is blocked, so `/mcp-token` is the one path behind the Umbrel login. umbrelOS sets `APP_SEED`, and compose passes it through unchanged. `hooks/pre-start` creates `data/` with uid 1000, so a linter error about a missing `data/` directory in the package is harmless here.

Sign in via `http://umbrel.local:8748` or `http://<device hostname>:8748` (Tailscale MagicDNS). A raw IP is not an allowed origin.

The canonical copy is `umbrel/bitsperity-lunation/` in `Bitsperitybtc/lunation`. This folder has an identical copy, plus `icon.png` rendered from that repo's `icon.svg`.

### Image pin

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`) of the Lunation tag build:

```text
ghcr.io/bitsperitybtc/lunation:<version>@sha256:<index digest>
```

The package `ghcr.io/bitsperitybtc/lunation` must be public, or Umbrel cannot pull it. The current pin is in `bitsperity-lunation/docker-compose.yml`. To bump, follow the [release checklist](#release-checklist). Do not use `latest`. Do not use compose `build:`. `APP_PORT` stays `8080`.

## Studio

| | |
|---|---|
| Community app ID | `bitsperity-studio` |
| UI | `http://umbrel.local:8750` (Umbrel login) |
| MCP | `http://umbrel.local:8750/mcp` (no Umbrel login; off until a token is set) |
| Source | [Bitsperitybtc/bitsperity](https://github.com/Bitsperitybtc/bitsperity) `apps/canopy` |

Studio is the window onto one Canopy forest. It stores nothing of its own. App Settings names the forest: `STUDIO_OBSERVE_URL` and `STUDIO_CONTROL_URL` are how the container reaches the forest, and `CANOPY_CONTROL_TOKEN` is that forest's control token. The defaults point at this container, so a new install opens and shows the forest as unreachable until those three are set. Reads work once the observe URL is reachable. Pause, cancel and approve stay refused until the token matches.

The page is behind the Umbrel login. `PROXY_AUTH_WHITELIST` is `/mcp,/mcp/health` only. `/mcp` exists when `CANOPY_STUDIO_MCP_TOKEN` is set, and that bearer can start and cancel work.

On each start the container writes `/tmp/forests.yaml` from those variables and serves it. There is no forest file in the package, because an Umbrel update copies `docker-compose.yml` and not other files.

The canonical copy is `apps/canopy/umbrel/bitsperity-studio/` in `Bitsperitybtc/bitsperity`. This folder is an identical copy. `icon.png` is rendered from `brand/icons/starling.svg`, the mark Studio uses until Canopy has its own.

### Image pin

Compose pins the multi-arch index digest (`linux/amd64` + `linux/arm64`) of the Canopy tag build. The image tag keeps the `v`:

```text
ghcr.io/bitsperitybtc/canopy-studio:v3.0.0@sha256:<index digest>
```

The package must be public, or Umbrel cannot pull it. The current pin is in `bitsperity-studio/docker-compose.yml`. To bump, tag `canopy/vX.Y.Z` (that workflow also publishes `canopy:vX.Y.Z`), then follow the [release checklist](#release-checklist). Do not use `latest`. Do not use compose `build:`. `APP_PORT` stays `3000`.

## Notus

| | |
|---|---|
| Community app ID | `bitsperity-notus` |
| UI / API | `http://umbrel.local:8796`; other apps use `http://bitsperity-notus_web_1:8096` |
| Source | [Bitsperitybtc/notus](https://github.com/Bitsperitybtc/notus) |

Notus collects market news, prices and fundamentals into Postgres 16 and scores thesis relations with local llama.cpp models (d1, EmbeddingGemma-2). amd64 only. Secrets live in `${APP_DATA_DIR}/notus.env`; `hooks/pre-start` creates `db.env`, `relation.env` and the data directories (uid 1000) before compose starts.

A one-shot `restore` service restores `${APP_DATA_DIR}/restore/notus.dump` (sha256-checked) into an empty database, then opens the gate for `web`, which migrates and serves. Runbook: `docs/operations/umbrel-cutover.md` in the notus repo.

The canonical copy is `umbrel/bitsperity-notus/` in `Bitsperitybtc/notus`. This folder has an identical copy, except `icon` and `submission` in `umbrel-app.yml`, plus `icon.png` from the brand assets.

### Image pin

All images are digest-pinned: `ghcr.io/bitsperitybtc/notus:v<version>@sha256:<digest>` (note the `v` in the tag), `postgres:16-alpine@sha256:…`, `ghcr.io/ggml-org/llama.cpp:server-b11946@sha256:…`. The notus package must be public. The current pins are in `bitsperity-notus/docker-compose.yml`.

To bump: tag on `notus` `main`, pin the new digest in notus `umbrel/bitsperity-notus/`, set `version`, then copy the folder here. Do not use `latest` or compose `build:`.

## Release checklist

The same steps for every app. Order of apps: Beacon, then Moonstone, then Horizon and Lunation (Horizon depends on Beacon, and Moonstone's mailbox runs the Beacon image).

1. **Tag.** Tag `vX.Y.Z` on the app repo's `main`. CHANGELOG and, in `umbrel-app.yml`, `version` and `releaseNotes` are already in the release PR. The tag must match `version`.
2. **Image.** The repo's workflow builds the multi-arch image (`linux/amd64` + `linux/arm64`) from the tag.
3. **Index digest.** Read the **index** digest of the tag without a login, and check that amd64 and arm64 are both listed (see [Check an image digest](#check-an-image-digest)). Note the digest.
4. **Pin PR** in the app repo: compose on `image: ghcr.io/bitsperitybtc/<app>:X.Y.Z@sha256:<index digest>`.
5. **Store PR** here: copy the package folder 1:1 from the app repo (`umbrel/bitsperity-<app>/`, for Moonstone `bitsperity-moonstone/`). `diff -r <app repo folder> bitsperity-<app>` must print nothing (only intentional differences may remain, for example `icon.png` or Notus's `icon` and `submission`; read the diff, do not hide it). Merge to `master`. This repo changes only by pull request.
6. **Backup** the app's data if it has any: Horizon `mcp/` and the two JSON configs, Moonstone and Lunation `data/`, Beacon the relay database (`data/`, a strfry LMDB).
7. **Update on the Umbrel through the UI** (refresh the community store, then **Update**; no reinstall, so the update path is tested). `version` must differ from the installed one, and the files listed under "How umbrelOS updates this app" are what changes.
8. **Smoke test and logs.** Health is green, sign-in works, one core path works (Beacon: a client connects to `ws://<umbrel>:8749`, an event round-trips and survives a restart), `docker logs` is clean. Write the result into the release issue.

A change to the pinned image needs steps 1 to 4 first. A listing-only change (text, icon, gallery) needs only a new `version` in the store copy and in the app repo.

## Layout

```text
umbrel-app-store.yml          Store id + display name
bitsperity-beacon/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + relay (strfry)
  data/.gitkeep               Bind-mount source for the relay database
  icon.png                    256×256 square PNG, no rounded corners (umbrelOS masks)
bitsperity-horizon/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + web + mcp (same image)
  hooks/pre-start             Refreshes the two JSON configs when they still hold an old default
  relay-config.json           SPA relay config (served as a file)
  signer-config.json          SPA signer config (Moonstone UI port)
  icon.png                    512×512 square PNG, no rounded corners (umbrelOS masks)
  gallery/1.png … 4.png       Store screenshots
bitsperity-lunation/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + web image
  hooks/pre-start             Creates data/ with uid 1000
  icon.png                    512×512 square PNG, no rounded corners (umbrelOS masks)
bitsperity-studio/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + Studio image (writes forests.yaml on start)
  icon.png                    512×512 square PNG, no rounded corners (umbrelOS masks)
bitsperity-moonstone/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + signer + mailbox relay (Beacon image)
  icon.png                    512×512 square PNG, no rounded corners (umbrelOS masks)
  gallery/                    Store screenshots
bitsperity-notus/
  umbrel-app.yml              Listing
  docker-compose.yml          app_proxy + postgres + restore + web + llama.cpp
  hooks/                      pre-install, pre-start, restore.sh, row-counts.sql, fetch-models.sh
  icon.png                    512×512 square PNG, no rounded corners (umbrelOS masks)
```

## License

Packaging files are Apache-2.0 ([LICENSE](LICENSE)); icons and gallery images are CC BY-SA 4.0. Each app's code licence is in its source repository; the Beacon image (strfry) is GPL-3.0-only. Details in [NOTICE](NOTICE).
