import { readFileSync, writeFileSync } from 'node:fs';

const root = new URL('../', import.meta.url);
const read = name => readFileSync(new URL(name, root), 'utf8');

const config = JSON.parse(read('config.json'));
const { redirects } = JSON.parse(read('redirects.json'));
if (!Array.isArray(redirects)) {
  throw new Error('redirects.json has no "redirects" array');
}

const text = `${JSON.stringify({ ...config, redirects }, null, 2)}\n`;
const target = new URL('serve.json', root);

if (process.argv[2] === '--check') {
  if (read('serve.json') !== text) {
    console.error(
      'serve.json differs from config.json + redirects.json; ' +
        'run node scripts/serve-json.mjs'
    );
    process.exit(1);
  }
} else {
  writeFileSync(target, text);
}
