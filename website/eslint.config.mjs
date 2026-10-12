import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTypeScript from "eslint-config-next/typescript";

export default defineConfig([
  ...nextVitals,
  ...nextTypeScript,
  globalIgnores([".next/**", "out/**"]),
  {
    rules: {
      // Website ordering is intentionally client-driven (Supabase anon auth + cart hydration);
      // these effects hydrate localStorage/supabase and are correctly gated.
      "react-hooks/set-state-in-effect": "off",
    },
  },
]);
