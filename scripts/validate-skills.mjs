#!/usr/bin/env node

import { readdir, readFile } from "node:fs/promises";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");

function parseFrontmatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) return null;

  const fields = {};
  for (const line of match[1].split("\n")) {
    const keyMatch = line.match(/^([a-zA-Z0-9_-]+):\s*(.*)$/);
    if (keyMatch) {
      fields[keyMatch[1]] = keyMatch[2].trim();
    }
  }

  return fields;
}

async function main() {
  const entries = await readdir(ROOT, { withFileTypes: true });
  const skillDirs = entries.filter(
    (entry) =>
      entry.isDirectory() &&
      !entry.name.startsWith(".") &&
      entry.name !== "scripts",
  );

  if (skillDirs.length === 0) {
    console.error("No skill directories found.");
    process.exit(1);
  }

  let hasErrors = false;

  for (const entry of skillDirs) {
    const skillPath = join(ROOT, entry.name, "SKILL.md");
    let content;

    try {
      content = await readFile(skillPath, "utf8");
    } catch {
      console.error(`✗ ${entry.name}/ — missing SKILL.md`);
      hasErrors = true;
      continue;
    }

    const meta = parseFrontmatter(content);
    if (!meta) {
      console.error(`✗ ${entry.name}/SKILL.md — missing YAML frontmatter`);
      hasErrors = true;
      continue;
    }

    if (!meta.name) {
      console.error(`✗ ${entry.name}/SKILL.md — missing 'name' in frontmatter`);
      hasErrors = true;
    } else if (meta.name !== entry.name) {
      console.warn(
        `⚠ ${entry.name}/ — folder name differs from frontmatter name '${meta.name}'`,
      );
    }

    if (!meta.description) {
      console.error(`✗ ${entry.name}/SKILL.md — missing 'description' in frontmatter`);
      hasErrors = true;
    }

    if (!hasErrors) {
      console.log(`✓ ${entry.name}`);
    }
  }

  if (hasErrors) {
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
