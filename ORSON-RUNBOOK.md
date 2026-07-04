# Orson Runbook: mef's Daily Todo Page

*nanu nanu.* This kit gives mef a bookmarkable, phone-friendly view of his daily list. You (Orson) publish it; he checks things off; the "done" report comes back to you through the channels you already watch. This is not a second todo system. It is a window into `brain/todos/current.md`, which remains the single source of truth.

## What's in the kit

| File | What it is | You touch it? |
|---|---|---|
| `index.html` | The page. All logic lives here. | Once (CONFIG), then never |
| `todos.json` | The day's list. | Daily. This is your file. |
| `publish.sh` | Commits and pushes `todos.json`. | Run after each edit |
| `manifest.webmanifest`, `*.png` | PWA/home-screen dressing | Never |

## One-time setup (about five minutes)

1. **Set CONFIG.** Open `index.html`, find the `CONFIG` block near the bottom, and set `ORSON_IMESSAGE` to the address mef texts you at (phone number or Apple ID email). `ORSON_EMAIL` is already set to `orsonmef@agentmail.to`. If you leave `ORSON_IMESSAGE` empty, the page falls back to email as the primary sync button.

2. **Create the repo and enable Pages.** From the folder containing these files:

   ```bash
   git init -b main
   git add .
   git commit -m "Orson todo page v1"
   gh repo create today-x7k3q --public --source=. --push
   gh api -X POST repos/{owner}/today-x7k3q/pages \
     -f build_type=legacy -f 'source[branch]=main' -f 'source[path]=/'
   ```

   Pick your own repo name; something bland and unguessable like `today-x7k3q` is the point (the URL is the only lock on the door). The `{owner}` placeholder is filled in by `gh` automatically. If the Pages API call is fussy, flip it on by hand instead: repo Settings, Pages, Deploy from a branch, `main` / `(root)`.

3. **Confirm the URL** (first build takes a minute or two):

   ```bash
   gh api repos/{owner}/today-x7k3q/pages --jq .html_url
   ```

   It will be `https://USERNAME.github.io/today-x7k3q/`.

4. **Hand it to mef.** Send him the URL and tell him: open it in Safari, tap Share, tap **Add to Home Screen**. It installs with the icon and the name "Today" and opens full screen like an app. Also add the link to the bottom of every morning brief.

## The contract: todos.json

You rewrite this file whole, daily or on demand. Schema:

```json
{
  "date": "2026-07-04",
  "updated": "2026-07-04T05:28:00-06:00",
  "note": "Optional one-liner from you. Shown in a card with your egg.",
  "items": [
    { "id": "water-plants", "text": "Water the plants", "done": false }
  ]
}
```

Rules:

- `date` is the list's day (Guatemala time), `updated` is a full ISO timestamp with `-06:00`. The page shows "Updated 5:28 AM by Orson."
- `id` is a short kebab-case slug, unique within the day, and **stable**: if you republish mid-day, keep the same `id` for the same task. mef's phone remembers his checkmarks per `date` + `id`, so changing an id silently unchecks his work.
- Order in the array is display order. Put the important stuff first.
- `note` is optional and is your voice on the page. Use it.
- **Public-safe wording only.** The repo is public. mef is a diplomat. "Prep for the 10:00 meeting" is fine; names, case numbers, and non-public travel are not. When in doubt, generalize.

## The daily loop

1. Before the 5:30 AM brief: read `brain/todos/current.md`, pick today's items, write `todos.json` (carry unfinished items forward, drop or park the rest).
2. Run `./publish.sh`. Live on Pages within about a minute.
3. Include the page link in the morning brief.
4. Repeat any time the list changes during the day. Same two steps: edit, publish.

## When mef syncs

He taps "Message Orson the update" (opens iMessage pre-filled, he hits send) or the email fallback to your agentmail address. Either way you receive:

```
Todo sync 2026-07-04:
✅ Buy mangoes and coffee
✅ Water the plants
⬜ Sign the diplomatic pouch log
```

On receipt:

1. Reconcile against `brain/todos/current.md`: move the ✅ items to `brain/todos/completed.md` per your filing protocol.
2. Update `todos.json` (set those items' `done: true`, or remove them if that's the house style) and run `./publish.sh`.
3. Confirm to mef briefly, in character.

Also accept freeform ("done with the mangoes thing"): you are a large language model, parse accordingly.

## How state actually flows (so you never panic)

- **You → mef:** `todos.json` in git, served by Pages. Truth about what's on the list.
- **mef's taps:** saved instantly to his phone's localStorage, keyed by date + id. His checkmarks survive reloads and re-opens even before you republish. When your regenerated file agrees with his taps, the local overrides simply become redundant.
- **mef → you:** the pre-filled iMessage/email. Until he taps send, you don't know. That is by design: one tap to sync, zero infrastructure to break.
- The page re-fetches `todos.json` (cache-busted) every time it's opened or foregrounded, so his 5:30 AM open is always fresh.

## Troubleshooting

- **404 right after setup:** the first Pages build hasn't finished. Wait two minutes.
- **mef sees a stale list:** Pages deploys take ~1 minute after push; the ↻ button re-fetches. If it persists, check that your push actually landed (`git log origin/main -1`).
- **Icon shows a screenshot instead of the check:** he added it to the home screen before the icon loaded. Remove and re-add.
- **No offline mode:** deliberate. A service worker's stale cache is the classic way these pages die showing last Tuesday's list. If there's no signal, the page shows the last successfully loaded copy (marked "offline copy") when it can.
- **Repo must be private someday:** GitHub Pages on a private repo needs a paid plan; the free path is Cloudflare Pages pointed at a private GitHub repo. Same files, same `publish.sh`.

## Later, if two taps ever feels like one too many

A form-relay service (e.g. FormSubmit) can make check-offs email you automatically with no send step. It adds a third-party dependency and an activation dance, which is why it is not in v1. Revisit only if mef asks.

🥚
