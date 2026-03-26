# Website Autoresearch

You are an autonomous web researcher. Your job is to improve a website's Lighthouse scores through iterative experiments.

## Setup

1. **Check if an experiment branch exists.** Run `git branch`. If `autoresearch` branch exists, switch to it. If not, create it: `git checkout -b autoresearch`. All work happens on this branch, never on master.
2. **Read the in-scope files** for full context:
   - `index.html` — the page you modify.
   - `styles.css` — the stylesheet you modify.
   - `script.js` — the JavaScript you modify.
3. **Read `results.tsv`** to see what experiments have already been tried. Do NOT repeat experiments that were already discarded. Build on what worked.
4. **Run a baseline audit** if results.tsv has no entries yet (see Measurement below).

## Experimentation

Each experiment modifies the website and measures the result using Lighthouse.

**What you CAN do:**
- Modify `index.html`, `styles.css`, and `script.js`. These are the only files you edit.
- Add, remove, or replace files in `assets/`.
- Everything is fair game: HTML structure, CSS, JavaScript, images, meta tags, accessibility, semantics, performance.

**What you CANNOT do:**
- Modify `program.md`. It is read-only.
- Modify `results.tsv` except to append new rows.
- Install packages or add build tools. This is plain HTML/CSS/JS with no build step.

**The goal is simple: get the highest composite Lighthouse score.** The composite score is the average of Performance, Accessibility, Best Practices, and SEO (each 0-100).

**Simplicity criterion**: All else being equal, simpler is better. A small improvement that adds ugly complexity is not worth it. Clean, readable code that scores well is the goal.

## Measurement

Use the Lighthouse CLI to measure all 4 categories. Run it exactly ONCE per experiment — do not retry or run multiple times.

Always append a cache-busting query parameter using the current git commit hash to avoid GitHub Pages CDN cache.

**Steps:**
1. Get the current commit hash: `HASH=$(git rev-parse --short HEAD)`
2. Run Lighthouse exactly once:
   ```
   npx lighthouse "https://shivss26.github.io/website-autoresearch-haiku-trial-1/?v=$HASH" --output=json --output-path=./lighthouse-report.json --chrome-flags="--headless" 2>/dev/null
   ```
3. Extract scores:
   ```
   python -c "import json; d=json.load(open('lighthouse-report.json')); [print(f'{k}: {int(d[\"categories\"][k][\"score\"]*100)}') for k in ['performance','accessibility','best-practices','seo']]"
   ```
4. Delete the report immediately after extracting scores:
   ```
   rm -f lighthouse-report.json
   ```

Do NOT guess or estimate scores. Always measure. Do NOT run Lighthouse more than once per experiment.

## Output format

After each Lighthouse audit, report scores like this:

```
===== LIGHTHOUSE SCORES =====
performance:    XX
accessibility:  XX
best-practices: XX
seo:            XX
composite:      XX.X
=============================
```

## Logging results

Log every experiment to `results.tsv` (tab-separated, NOT comma-separated).

The TSV has a header row and 8 columns:

```
commit	perf	a11y	bp	seo	composite	status	description
```

1. git commit hash (short, 7 chars)
2. performance score (0-100)
3. accessibility score (0-100)
4. best-practices score (0-100)
5. seo score (0-100)
6. composite (average of the four, one decimal)
7. status: `baseline`, `keep`, or `discard`
8. short text description of what this experiment tried

Example:

```
commit	perf	a11y	bp	seo	composite	status	description
d35057d	28	56	69	64	54.3	baseline	initial page state
a1b2c3d	45	62	74	70	62.8	keep	removed render-blocking script
b2c3d4e	42	60	71	68	60.3	discard	replaced all images with SVGs
```

## The experiment loop

All work happens on the `autoresearch` branch. Every experiment is committed and pushed so the full history is visible.

LOOP:

1. Read the current code and results.tsv to understand the current state and what's been tried.
2. Propose a hypothesis: decide what to change and why you think it will improve scores.
3. Make the change to the code.
4. `git add` the changed files, `git commit` with a descriptive message prefixed with `[EXPERIMENT]`.
5. Update `results.tsv` with a new row (status TBD, leave as `pending` for now). Amend the commit: `git add results.tsv && git commit --amend --no-edit`.
6. `git push -u origin autoresearch` to trigger a GitHub Pages deploy.
7. Wait 60 seconds for the deploy to propagate.
8. Run Lighthouse CLI exactly once with cache-busting commit hash (see Measurement).
9. Delete `lighthouse-report.json` immediately after extracting scores.
10. Compare composite score against the previous baseline (the most recent `keep` or `baseline` row in results.tsv).
11. Decide: keep or discard?
    - If the composite score improved: Update the `pending` row in results.tsv to `keep`. Commit with message `[KEEP] <description>` and push.
    - If the composite score did not improve: Revert the code files (not results.tsv) to their previous state. Update the `pending` row to `discard`. Commit with message `[DISCARD] revert: <description>` and push.
12. Exit. The next agent invocation will continue from step 1.

**Commit message format:**
- Experiment + TSV log: `[EXPERIMENT] replaced table layout with flexbox`
- Kept (after measurement): `[KEEP] replaced table layout with flexbox`
- Discarded (revert + log): `[DISCARD] revert: replaced table layout with flexbox`

This means each experiment produces exactly 2 commits: the experiment itself, and the keep/discard result.

**Target: 90 composite.** Once you hit 90 or above on a kept experiment, log it and exit.

## Important rules

- **One change at a time.** Each experiment should test ONE idea. Don't bundle multiple changes.
- **Don't repeat failed experiments.** Always read results.tsv first. If something was already tried and discarded, don't try it again.
- **The baseline ratchets forward.** When an experiment is kept, it becomes the new baseline. Always compare against the most recent kept version.
- **Run Lighthouse exactly once per experiment.** Do not retry. If it fails, log the experiment as `error` and exit.
- **Delete lighthouse-report.json after every run.** Do not leave report files in the directory.
- **Never work on master.** All experiments happen on the `autoresearch` branch.
- **Do ONE experiment per session, then exit.** The wrapper script handles restarting you.
