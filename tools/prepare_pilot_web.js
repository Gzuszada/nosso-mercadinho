const fs = require('fs');
const path = require('path');

const buildWebDir = path.resolve(__dirname, '..', 'build', 'web');
const indexPath = path.join(buildWebDir, 'index.html');
const manifestPath = path.join(buildWebDir, 'manifest.json');

if (!fs.existsSync(indexPath) || !fs.existsSync(manifestPath)) {
  throw new Error('Pilot Web build not found. Run the pilot Flutter build first.');
}

const index = fs.readFileSync(indexPath, 'utf8');
const originalTitle = '<title>Nosso Mercado</title>';
const pilotTitle = '<title>Nosso Mercado — Piloto</title>';
if (index.includes(originalTitle)) {
  fs.writeFileSync(indexPath, index.replace(originalTitle, pilotTitle));
} else if (!index.includes(pilotTitle)) {
  throw new Error(`Expected title not found in ${indexPath}`);
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
manifest.name = 'Nosso Mercado — Piloto';
manifest.short_name = 'Mercado Piloto';
manifest.description = 'Piloto do mercado compartilhado com sincronização v2.';
fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);

console.log('Pilot Web identity applied to build/web.');
