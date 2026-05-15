#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const TEMPLATE_DIR = path.resolve(__dirname, '..', 'template');
const TARGET = process.cwd();

if (!fs.existsSync(TEMPLATE_DIR)) {
  console.error(`pi-llm-wiki-init: bundled template not found at ${TEMPLATE_DIR}`);
  console.error('This is a packaging bug — please file an issue.');
  process.exit(2);
}

if (fs.existsSync(path.join(TARGET, 'AGENTS.md'))) {
  console.error(`pi-llm-wiki-init: AGENTS.md already exists in ${TARGET}`);
  console.error('This directory already looks like an llm-wiki. Run /wiki-new to customize it in place,');
  console.error('or move/remove AGENTS.md if you really want to re-initialize from the bundled template.');
  process.exit(1);
}

const created = [];
const skipped = [];

function copyTree(src, dst) {
  const stat = fs.statSync(src);
  if (stat.isDirectory()) {
    if (!fs.existsSync(dst)) fs.mkdirSync(dst, { recursive: true });
    for (const entry of fs.readdirSync(src)) {
      copyTree(path.join(src, entry), path.join(dst, entry));
    }
  } else {
    const rel = path.relative(TARGET, dst);
    if (fs.existsSync(dst)) {
      skipped.push(rel);
    } else {
      fs.copyFileSync(src, dst);
      created.push(rel);
    }
  }
}

for (const entry of fs.readdirSync(TEMPLATE_DIR)) {
  copyTree(path.join(TEMPLATE_DIR, entry), path.join(TARGET, entry));
}

console.log(`pi-llm-wiki-init: initialized llm-wiki template in ${TARGET}`);
console.log(`  created: ${created.length} file(s)`);
if (skipped.length > 0) {
  console.log(`  skipped: ${skipped.length} file(s) that already existed:`);
  for (const f of skipped) console.log(`    - ${f}`);
}
console.log('');
console.log('Next:');
console.log('  1. Run /wiki-new <domain description> in pi to customize the placeholders.');
console.log('  2. Run /wiki-project-init to scaffold project/ and customize ## Implementation Workspace.');
console.log('  3. Run /wiki-kanban-board <slug> to bind a Hermes board (required by /wiki-kanban-emit and /wiki-kanban-ingest).');
console.log('  4. Drop source files into raw/ and run /wiki-ingest <path>.');
