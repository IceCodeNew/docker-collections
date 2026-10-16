# Stronghold-Protocol

[Upstream](https://github.com/sganggs/Stronghold-Protocol) provides the game server and browser client.
[Dockerfile](Dockerfile) uses DHI Node.js 24 development and runtime images.
The runtime uses UID/GID `1993:1993`.
[catatonit](https://github.com/openSUSE/catatonit) runs the Node.js entrypoint and reaps orphaned processes.

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
with Node.js 24, and verifies them. It caches six external source repositories in
five groups, with fonts and gamedata sharing a group. Keys use Git content-tree IDs
and generator inputs. A group restores only caches with the same source tree, so
updated source content is downloaded again while unaffected groups keep their caches.
Metadata-only commits do not change a content-tree fingerprint. If a source cannot
be resolved, its group gets a random key and the downloader runs without a restored
cache for that group. Cache logs count assets, fonts, and indexes separately.
Official statistics-page CDN assets, embedded images, and generated CSS remain in
the uploaded bundle but are excluded from Git source caches. The downloader fetches
or regenerates them on each run. Other unrecognized asset provenance still fails
cache preparation.

`--prune` removes assets absent from the new manifest; unreferenced font files are
removed before caching and uploading.
The workflow uploads a delta asset bundle for both architecture builds. Files that
match the SHA-256 inventory of a successfully restored cache are omitted; new or
changed files stay in the artifact, alongside the current manifest and cache-file
inventory. Each architecture restores the recorded exact cache keys and verifies
the omitted files before rebuilding the bundle. Unreferenced cached files are not
copied into it. An unavailable cache or a checksum mismatch fails the image job.
With no restored caches, the artifact contains the full bundle. A delta artifact
alone is not a complete asset pack; it depends on the recorded GitHub Actions caches.
After three attempts, individual failed downloads are omitted from the manifest;
verified available art is still bundled and cached. If asset verification fails,
the workflow builds with the upstream placeholder manifest instead. An unconfigured
source repository remains a configuration error and stops the job.
The workflow also uploads `upstream/.cache/assets-report.json`, when present, as
the separate `stronghold-protocol-asset-download-report` artifact in the workflow
run's artifacts list. This report remains available after a failed asset fetch;
cancelled runs skip the upload. See the `Upload asset download report` step in
the image workflow for its retention period. A missing report produces a warning.
The Dockerfile itself never downloads art. The image includes four language packs
and the v0.3.0 plugin templates, Schemas, and author tools. Official scenes and
combat effects still require game client extraction or a matching complete bundle.

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

Mount a volume at `/app/plugins` to retain installed plugins and Studio settings
across image updates. The templates stay in `/app/plugin-resources`. Script plugins
remain disabled unless `SP_PLUGIN_SCRIPTS` is explicitly set.

Do not expose the game port directly to untrusted clients with trusted proxy headers.
Read the upstream `TRUST_PROXY` guidance in [the deployment guide](https://github.com/sganggs/Stronghold-Protocol/blob/master/docs/DEPLOY.md).
Game sessions stay in memory and disappear when the server stops.

## Validate

The scripts use Node standard APIs. Run the tests with a Node version that supports TypeScript stripping:

```sh
node --test Stronghold-Protocol/entrypoint_test.ts
python3 -m unittest discover -s Stronghold-Protocol -p 'asset_cache_test.py'
```

The image workflow builds native AMD64 and ARM64 images, checks `/healthz`,
and verifies the built-in language packs and plugin resources before publication.
Its smoke test starts the game without a public tunnel.

## Licenses

The upstream code uses GPL-3.0-or-later with its stated linking exception.
Game art, audio, models, names, and data have separate Hypergryph/Yostar rights.
The upstream notice limits their use to personal, educational, non-commercial purposes.
Keep `LICENSE`, `NOTICE.md`, `THIRD-PARTY-NOTICES.md`, and dependency license files with the image.
Read [the upstream notice](https://github.com/sganggs/Stronghold-Protocol/blob/master/NOTICE.md) before distribution.

## References

- [DHI Node.js catalog](https://hub.docker.com/hardened-images/catalog/dhi/node/images)
- [Quick Tunnels](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/)
- [cloudflared run parameters](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/run-parameters/)
