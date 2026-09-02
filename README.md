# Filestash

[Filestash](https://www.filestash.app) is a web-based file manager. This repo packages it as an OpenHost app, storing files in the zone's persistent volume and using OpenHost's built-in auth so no separate login is needed.

## What it does

Filestash gives you a browser-based interface to your files. It works on any browser, no client software required.

**Browsing and organizing.** Browse directories, create and delete folders, rename files and folders, sort by name, date, or size, toggle hidden files.

**Uploading and downloading.** Drag-and-drop or file-picker upload; download any file or folder as a zip.

**Previews.** Renders inline without downloading: images, video, audio, PDFs, text and code (with syntax highlighting), Markdown (rendered), and more.

**Editing.** Text files and code can be edited directly in the browser and saved back.

**Sharing.** Disabled by this package so the default file browser remains owner-only.

## Access

Browsing, uploading, editing and the admin panel all require the zone owner to be
logged in. Anonymous requests to those paths are redirected to the zone login.

No application paths are public. The container also sets upstream Filestash's
`features.share.enable` setting to `false` on every startup, which hides the Share
action. An administrator can change that setting for the running process, but
OpenHost still requires owner authentication for every route and the next restart
disables the feature again.

## Why sharing is disabled

Filestash share links are bearer credentials, while this app can access every
app's persistent data. A separate sharing-enabled package can expose the required
routes explicitly if that tradeoff is desired; this default package does not.

## Storage

Files are stored at `/data/` in the zone's persistent volume, the same root shared across all apps that request `access_all_app_data`. The app's own state (config, session keys) lives in its OpenHost app-data directory and is kept separate from your files.

Data survives app redeployments and container restarts.

## Deploying

```bash
oh app deploy https://github.com/your-org/openhost-filestash --name file-browser --wait
```

To update after pushing changes:

```bash
git commit -am "..." && git push
oh app reload file-browser --update --wait
oh app logs file-browser
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
