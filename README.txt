SITE DAILY - Stage 2 (offline-first daily entry app)

FILES
 index.html, sw.js, manifest.json, icon.svg, icon-192.png  = the app (upload all 5 together)
 schema_supabase.sql                                       = online database (run once in Supabase)

SETUP (one time, about 15 minutes, needs internet)
 1. Host the app files on any free HTTPS host: Netlify Drop (drag the folder), Cloudflare Pages or GitHub Pages.
 2. Open the link on each phone, wait for it to load once, then Add to Home Screen. After that it opens with no signal.
 3. supabase.com -> New project (free). SQL Editor -> paste schema_supabase.sql -> Run.
 4. Supabase -> Authentication -> Users -> Add user (one per person: email + password).
 5. Supabase -> Project Settings -> API: copy the Project URL and the anon public key.
 6. In the app: Setup -> Sync -> paste URL, key, email, password -> Sign in & sync.
 From then on: work offline, and everything uploads automatically when signal returns.

BEFORE TRUSTING COST REPORTS
 Update labour rates, contract rates (CONTROL sheet values were samples) and material prices in Setup.
 Fill each run's size / ways / length in the Runs tab (the workbook rows had none).
