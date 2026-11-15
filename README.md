# kanboard-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Kanboard](https://github.com/kanboard/kanboard).

## What this is

A four-file TOS Docker application archive (`kanboarddocker.tar.gz`) that installs
Kanboard on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `kanboarddocker`)
- `kanboarddocker.lang` — 23-language superset (TOS requires 14)
- `kanboarddocker.svg` — application icon (1512 bytes, 4 SVG elements)
- `docker-compose.yml` — one service, image `kanboard/kanboard:v1.2.57`

## How it works

| | |
|---|---|
| Container image | `kanboard/kanboard:v1.2.57` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8173/` (container port 8080) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/var/www/app/data` → `/Volume1/DockerAppData/kanboarddocker/data`, `/var/www/app/plugins` → `/Volume1/DockerAppData/kanboarddocker/plugins` |
| Logs | `docker logs kanboarddocker` (stdout/stderr) |

`/var/www/app/data` (mounted from `DockerAppData/kanboarddocker/data`) holds `db.sqlite`, attachments and the uploaded files; `/var/www/app/plugins` holds plugins.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper**: serves the app with `php -S 0.0.0.0:8080` (the image's Apache binds 80, unusable as uid 1000) and keeps `data/` and `plugins/` on the volumes.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 8080.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **PHP built-in server.** Apache binds port 80, which uid 1000 cannot use; `php -S` serves the same app on 8080.
- **SQLite only.** No database server; boards and tasks live in one file.

## Privacy

This application runs entirely on your NAS. It does not include analytics, telemetry or advertising SDKs, and the packaging contains no code that sends data to the packager. Data is only exchanged with the services you configure yourself (for example media servers, notification endpoints or model APIs), and only from the container. Everything the application stores lives in the application data folder described above; removing the app with its data deletes it.

## Third-party components

The package runs the upstream image `kanboard/kanboard:v1.2.57` unmodified. Its components and their licences are those of the upstream project (https://github.com/kanboard/kanboard), which is distributed under **MIT**. No upstream source code is redistributed in this repository; only the four packaging files are original work.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `/Volume1/DockerAppData/kanboarddocker/data` | Kanboard application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |
| `/Volume1/DockerAppData/kanboarddocker/plugins` | Kanboard application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/kanboarddocker.tar.gz + .sha256
scripts/build.sh 1.2.57-2   # packaging iteration bump
scripts/build.sh 1.2.57-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/kanboarddocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v1.2.57-1`**, assets `kanboarddocker.tar.gz` +
   `kanboarddocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `kanboarddocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `1.2.57-1` → automated validation → review.

## License / branding

Kanboard is distributed by its upstream authors under **MIT**. The container image is the official image from Docker Hub (`kanboard/kanboard:v1.2.57`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

- The built-in PHP server is single-threaded; fine for small teams, not for heavy load.
- Default admin/admin must be changed after the first login.
- The UI is plain HTTP; use a TLS reverse proxy before exposing it to the internet.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
