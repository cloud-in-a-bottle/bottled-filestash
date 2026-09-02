# Filestash

[Filestash](https://www.filestash.app) is a web-based file manager. This repo packages it as an OpenHost app, storing files in the zone's persistent volume and using OpenHost's built-in auth so no separate login is needed.

## What it does

Filestash gives you a browser-based interface to your files. It works on any browser, no client software required.

**Browsing and organizing.** Browse directories, create and delete folders, rename files and folders, sort by name, date, or size, toggle hidden files.

**Uploading and downloading.** Drag-and-drop or file-picker upload; download any file or folder as a zip.

**Previews.** Renders inline without downloading: images, video, audio, PDFs, text and code (with syntax highlighting), Markdown (rendered), and more.

**Editing.** Text files and code can be edited directly in the browser and saved back.

**Sharing.** Any file or folder can be shared via a link that works without logging in. Sharing is disabled by default in Filestash; read the sharing section below before enabling it.

## Access

Browsing, uploading, editing and the admin panel all require the zone owner to be
logged in. Anonymous requests to those paths are redirected to the zone login.

Share links are the deliberate exception when enabled. `openhost.toml` lists the
specific paths a share recipient needs in `public_paths`, so a person with a share
link can load the share page and read what it points at without an account on your
zone. The container entrypoint sets Filestash's `features.share.enable` setting to
`false` on every startup; enabling sharing requires changing the image configuration.

## Sharing, and what it costs you

A share link is a bearer token. Anyone holding the link can read that share, and
that is the whole of the access control. Specifically:

- The share id in the URL is the credential. There is no second check tied to the
  recipient, so a link forwarded to someone else keeps working.
- The proof cookie a recipient picks up is not bound to one share. Somebody who
  holds any share link and also learns a second share's id can read that second
  share too.
- Filestash generates ids of about seven characters, roughly 42 bits. That is far
  short of a random token (a UUID is 122 bits), and neither Filestash nor the zone
  rate-limits attempts, so ids are not resistant to a determined guessing attack.

What a share recipient cannot do, verified against a live deployment: reach
anything outside the shared path. Requests resolve relative to the share root,
`..` is normalised back to it, and absolute paths to other apps' data, the zone
secrets store and the instance identity keys all fail. A read-only share also
cannot be written to. Without a share credential every one of the opened paths
returns 401 from Filestash itself.

The practical guidance: treat a share link as public the moment you send it, share
the narrowest path that does the job, and delete shares when you are done with
them. Because this app is mounted over the zone's whole volume (see Storage), do
not share a directory near the root.

This risk is why sharing is disabled by default. The router paths remain configured,
but Filestash rejects share requests while `features.share.enable` is `false`. The
setting is package-managed and cannot be enabled through Filestash's admin UI.

## Storage

Files are stored at `/data/` in the zone's persistent volume, the same root shared across all apps that request `access_all_app_data`. The app's own state (config, session keys) lives at `/data/app_data/filestash/` and is kept separate from your files.

Data survives app redeployments and container restarts.

## Deploying

```bash
oh app deploy https://github.com/your-org/openhost-filestash --name filestash --wait
```

To update after pushing changes:

```bash
git commit -am "..." && git push
oh app reload filestash --update --wait
oh app logs filestash
```

## Local development

Requires [just](https://github.com/casey/just) and [Podman](https://podman.io).

```bash
just test   # clean build + fresh data; runs at http://localhost:8334
just run    # rebuild, keep existing data (for testing persistence across restarts)
just build  # build the image only
```

Local data is written to `test-data/` (gitignored).

## License

Filestash is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). The container image built from this repo is distributed under that license. The packaging files original to this repository are additionally available under the MIT License. See LICENSE and NOTICE for details.
