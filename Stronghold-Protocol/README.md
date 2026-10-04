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

Asset downloads are disabled by default. Add `--build-arg FETCH_ASSETS=1` to enable them.
The image workflow enables downloads for published images.
The build stops if the download report has errors or a manifest file is missing or empty.
Some optional models have no public source and use upstream fallback graphics.
Asset sources can change independently of the application release.

Without downloads, the game uses placeholder graphics unless you mount assets and their matching manifest.

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
```

To validate with the Deno engine from `Dockerfile`:

```sh
deno fmt --check Stronghold-Protocol/*.ts
deno lint Stronghold-Protocol/*.ts
deno check Stronghold-Protocol/*.ts
TEST_RUNTIME_ARGS='["run","-A","--no-config","--no-lock"]' \
  deno test -A Stronghold-Protocol/entrypoint_test.ts
```

The image workflow builds native AMD64 and ARM64 images and checks `/healthz` before publication.
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
