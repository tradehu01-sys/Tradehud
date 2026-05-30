CREATE TABLE IF NOT EXISTS public.gold_game_options (
  game text PRIMARY KEY,
  faction_disabled boolean NOT NULL DEFAULT false,
  faction_options text[] NOT NULL DEFAULT ARRAY['Alianza','Horda','Neutral'],
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.gold_game_options ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "gold_game_options_public_read" ON public.gold_game_options;
CREATE POLICY "gold_game_options_public_read"
  ON public.gold_game_options
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "gold_game_options_admin_write" ON public.gold_game_options;
CREATE POLICY "gold_game_options_admin_write"
  ON public.gold_game_options
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.user_profiles p
      WHERE p.id = auth.uid() AND p.is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.user_profiles p
      WHERE p.id = auth.uid() AND p.is_admin = true
    )
  );

DROP POLICY IF EXISTS "gold_game_options_admin_panel_write" ON public.gold_game_options;
CREATE POLICY "gold_game_options_admin_panel_write"
  ON public.gold_game_options
  FOR ALL
  TO anon
  USING (true)
  WITH CHECK (
    game IS NOT NULL
    AND length(trim(game)) > 0
    AND cardinality(faction_options) >= 0
  );

GRANT SELECT ON public.gold_game_options TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.gold_game_options TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.gold_game_options TO anon;
