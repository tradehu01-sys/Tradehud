#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = resolve(__dirname, '..');

const accessToken = process.env.SUPABASE_ACCESS_TOKEN;
const projectRef = process.env.PROJECT_REF || process.env.SUPABASE_PROJECT_REF;
const dryRun = process.argv.includes('--dry-run');

if (!accessToken && !dryRun) {
  console.error('Missing SUPABASE_ACCESS_TOKEN. Create it in Supabase Dashboard → Account → Access Tokens.');
  process.exit(1);
}

if (!projectRef && !dryRun) {
  console.error('Missing PROJECT_REF or SUPABASE_PROJECT_REF. Use the ref from your Supabase project URL.');
  process.exit(1);
}

const [confirmationContent, recoveryContent] = await Promise.all([
  readFile(resolve(rootDir, 'supabase/templates/confirmation.html'), 'utf8'),
  readFile(resolve(rootDir, 'supabase/templates/recovery.html'), 'utf8')
]);

const payload = {
  mailer_subjects_confirmation: 'Confirma tu cuenta de TradeHub MMORPG',
  mailer_templates_confirmation_content: confirmationContent,
  mailer_subjects_recovery: 'Restablece tu contraseña de TradeHub MMORPG',
  mailer_templates_recovery_content: recoveryContent
};

if (dryRun) {
  console.log(JSON.stringify(payload, null, 2));
  process.exit(0);
}

const response = await fetch(`https://api.supabase.com/v1/projects/${projectRef}/config/auth`, {
  method: 'PATCH',
  headers: {
    Authorization: `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(payload)
});

const body = await response.text();
if (!response.ok) {
  console.error(`Supabase Auth config update failed (${response.status}):`);
  console.error(body);
  process.exit(1);
}

console.log('TradeHub auth email templates updated successfully.');
console.log('Updated: confirmation subject/content and recovery subject/content.');
