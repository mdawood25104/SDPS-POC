# Smart Parking Management System POC

## Run locally
1. Add your Supabase URL and anon key to the `.env`.
2. In the Supabase SQL Editor, run `supabase/schema.sql`.
3. Run `npm install`.
4. Run `npm run dev`.

Without Supabase credentials, the app uses a browser-local fallback for demonstration. This fallback is not shared between users or devices.

## Permanent Vercel deployment

1. Create or choose a permanent Vercel project owned by your account or team.
2. In Supabase, run `supabase/schema.sql` against the production project.
3. In the Vercel project settings, add these **Production** environment variables:
	- `VITE_SUPABASE_URL`
	- `VITE_SUPABASE_ANON_KEY`
4. Deploy from the repository root:

	```bash
	npx vercel --prod
	```

	The first run will prompt you to log in and link the local folder to the permanent Vercel project. Do not commit `.env` or service-role keys.

`vercel.json` provides the SPA fallback required when a deployed URL is refreshed. The Supabase anon key is intended for browser use, but the current POC policies allow public CRUD access; add Supabase Auth and user-scoped RLS policies before using this with real customer or payment data.

The app has a localStorage fallback if Supabase credentials are not configured, so the UI and complete demo flow can be tested immediately. When Supabase is configured, data is persisted in Supabase and realtime subscriptions are enabled.

## Main demo
Dashboard -> Entry / Exit -> enter LEA-1234 -> select a free space -> Confirm Entry -> search LEA-1234 in exit panel -> Find Active Session -> Mark as Paid & Complete Exit.

AI Detection Simulator is explicitly labelled as a simulation.
