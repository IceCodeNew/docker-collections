# Stronghold-Protocol

[Upstream](https://github.com/sganggs/Stronghold-Protocol) provides the game server and browser client.
[Dockerfile](Dockerfile) uses DHI Deno development and runtime images.
The runtime has no shell or package manager and uses UID/GID `1993:1993`.
[catatonit](https://github.com/openSUSE/catatonit) runs the Deno entrypoint and reaps orphaned processes.

## Build

Authenticate to DHI with your Docker Hub credentials:

```sh
docker login dhi.io
```

Read `STRONGHOLD_PROTOCOL_VERSION` in [the image workflow](../.github/workflows/Stronghold-Protocol.yml) for the upstream release.
Clone that release into a separate directory:

```sh
git clone --depth=1 --branch <release> \
  https://github.com/sganggs/Stronghold-Protocol.git /tmp/stronghold-source

docker buildx build --load \
  --build-context src_dir=/tmp/stronghold-source \
  --tag stronghold-protocol ./Stronghold-Protocol
```

The workflow checks out the configured Stronghold release, downloads optional art and battle voices
with Node.js 24, and verifies them. The asset job uses the separately pinned asset-tool
commit in the workflow until a release includes source-snapshot verification; this
does not change the game server or browser release in the image.
It caches six external source repositories in five groups, with fonts and gamedata
sharing a group. Keys use Git content-tree IDs and generator inputs. Each group can
restore its latest successful cache when the exact key is absent, including after
yuanyan updates. Metadata-only commits do not change a content-tree fingerprint.

Restored files are candidates, not trusted output. The downloader checks raw files
and indexes against Git blob hashes from pinned source commits before reuse or
acceptance. Same-size replacements and stale mirror responses fail that check.
It downloads changed files and reuses unchanged raw files. Normalized atlases and
generated font files are rebuilt from verified originals. `--prune` removes assets
absent from the new manifest; unreferenced font files are removed before caching
and uploading. Source API failures do not bypass verification. Cache restore and
save logs count assets, fonts, and indexes separately.
The workflow uploads one combined asset bundle for both architecture builds.
Missing optional files may be omitted from the manifest. If downloads or verification
still fail after three attempts,
the workflow builds with the upstream placeholder manifest instead.
The workflow also uploads `upstream/.cache/assets-report.json`, when present, as
the separate `stronghold-protocol-asset-download-report` artifact in the workflow
run's artifacts list. This report remains available after a failed asset fetch;
cancelled runs skip the upload. See the `Upload asset download report` step in
the image workflow for its retention period. A missing report produces a warning.
The Dockerfile itself never downloads art. Version 0.2.1 includes four language
packs in the image; 39 summon models have no public art source and require local
game client extraction.

For a local image with art, prepare the bundle from a checkout of the release:

```sh
cd /tmp/stronghold-source
npm ci --omit=dev --ignore-scripts --no-audit --no-fund
node tools/fetch-assets.mjs
node /path/to/docker-collections/Stronghold-Protocol/verify-assets.mjs
mkdir -p /tmp/stronghold-assets/public /tmp/stronghold-assets/data
cp -a public/assets public/fonts /tmp/stronghold-assets/public/
cp data/assets.json /tmp/stronghold-assets/data/
cd /path/to/docker-collections
docker buildx build --load \
  --build-context src_dir=/tmp/stronghold-source \
  --build-context asset_bundle=/tmp/stronghold-assets \
  --tag stronghold-protocol ./Stronghold-Protocol
```

Without an asset bundle, a local build uses the upstream placeholder manifest.
For the `tested` target, `--build-arg FETCH_ASSETS=1` checks that every image
and font referenced by the bundled manifest exists as a nonempty file in the
final image. The workflow enables this check when the asset job succeeds.

## Run with a temporary tunnel

```sh
docker run --detach --name stronghold-protocol \
  --restart unless-stopped stronghold-protocol
docker logs --follow stronghold-protocol
```

cloudflared prints the public `trycloudflare.com` URL in the container logs.
You do not need to publish a host port.
The URL changes when the tunnel restarts.
Quick Tunnels have no uptime guarantee and have a limit of 200 concurrent requests.

**The default tunnel makes the game public.** The upstream game has no account authentication.
Use a named tunnel and Cloudflare Access if you need access restrictions.

## Run with a named tunnel

Create a remotely managed tunnel in Cloudflare.
Set its public hostname service to `http://127.0.0.1:3000`.
Use the hostname root path so that `/ws` and static files work.

Set `TUNNEL_TOKEN` in a local environment file. Do not commit this file.

```sh
docker run --detach --name stronghold-protocol \
  --restart unless-stopped --env-file /path/to/tunnel.env stronghold-protocol
```

cloudflared reads `TUNNEL_TOKEN` from the environment, not from a command-line argument.
The game subprocess does not receive the token.
As an alternative, mount a token file and set `TUNNEL_TOKEN_FILE` to its container path.
Give UID `1993` read access to the file.

If you change `PORT`, change the named tunnel service port in Cloudflare too.
The temporary tunnel and health check use `PORT` automatically.
Keep `HOST=0.0.0.0` or use a loopback address that cloudflared can reach.

The container stops both processes if either process exits.
It forwards termination signals and allows five seconds for shutdown.
The health check requests the local `/healthz` endpoint; it does not check Cloudflare connectivity.

Do not expose the game port directly to untrusted clients with trusted proxy headers.
Read the upstream `TRUST_PROXY` guidance in [the deployment guide](https://github.com/sganggs/Stronghold-Protocol/blob/master/docs/DEPLOY.md).
Game sessions stay in memory and disappear when the server stops.

## Validate

The scripts use Node standard APIs. Run the tests with a Node version that supports TypeScript stripping:

```sh
node --test Stronghold-Protocol/entrypoint_test.ts
python3 -m unittest discover -s Stronghold-Protocol -p 'asset_cache_test.py'
```

To validate with the Deno engine from `Dockerfile`:

```sh
deno fmt --check Stronghold-Protocol/*.ts
deno lint Stronghold-Protocol/*.ts
deno check Stronghold-Protocol/*.ts
TEST_RUNTIME_ARGS='["run","--allow-read","--allow-net","--allow-env","--allow-run"]' \
  deno test -A Stronghold-Protocol/entrypoint_test.ts
```

The image workflow builds native AMD64 and ARM64 images, checks `/healthz`,
and verifies the four built-in 0.2.0 language packs before publication.
Its smoke test starts the game without a public tunnel.

## Licenses

The upstream code uses GPL-3.0-or-later with its stated linking exception.
Game art, audio, models, names, and data have separate Hypergryph/Yostar rights.
The upstream notice limits their use to personal, educational, non-commercial purposes.
Keep `LICENSE`, `NOTICE.md`, `THIRD-PARTY-NOTICES.md`, and dependency license files with the image.
Read [the upstream notice](https://github.com/sganggs/Stronghold-Protocol/blob/master/NOTICE.md) before distribution.

## References

- [DHI Deno guide](https://hub.docker.com/hardened-images/catalog/dhi/deno/guides)
- [DHI runtime specifications](https://hub.docker.com/hardened-images/catalog/dhi/deno/images/deno%2Fdebian-13%2F2/sha256-10884e38854d6172230cf1b20752ebc2c2ce540cf4aaae4c9a394f39a1146ae7/specifications)
- [Quick Tunnels](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/)
- [cloudflared run parameters](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/run-parameters/)
