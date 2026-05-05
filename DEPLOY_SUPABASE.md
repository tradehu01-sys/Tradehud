# Deploy y conexión Supabase (TradeHud)

## 1) Variables de entorno correctas
En Vercel/Netlify/hosting configura **solo** estas públicas para frontend:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` (o `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`)

No uses `service_role` en frontend.

## 2) Aplicar schema completo
Ejecuta **SCHEMA_COMPLETO.sql** en Supabase SQL Editor. Ese archivo incluye:
- Tablas (`user_profiles`, `tickets`, `games`, `gold_categories`, etc.)
- RLS y policies
- Bucket `tradehud-assets` + policies de storage
- Seeds mínimos

## 3) Verificación rápida
Después de correr schema:
1. Confirma que existe tabla `public.games` con columna `services` (`text[]`).
2. Confirma que existe tabla `public.app_assets`.
3. Confirma bucket `tradehud-assets` público.

## 4) Cambios de robustez incluidos en este repo
`index.html` ahora limpia valores pegados con saltos de línea o texto extra (por ejemplo copiar/pegar variables con etiquetas), y detecta automáticamente:
- URL Supabase válida
- `anon jwt` o `sb_publishable_*`

Con eso evita errores comunes de deploy por variables mal pegadas.
