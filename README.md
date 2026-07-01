# Filestash

[Filestash](https://www.filestash.app) is a web-based file manager. This repo packages it as an OpenHost app, storing files in the zone's persistent volume and using OpenHost's built-in auth so no separate login is needed.

## What it does

Filestash gives you a browser-based interface to your files. It works on any browser, no client software required.

**Browsing and organizing** — browse directories, create and delete folders, rename files and folders, sort by name, date, or size, toggle hidden files.

**Uploading and downloading** — drag-and-drop or file-picker upload; download any file or folder as a zip.

**Previews** — renders inline without downloading: images, video, audio, PDFs, text and code (with syntax highlighting), Markdown (rendered), and more.

**Editing** — text files and code can be edited directly in the browser and saved back.

**Sharing** — any file or folder can be shared via a public link. The link works without logging in and grants read-only access to that path.

## Access

All routes require the zone owner to be logged in. Share links are the exception — they bypass auth and give anyone with the link read-only access to the specific file or folder.

## Storage

Files are stored at `/data/` in the zone's persistent volume — the same root shared across all apps that request `access_all_data`. The app's own state (config, session keys) lives at `/data/app_data/filestash/` and is kept separate from your files.

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
