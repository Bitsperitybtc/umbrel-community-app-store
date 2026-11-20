# Horizon — Umbrel package

This folder is the canonical Umbrel package for Horizon (app id `bitsperity-horizon`).
`Bitsperitybtc/umbrel-community-app-store` holds an identical copy of
`umbrel-app.yml`, `docker-compose.yml`, `signer-config.json`, `relay-config.json`, `hooks/pre-start` (mode 755), `icon.png` and `gallery/`.
Change them here first, then copy them there byte for byte. `icon.svg` and this README stay in this repo only.

## Release

1. Set the same version in `package.json`, `umbrel-app.yml` (`version`) and the `web.image` tag in `docker-compose.yml`.
2. Merge to `main`, then tag: `git tag v<version> && git push origin v<version>`.
3. The Docker workflow builds `linux/amd64` + `linux/arm64` and pushes `ghcr.io/bitsperitybtc/horizon:<version>`.
   Copy the digest from the "Inspect multi-arch image" step and pin `image: ghcr.io/bitsperitybtc/horizon:<version>@sha256:<digest>`.
4. Copy the package to the store repo.

## Check an image

```sh
docker run --rm -d -p 8080:80 --name horizon-check ghcr.io/bitsperitybtc/horizon:<version>@sha256:<digest>
curl -fsS http://127.0.0.1:8080/healthz   # ok
docker rm -f horizon-check
```

## Files

| File | Role |
| --- | --- |
| `signer-config.json` | Served at `/signer-config.json`; tells Horizon where a same-node Moonstone listens (UI 8740; mailbox `ws://` or `wss://` on 8740 at `/mailbox`, matching the page, Moonstone 0.3.4 or later) for "Open in signer". |
| `relay-config.json` | Served at `/relay-config.json`. Relays a fresh visitor reads from and a login without a NIP-65 list publishes to. Defaults to `"self"`: `/relay` on the host and port Horizon is opened on (`wss://` over https, `ws://` over http). nginx forwards it to the bitsperity Beacon app (`HORIZON_LOCAL_RELAY_UPSTREAM` in `docker-compose.yml`, `ws://bitsperity-beacon_relay_1:7777` on `umbrel_main_network`). Beacon is listed in `dependencies:`, so umbrelOS installs it first; if it is stopped, `/relay` gives 502. There is no public fallback. |
| `hooks/pre-start` | Brings `relay-config.json` and `signer-config.json` from an earlier shipped default to the current one. |
| `gallery/` | 1440×900 screenshots (sample data on a local relay). |
| `docker-compose.yml` service `mcp` | The Horizon MCP over HTTP (same image, `node /opt/horizon-mcp/horizon-mcp.mjs`). See below. |

Both files are bind-mounted from `${APP_DATA_DIR}`: umbreld puts its common compose fragment first, so a relative `./` path would resolve outside this app.

An update copies only `docker-compose.yml`, `umbrel-app.yml` and `hooks/` into `${APP_DATA_DIR}`, so both files keep the content of the first install. `hooks/pre-start` runs on the host before each start: a file that still holds a default an earlier package shipped (ignoring whitespace) gets the current default, a missing file is written, and any other content stays. When a default changes, add the old one to the hook.

Port `3847` is the Umbrel app port (kept from the first store listing).

## MCP

The `mcp` service starts with the app and has no port of its own. It listens on a Unix socket in `${APP_DATA_DIR}/mcp-run`, which only `web` and `mcp` mount; nginx in `web` forwards `/mcp` and `/mcp-token` to it. So the endpoint is `http://<umbrel>:3847/mcp`, on the LAN or over Tailscale (`http://<tailscale-ip>:3847/mcp`).

- Auth: `Authorization: Bearer <token>` on every call except `GET /mcp/health`. The token is read from `${APP_DATA_DIR}/mcp/mcp-token` on every request (see Token storage). It starts as `deriveMcpToken(APP_SEED, "bitsperity-horizon")` (Kit, same scheme as Moonstone) and stays the same across restarts and updates until you regenerate it.
- Why `PROXY_AUTH_WHITELIST: "*"`: Umbrel's guide treats a whitelist of `*` as the exception, and here it is on purpose. Horizon is a client-side SPA: the page, `/relay` and the nginx health check hold no private data, sign-in is Nostr (NIP-46 signer, NWC wallet) and happens in the browser, so an Umbrel login in front of them protects nothing and would block agents and the relay socket, which cannot answer a login page. The one thing worth protecting is the MCP bearer token, so `PROXY_AUTH_BLACKLIST: "/mcp-token"` puts exactly that path behind the Umbrel login; `/mcp` itself is open to the network but needs the bearer token on every call (see Auth).
- Getting the token: Settings → Identity → Agent access (MCP) → Show token (the Umbrel login comes first; opening `http://<umbrel>:3847/mcp-token` in a browser lands there too). The panel shows the token, the server URL and the `Authorization: Bearer` header, each with Copy, and has Regenerate token. The data path `/mcp-token` is the only path behind the Umbrel login (`PROXY_AUTH_WHITELIST: "*"`, `PROXY_AUTH_BLACKLIST: "/mcp-token"`): `GET` with `Accept: application/json` returns the token, a same-origin `POST` with header `X-Bitsperity-MCP: regenerate` replaces it. nginx serves it only for the exact target from the app gateway (`HORIZON_PROXY_PEER`, `10.21.0.1`, the socket address, not `X-Forwarded-For`), so a request from another container or a `//mcp-token` spelling gets 404.
- Token storage: `${APP_DATA_DIR}/mcp/mcp-token` (mode 0600). On first start it holds the old seed-derived token, so agents keep working after the update. Regenerate writes a fresh random token there; the old one is refused at once, also inside open MCP sessions. A reinstall wipes app data, and the token falls back to the seed-derived one.
- Signing: `use_identity` returns a Moonstone approval link (`MOONSTONE_URL`, the same-node Moonstone on 8740; the pairing runs over Moonstone's mailbox container). The link's `relay=ws://bitsperity-moonstone_relay_1:8080` (`MOONSTONE_RELAYS`) is an internal Umbrel host on purpose: only the `mcp` container and Moonstone's signer dial it, both on the Umbrel app network; the browser opens only the `MOONSTONE_URL` page. A signer outside this Umbrel needs `MOONSTONE_RELAYS` set to a relay it can reach. Only with `NOSTR_LOCAL_KEYS=1` (off by default) Kit also offers local test identities, stored in `${APP_DATA_DIR}/mcp`.
- Relays: `NOSTR_LOCAL_RELAYS`, default the bitsperity Beacon app (`ws://bitsperity-beacon_relay_1:7777`).
- Relays named in events (poll and goal relay tags, relay hints): `HORIZON_PUBLIC_RELAYS`, default this app's `/relay` at `ws://${DEVICE_DOMAIN_NAME}:3847/relay`, which a browser on the LAN can reach. Set it in App Settings → Environment when browsers open Horizon on another address (for example an https tunnel: `wss://<host>/relay`).
- `/relay` upstream: `HORIZON_LOCAL_RELAY_UPSTREAM` on the web service, default Beacon. App Settings → Environment can point it at another `ws://host:port[/path]` relay.
- No test defaults: `NOSTR_LOCAL_KEYS` and `HORIZON_TEST_RESET` are a `0`/`1` switch in App Settings → Environment, `0` by default, and compose sets neither, so by default the MCP creates no local test identity and serves no `reset_test_data` tool; signing goes through Moonstone. Both are for testing only; switch one to `1` per device:
  - `NOSTR_LOCAL_KEYS=1` lets the MCP create local test identities (`create_local_identity`, then `use_identity`). Their keys are stored in `${APP_DATA_DIR}/mcp/local-keys`.
  - `HORIZON_TEST_RESET=1` adds the tool `reset_test_data`, which deletes the events the active local test identity published on the MCP relays. It needs `NOSTR_LOCAL_KEYS=1` and refuses Moonstone identities.
  - Any other value, including empty, leaves the feature off. Clear the value to turn it off again.
- Wallets for the MCP are added per identity in Horizon Settings → Wallet (MCP), not in App Settings. MCP can receive into them; it never pays.
- Host secrets (NIP-46 client key, NWC wallets added in Settings, Cashu swap records) and local test keys live in `${APP_DATA_DIR}/mcp`, which only `mcp` mounts.
