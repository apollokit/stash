// Stash Configuration
// Replace these with your Supabase project details

const CONFIG = {
  // Your Supabase project URL (from Project Settings > API)
  SUPABASE_URL: 'https://fhrlhhvwsexqugphpkla.supabase.co',

  // Your Supabase anon/public key (from Project Settings > API)
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZocmxoaHZ3c2V4cXVncGhwa2xhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3OTA2OTMsImV4cCI6MjA4NDM2NjY5M30._fwlGHw_x41tP-_mMaTLYvpIrEfhrX87Gt2IKN_ScAs',

  // Your web app URL (after deploying to Vercel/Netlify)
  WEB_APP_URL: 'https://your-stash-app.vercel.app',

  // Your user ID from Supabase (Authentication > Users)
  // For multi-user mode, this can be removed and auth will be required
  USER_ID: 'a4d6873f-e502-4b9e-a90d-5fa5bf46cbf2',
};

// Don't edit below this line
if (typeof module !== 'undefined') {
  module.exports = CONFIG;
}
