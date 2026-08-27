#!/usr/bin/env sh
set -eu

if [ ! -f "package.json" ]; then
  echo "No package.json found; skipping package bootstrap."
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found; skipping package bootstrap."
  exit 0
fi

current_name=$(npm pkg get name 2>/dev/null | tr -d '"[:space:]' || true)
if [ "$current_name" = "undefined" ] || [ "$current_name" = "null" ]; then
  current_name=""
fi

current_private=$(npm pkg get private 2>/dev/null | tr -d '"[:space:]' || true)
if [ "$current_private" = "undefined" ] || [ "$current_private" = "null" ]; then
  current_private=""
fi

current_description=$(npm pkg get description 2>/dev/null | tr -d '"' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
if [ "$current_description" = "undefined" ] || [ "$current_description" = "null" ]; then
  current_description=""
fi

repo_name=$(basename "$PWD")
project_name=$(printf '%s' "$repo_name" | sed -E 's/^[Ww][Oo][Rr][Kk]-//')
if [ -z "$project_name" ]; then
  project_name="$repo_name"
fi

sanitized=$(printf '%s' "$project_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/-+/-/g; s/^[-._]+//; s/[-._]+$//')
if [ -z "$sanitized" ]; then
  sanitized="project-docs"
fi

should_replace=false
if [ -z "$current_name" ] || [ "$current_name" = "template-docs" ] || [ "$current_name" = "work-template-docs" ]; then
  should_replace=true
fi

if [ "$should_replace" = "true" ] && [ "$current_name" != "$sanitized" ]; then
  npm pkg set "name=$sanitized" >/dev/null
  echo "Updated package.json name: $current_name -> $sanitized"
  metadata_changed=true
else
  echo "Keeping package.json name: $current_name"
fi

template_description="Reusable template for documentation-first projects."
default_description="Documentation for $project_name."
should_replace_description=false
if [ "$should_replace" = "true" ] || [ -z "$current_description" ] || [ "$current_description" = "$template_description" ]; then
  should_replace_description=true
fi

if [ "$should_replace_description" = "true" ] && [ "$current_description" != "$default_description" ]; then
  npm pkg set "description=$default_description" >/dev/null
  echo "Updated package.json description: $current_description -> $default_description"
  metadata_changed=true
else
  echo "Keeping package.json description: $current_description"
fi

metadata_changed=${metadata_changed:-false}
if [ "$should_replace" = "true" ] || [ -z "$current_private" ]; then
  npm pkg set "private=true" --json >/dev/null
  echo "Ensured package.json private=true"
  metadata_changed=true
else
  echo "Keeping package.json private: $current_private"
fi

# Regenerate package-lock.json only when package.json metadata was actually updated
if [ "$metadata_changed" = "true" ]; then
  npm install --package-lock-only >/dev/null
  echo "Regenerated package-lock.json"
else
  echo "No package.json metadata changed; skipping package-lock.json regeneration."
fi

settings_path=".vscode/settings.json"
if [ ! -f "$settings_path" ]; then
  echo "No $settings_path found; skipping cSpell bootstrap."
  exit 0
fi

dict_name="${sanitized}-words"
dict_file=".vscode/${dict_name}.txt"
template_dict_file=".vscode/generic-project-words.txt"

node - "$repo_name" "$project_name" "$sanitized" "$settings_path" "$dict_name" "$dict_file" "$template_dict_file" <<'NODE'
const fs = require("fs");
const path = require("path");

const [repoName, projectName, sanitizedName, settingsPath, dictionaryName, dictionaryFilePath, templateDictionaryPath] = process.argv.slice(2);

function splitWords(value) {
  return value
    .split(/[^A-Za-z0-9]+/)
    .map((word) => word.trim())
    .filter((word) => word.length > 0);
}

function readWordFile(filePath) {
  if (!fs.existsSync(filePath)) {
    return [];
  }

  return fs
    .readFileSync(filePath, "utf8")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0);
}

function sortNode(node) {
  if (Array.isArray(node)) {
    return node.map((item) => sortNode(item));
  }

  if (node && typeof node === "object") {
    const sorted = {};
    for (const key of Object.keys(node).sort((left, right) => left.localeCompare(right))) {
      sorted[key] = sortNode(node[key]);
    }
    return sorted;
  }

  return node;
}

const seededWords = new Set();
for (const token of splitWords(repoName)) {
  seededWords.add(token);
  seededWords.add(token.toLowerCase());
}
for (const token of splitWords(projectName)) {
  seededWords.add(token);
  seededWords.add(token.toLowerCase());
}
for (const token of splitWords(sanitizedName)) {
  seededWords.add(token);
  seededWords.add(token.toLowerCase());
}
seededWords.add(sanitizedName.toLowerCase());

for (const word of readWordFile(templateDictionaryPath)) {
  seededWords.add(word);
}
for (const word of readWordFile(dictionaryFilePath)) {
  seededWords.add(word);
}

const sortedWords = [...seededWords].sort((left, right) => left.localeCompare(right));
fs.mkdirSync(path.dirname(dictionaryFilePath), { recursive: true });
fs.writeFileSync(dictionaryFilePath, `${sortedWords.join("\n")}\n`, "utf8");

const settings = JSON.parse(fs.readFileSync(settingsPath, "utf8"));

function isPlainObject(value) {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

// Settings files in this template use flat dotted keys for cSpell.* (see
// .vscode/settings.generic.json), not a nested "cSpell": {...} object. Target
// the flat key, and fold in any legacy nested customDictionaries entries so a
// previously mis-registered settings.json self-heals instead of ending up
// with two conflicting customDictionaries blocks.
if (!isPlainObject(settings["cSpell.customDictionaries"])) {
  settings["cSpell.customDictionaries"] = {};
}
const customDictionaries = settings["cSpell.customDictionaries"];

if (isPlainObject(settings.cSpell)) {
  if (isPlainObject(settings.cSpell.customDictionaries)) {
    for (const [key, value] of Object.entries(settings.cSpell.customDictionaries)) {
      if (!(key in customDictionaries)) {
        customDictionaries[key] = value;
      }
    }
    delete settings.cSpell.customDictionaries;
  }
  if (Object.keys(settings.cSpell).length === 0) {
    delete settings.cSpell;
  }
}

customDictionaries[dictionaryName] = {
  addWords: true,
  description: "Project-specific accepted words",
  name: dictionaryName,
  path: `\${workspaceFolder}/.vscode/${path.basename(dictionaryFilePath)}`,
  scope: "workspace",
};

const formattedSettings = `${JSON.stringify(sortNode(settings), null, 2)}\n`;
fs.writeFileSync(settingsPath, formattedSettings, "utf8");

const docsTokens = new Map([
  ["{{PROJECT_NAME}}", projectName],
  ["{{REPO_NAME}}", repoName],
]);
const docsRoot = "docs";
let docsUpdated = 0;

function walkDirectory(rootPath) {
  const entries = fs.readdirSync(rootPath, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(rootPath, entry.name);
    if (entry.isDirectory()) {
      walkDirectory(fullPath);
      continue;
    }

    const isMarkdown = path.extname(entry.name).toLowerCase() === ".md";
    const isIlograph = entry.name.toLowerCase().endsWith(".ilograph.yaml");
    if (!entry.isFile() || (!isMarkdown && !isIlograph)) {
      continue;
    }

    const content = fs.readFileSync(fullPath, "utf8");
    let updatedContent = content;
    for (const [token, value] of docsTokens) {
      updatedContent = updatedContent.split(token).join(value);
    }

    if (updatedContent === content) {
      continue;
    }

    fs.writeFileSync(fullPath, updatedContent, "utf8");
    docsUpdated += 1;
  }
}

if (fs.existsSync(docsRoot) && fs.statSync(docsRoot).isDirectory()) {
  walkDirectory(docsRoot);
}

console.log(`Ensured cSpell word list: ${dictionaryFilePath}`);
console.log(`Ensured cSpell dictionary registration: ${dictionaryName}`);
console.log(`Updated docs placeholders: ${docsUpdated}`);
NODE
