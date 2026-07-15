#!/usr/bin/env node

import { readdir, readFile, writeFile } from "node:fs/promises";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const README_PATH = join(ROOT, "README.md");
const TABLE_START = "<!-- SKILLS_TABLE_START -->";
const TABLE_END = "<!-- SKILLS_TABLE_END -->";

function parseFrontmatter(content) {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) return {};

  const fields = {};
  const lines = match[1].split("\n");
  let currentKey = null;
  let currentValue = [];

  for (const line of lines) {
    const keyMatch = line.match(/^([a-zA-Z0-9_-]+):\s*(.*)$/);
    if (keyMatch) {
      if (currentKey) {
        fields[currentKey] = currentValue.join("\n").trim();
      }
      currentKey = keyMatch[1];
      currentValue = [keyMatch[2]];
      continue;
    }

    if (currentKey && /^\s/.test(line)) {
      currentValue.push(line.trim());
    }
  }

  if (currentKey) {
    fields[currentKey] = currentValue.join("\n").trim();
  }

  return fields;
}

async function collectSkills() {
  const entries = await readdir(ROOT, { withFileTypes: true });
  const skills = [];

  for (const entry of entries) {
    if (!entry.isDirectory() || entry.name === "scripts" || entry.name.startsWith(".")) {
      continue;
    }

    const skillPath = join(ROOT, entry.name, "SKILL.md");
    let content;
    try {
      content = await readFile(skillPath, "utf8");
    } catch {
      continue;
    }

    const meta = parseFrontmatter(content);
    const name = meta.name || entry.name;
    const description = (meta.description || "").replace(/\s+/g, " ").trim();

    if (!description) {
      throw new Error(`${entry.name}/SKILL.md is missing a description in frontmatter`);
    }

    skills.push({ name, description, folder: entry.name });
  }

  return skills.sort((a, b) => a.name.localeCompare(b.name));
}

function buildTable(skills) {
  const lines = [
    TABLE_START,
    "| Skill | Description |",
    "|-------|-------------|",
  ];

  for (const skill of skills) {
    lines.push(`| [${skill.name}](${skill.folder}) | ${skill.description} |`);
  }

  lines.push(TABLE_END);
  return lines.join("\n");
}

async function updateReadme(tableBlock) {
  const readme = await readFile(README_PATH, "utf8");

  if (!readme.includes(TABLE_START) || !readme.includes(TABLE_END)) {
    throw new Error(
      `README.md must contain ${TABLE_START} and ${TABLE_END} markers`,
    );
  }

  const pattern = new RegExp(
    `${TABLE_START}[\\s\\S]*?${TABLE_END}`,
    "m",
  );

  const updated = readme.replace(pattern, tableBlock);
  await writeFile(README_PATH, updated, "utf8");
}

async function main() {
  const skills = await collectSkills();

  if (skills.length === 0) {
    console.error("No skills found. Add a folder with SKILL.md at the repo root.");
    process.exit(1);
  }

  const tableBlock = buildTable(skills);
  await updateReadme(tableBlock);

  console.log(`Updated README with ${skills.length} skill(s):`);
  for (const skill of skills) {
    console.log(`  - ${skill.name}`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
