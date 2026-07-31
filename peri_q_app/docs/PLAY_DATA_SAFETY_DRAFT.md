# Google Play Data Safety Draft

This is an engineering draft, not a submission. The owner is responsible for checking the production Supabase configuration, every enabled provider/SDK, retention practice and the current Play Console definitions before submitting. All apps on closed/open/production tracks must complete the form; internal-only apps are treated differently by Play.

| Data type | Collected | Shared | Purpose | Required? | Ephemeral? | Transit encryption | Deletion | Collector |
|---|---|---|---|---|---|---|---|---|
| Name | Yes | No* | Order fulfilment/account | Required at checkout | No | HTTPS/TLS | In-app account deletion/support request | App → Supabase |
| Email | For email accounts | No* | Authentication/account management | Optional; not needed for guest | No | HTTPS/TLS | Account deletion | Supabase Auth |
| Phone number | Yes | No* | Account contact and order fulfilment; not authentication | Required at checkout | No | HTTPS/TLS | Account deletion | App → Supabase |
| Delivery address | Delivery only | No* | Deliver order | Optional unless delivery | No; also saved locally if user chooses | HTTPS/TLS remotely | Delete saved address/account | App/SharedPreferences/Supabase order |
| Authentication data/session identifier | Yes | No* | Sign-in, guest isolation, security | Required for backend order isolation | Session processing plus encrypted persisted token | HTTPS/TLS | Sign out/account deletion | Supabase Auth SDK + Android encrypted storage |
| Order history/items/notes/status | Yes | No* | Fulfilment, support, business records | Required to place an order | No | HTTPS/TLS | Current implementation deletes with account | Supabase database |
| EFT proof image/PDF | EFT only | No* | Payment reconciliation | Optional unless user chooses/proceeds with EFT proof | No | HTTPS/TLS | Removed before account deletion; support request | System picker → private Supabase Storage |
| App interactions | Minimal operational requests | No* | Core functionality/security | Required for features | Partly | HTTPS/TLS | Follows associated account/data | Supabase service logs—owner must verify retention |
| Crash diagnostics/analytics | No SDK configured | No | N/A | N/A | N/A | N/A | N/A | None in app |
| Device or other identifier (FCM token and random installation ID) | Yes | No* | Deliver transactional order and status notifications; fraud/spam prevention | Optional; notification permission can be denied | No | HTTPS/TLS | Removed on sign-out/account deletion; invalid tokens pruned | App → Supabase → Firebase Cloud Messaging |
| Advertising identifiers | No | No | N/A | N/A | N/A | N/A | N/A | No ads/tracking SDK |

`No*` assumes Supabase is used only as the owner's service provider and data is not transferred to independent third parties for their own purposes. Google Play's definition of “shared” and applicable service-provider exceptions must be reviewed against the owner's Supabase contract, hosting region, support workflows and any exports.

## Security and retention answers to verify

- Data is encrypted in transit by HTTPS/WSS when the production Supabase URL uses HTTPS.
- The application supports guest use, account creation and in-app account deletion. A public web deletion URL is still mandatory and must be supplied.
- The current schema cascades profiles/orders/items on user deletion and the app removes private proof files first. The owner must decide whether any lawful financial retention is required before production; if retention is required, redesign deletion/anonymisation and update the policy/declaration before launch.
- Auth sessions and PKCE verifier data use encrypted Android storage and migrate away from legacy SharedPreferences. Saved addresses/customer details remain in app-private SharedPreferences and are removed during in-app deletion; Android backup is disabled.
- Supabase platform/auth/database/storage logs and backups may have separate retention. Verify and disclose their behaviour.
- Firebase Cloud Messaging receives device tokens and notification delivery data as a service provider. Verify Google's retention and Play Data Safety treatment, and update the public privacy policy before production.
- Confirm no SDK or infrastructure was added after this audit, and verify whether support staff export personal data outside Supabase.

Official guidance: https://support.google.com/googleplay/android-developer/answer/10787469
