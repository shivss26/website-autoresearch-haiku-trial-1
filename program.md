# Website Autoresearch

You are an autonomous web researcher. Your job is to improve a website's Lighthouse scores through iterative experiments.

## Setup

1. **Read the in-scope files** for full context:
   - `index.html` — the page you modify.
   - `styles.css` — the stylesheet you modify.
   - `script.js` — the JavaScript you modify.
2. **Read `results.tsv`** to see what experiments have already been tried. Do NOT repeat experiments that were already discarded. Build on what worked.
3. **Run a baseline audit** if results.tsv is empty (see Measurement below).

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

You MUST use the Lighthouse CLI to measure all 4 categories in a single run. Always append a cache-busting query parameter using the current git commit hash to avoid GitHub Pages CDN cache.

**Steps:**
1. Get the current commit hash: `git rev-parse --short HEAD`
2. Run Lighthouse:
   ```
   npx lighthouse "https://shivss26.github.io/website-autoresearch-haiku-trial-1/?v=COMMIT_HASH" --output=json --output-path=./lighthouse-report.json --chrome-flags="--headless"
   ```
3. Extract scores:
   ```
   python -c "import json; d=json.load(open('lighthouse-report.json')); [print(f'{k}: {int(d[\"categories\"][k][\"score\"]*100)}') for k in ['performance','accessibility','best-practices','seo']]"
   ```

Do NOT guess or estimate scores. Always measure.

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

Every experiment is committed and pushed to GitHub so the full history is visible. There are no reverts — discarded experiments stay in the history, labeled clearly.

LOOP:

1. Read the current code and results.tsv to understand the current state and what's been tried.
2. Propose a hypothesis: decide what to change and why you think it will improve scores.
3. Make the change to the code.
4. `git add` the changed files and `git commit` with a descriptive message prefixed with `[EXPERIMENT]`.
5. `git push` to trigger a GitHub Pages deploy.
6. Wait 60 seconds for the deploy to propagate.
7. Run Lighthouse CLI with cache-busting commit hash (see Measurement).
8. Compare scores against the previous baseline.
9. Decide: keep or discard?
   - If the composite score improved: this is a **keep**. This becomes the new baseline.
   - If the composite score did not improve or regressed: this is a **discard**. Revert the code to the previous state, commit with `[DISCARD]` prefix, and push.
10. Log the result in `results.tsv`, commit and push the updated TSV.
11. Exit. The next agent invocation will continue from step 1.

**Commit message format:**
- Baseline: `[BASELINE] initial page state`
- Kept experiments: `[KEEP] added semantic HTML landmarks`
- Experiment (before decision): `[EXPERIMENT] replaced table layout with flexbox`
- Discarded reverts: `[DISCARD] revert: replaced table layout with flexbox`

**Target: 90 composite.** Once you hit 90 or above on a kept experiment, log it and exit.

## Important rules

- **One change at a time.** Each experiment should test ONE idea. Don't bundle multiple changes — it makes it impossible to know what helped.
- **Don't repeat failed experiments.** Always read results.tsv first. If something was already tried and discarded, don't try the same thing again.
- **The baseline ratchets forward.** When an experiment is kept, it becomes the new baseline. Always compare against the most recent kept version, not the original.
- **Push after every commit.** Every commit gets pushed so the full experiment history is preserved on GitHub.
- **Clean up after yourself.** Delete `lighthouse-report.json` before exiting (it's large and shouldn't be committed).
- **Do ONE experiment per session, then exit.** The wrapper script handles restarting you.
