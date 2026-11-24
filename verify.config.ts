import { defineConfig } from '@revyl/verify';

// Verify targets for the Artex web UI. See the README's "Verify" section.
//
// The Artex base URL is read from ARTEX_BASE_URL (a public HTTPS URL that
// Revyl's hosted browser can reach, e.g. a tunnel/preview of your local Artex),
// and the Revyl web app id from REVYL_WEB_APP_ID. Nothing environment-specific
// is committed.
export default defineConfig({
  targets: {
    artex: {
      platform: 'web',
      app: {
        appId: process.env.REVYL_WEB_APP_ID ?? '',
        url: process.env.ARTEX_BASE_URL ?? '',
      },
      viewport: { width: 1440, height: 900 },
    },
  },
  stepTimeout: 240_000,
});
