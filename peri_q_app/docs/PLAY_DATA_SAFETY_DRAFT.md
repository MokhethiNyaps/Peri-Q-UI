# Google Play Data Safety Draft

This is an engineering draft, not a submission. The owner is responsible for checking the production Supabase configuration, every enabled provider/SDK, retention practice and the current Play Console definitions before submitting. All apps on closed/open/production tracks must complete the form; internal-only apps are treated differently by Play.

| Data type | Collected | Shared | Purpose | Required? | Ephemeral? | Transit encryption | Deletion | Collector |
|---|---|---|---|---|---|---|---|---|
| Name | Yes | No* | Order fulfilment | Required at checkout | No | HTTPS/TLS | Support/deletion request | App → Supabase |
| Phone number | Yes | No* | Order contact/fulfilment | Required at checkout | No | HTTPS/TLS | Support/deletion request | App → Supabase |
| Delivery address | Delivery only | No* | Deliver order | Optional unless delivery | No; also saved locally if user chooses | HTTPS/TLS remotely | Delete locally saved address; support/deletion request for order data | App/SharedPreferences/Supabase order |
| Authentication data/session identifier | Yes | No* | Guest isolation and security | Required for backend order isolation | Session processing plus encrypted persisted token | HTTPS/TLS | Support/deletion request | Supabase Auth SDK + Android encrypted storage |
| Order history/items/notes/status | Yes | No* | Fulfilment, support, business records | Required to place an order | No | HTTPS/TLS | Support/deletion request subject to required retention | Supabase database |
| EFT proof image/PDF | EFT only | No* | Payment reconciliation | Optional unless user chooses/proceeds with EFT proof | No | HTTPS/TLS | Support/deletion request | System picker → private Supabase Storage |
| App interactions | Minimal operational requests | No* | Core functionality/security | Required for features | Partly | HTTPS/TLS | Follows associated data and provider retention | Supabase service logs—owner must verify retention |
| Crash diagnostics/analytics | No SDK configured | No | N/A | N/A | N/A | N/A | N/A | None in app |
| Push token/notifications | No | No | N/A | N/A | N/A | N/A | N/A | FCM not configured |
| Advertising identifiers | No | No | N/A | N/A | N/A | N/A | N/A | No ads/tracking SDK |

`No*` assumes Supabase is used only as the owner's service provider and data is not transferred to independent third parties for their own purposes. Google Play's definition of “shared” and applicable service-provider exceptions must be reviewed against the owner's Supabase contract, hosting region, support workflows and any exports.

## Security and retention answers to verify

- Data is encrypted in transit by HTTPS/WSS when the production Supabase URL uses HTTPS.
- Version 1.0.2 supports anonymous guest use only. Customer login, account creation, password recovery, sign-out and in-app registered-account deletion are not offered. The public deletion/support URL remains available for legacy requests.
- The current schema cascades profiles/orders/items on user deletion and the app removes private proof files first. The owner must decide whether any lawful financial retention is required before production; if retention is required, redesign deletion/anonymisation and update the policy/declaration before launch.
- Anonymous Auth sessions use encrypted Android storage. Saved addresses/customer details remain in app-private SharedPreferences; Android backup is disabled.
- Supabase platform/auth/database/storage logs and backups may have separate retention. Verify and disclose their behaviour.
- Confirm no SDK or infrastructure was added after this audit, and verify whether support staff export personal data outside Supabase.

Official guidance: https://support.google.com/googleplay/android-developer/answer/10787469
