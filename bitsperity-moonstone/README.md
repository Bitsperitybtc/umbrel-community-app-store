# Moonstone — Umbrel package

This folder is the installable Umbrel app. It ships through the bitsperity Community App Store, [`Bitsperitybtc/umbrel-community-app-store`](https://github.com/Bitsperitybtc/umbrel-community-app-store) (no PR on `getumbrel/umbrel-apps`). The code lives in the monorepo [`Bitsperitybtc/bitsperity`](https://github.com/Bitsperitybtc/bitsperity) under `apps/moonstone`.

## Add the store on an Umbrel

1. Umbrel → App Store → Community App Stores → add
   `https://github.com/Bitsperitybtc/umbrel-community-app-store`
2. Install **Moonstone** (app id `bitsperity-moonstone`, directory `bitsperity-moonstone/`).

The compose file pulls `ghcr.io/bitsperitybtc/moonstone:<version>` (published, amd64 + arm64). Here it is pinned by tag only; the copy in the store adds the digest.

This folder (`apps/moonstone/umbrel/bitsperity-moonstone/`) is the canonical package. `Bitsperitybtc/umbrel-community-app-store` holds a copy of `umbrel-app.yml`, `docker-compose.yml`, `icon.png` and `gallery/`; change it here first, then copy it there.

## Requirements

- `manifestVersion: 1`, which umbrelOS reads as 1.0.0.
- umbrelOS 2.0.0 or newer. The manifest uses `environment:` (app settings), which umbrelOS 1.x does not have, and compose relies on the 2.0 app gateway at `10.21.0.1`.
- Image `linux/amd64` and `linux/arm64` (built by `.github/workflows/release-moonstone.yml` in the monorepo). The mailbox image, bitsperity Beacon, is published for both too.

## Release

`version` in `umbrel-app.yml` always names the image tag that `docker-compose.yml` pins: `scripts/ci/umbrel-packages.test.mjs` at the monorepo root fails when they differ or when an image carries a digest here. A release goes in this order:

1. Release PR: `CHANGELOG.md` and the `version` in `package.json` and `web/package.json`. `umbrel-app.yml` and `docker-compose.yml` stay on the old release.
2. After merge, tag it in the monorepo: `git tag moonstone/v<version> && git push origin moonstone/v<version>`. `.github/workflows/release-moonstone.yml` builds `linux/amd64` and `linux/arm64`, pushes `<version>`, `<major>.<minor>` and `latest`, and smokes the image (healthy, uid 1000, no tsx).
3. Pin PR: set, in one commit, the `signer` and `data_owner` image to `ghcr.io/bitsperitybtc/moonstone:<version>` (tag only), and `version` and `releaseNotes` in `umbrel-app.yml`.
4. Copy `umbrel-app.yml` and `docker-compose.yml` into `Bitsperitybtc/umbrel-community-app-store`; the store copy adds the index digest of each image (`docker buildx imagetools inspect`).

| Ref | Tags on GHCR |
| --- | --- |
| tag `moonstone/v<version>` | `<version>`, `<major>.<minor>`, `latest` |
| push to `main`, pull request | no image is pushed (CI builds and smokes it in the e2e job) |

The GHCR package is public; Umbrel cannot pull a private image.

## Ports

| Port | Role |
| --- | --- |
| 8740 | UI, Umbrel-authed via the umbrelOS app gateway |
| 8741 | NIP-46 mailbox WebSocket, no Umbrel cookie |
| 8740 `/mailbox` | Same mailbox for https pages (`wss://<host>:8740/mailbox`), whitelisted, no Umbrel cookie |

Umbrel injects `APP_SEED`. Compose passes it into the signer, which derives the API token (HKDF-SHA256, label `moonstone-api`) from the raw seed bytes and does not log the seed or the token. An empty (`APP_SEED=""`), shorter than 32 characters, or whitespace-padded seed aborts startup. The admin MCP token is a different derivation (`deriveMcpToken`, app id `bitsperity-moonstone`, HKDF info `bitsperity-mcp:bitsperity-moonstone`). Both MCP tokens are kept in the data volume (`/data/mcp-token`, `/data/nostr-mcp-token`, mode 0600), start as these derived values, and can be regenerated in Settings (the old token stops working at once); they are never logged. Settings shows the admin token behind the session cookie. The Nostr MCP token is `deriveMcpToken(APP_SEED, "bitsperity-moonstone-nostr")` (HKDF info `bitsperity-mcp:bitsperity-moonstone-nostr`). It is not an environment variable. Settings shows it behind the session cookie. `PROXY_AUTH_WHITELIST` is exactly `/mcp,/mcp/health,/nostr-mcp,/nostr-mcp/health,/mailbox,/pairing-offers`: those six paths skip the Umbrel login, each with its own guard. `/api` and the UI pages are not whitelisted.

| Path | What guards it |
| --- | --- |
| `/mcp` | the admin MCP bearer; no tool approves a connection, returns a secret or changes the signer address |
| `/mcp/health` | nothing; `GET` answers `{"ok":true}` only |
| `/nostr-mcp` | the Nostr MCP bearer; publishing still needs approval on the Approve screen |
| `/nostr-mcp/health` | nothing; `GET` answers `{"ok":true}` only |
| `/mailbox` | only WebSocket upgrades to the mailbox relay, where NIP-46 is the access control; any other request is `426`, with no page and no cookie |
| `/pairing-offers` | the `MOONSTONE_PAIRING_TOKEN` bearer, `POST` only; `404` when the setting is empty; it only lists a pairing as waiting and never approves or signs | Compose does not set `MOONSTONE_TEST_RESET`, so the test-reset tool and `POST /api/test/reset` stay off. `MOONSTONE_ALLOWED_HOSTS` is an Umbrel app setting (default empty). Set it to a MagicDNS name such as `umbrel.tailXXXX.ts.net` when the UI is opened on that host. The bare name `umbrel` is allowed without the variable. `MOONSTONE_PROXY_HOST` is `10.21.0.1`, the umbrelOS app-network gateway that the 2.0 app gateway proxies from, so the session cookie is issued to that source.

The mailbox is the bitsperity Beacon image (strfry) with `RELAY_WRITE_KINDS=24133`, so it accepts kind `24133` only. Its settings are `--set` flags in the compose `command`, so there is no config file to mount. It listens on 8080 inside the container, runs as uid 1000, and keeps its database on a tmpfs owned by uid 1000 (`uid=1000,gid=1000,mode=0700`; a root-owned tmpfs stops strfry with `mdb_env_open: Permission denied`).

## Bitspark (optional, other repo)

Same-node “Open in signer” is a client convenience, not required to use Moonstone. A client may ship its own `signer-config.json` (`signerUiPort` 8740; the mailbox is `ws://` or `wss://` `/mailbox` on that port, matching the page). Moonstone never reads that file.

## History

Before 0.2.0 this app was `nostr-signer` (directory `nostr-signer/`, image `ghcr.io/bitsperitybtc/nostr-signer`). Umbrel treats `bitsperity-moonstone` as a new app: existing `nostr-signer` installs do not upgrade in place, and their data dir stays under the old id.
