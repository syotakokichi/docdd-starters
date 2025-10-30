#!/usr/bin/env node
import { readdirSync, statSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = resolve(fileURLToPath(new URL(".", import.meta.url)));
const root = resolve(scriptDir, "..", "app");

function isSegmentDirectory(name) {
  return name.startsWith("(") && name.endsWith(")");
}

function listDirectories(path) {
  return readdirSync(path).filter((entry) => {
    const fullPath = join(path, entry);
    return statSync(fullPath).isDirectory();
  });
}

const requiredFolders = ["_containers", "_components"];
const missing = [];

for (const segmentDir of readdirSync(root)) {
  const segmentPath = join(root, segmentDir);
  if (!statSync(segmentPath).isDirectory() || !isSegmentDirectory(segmentDir)) continue;

  const routeEntries = listDirectories(segmentPath);
  for (const routeName of routeEntries) {
    const routePath = join(segmentPath, routeName);
    const hasRoutePage = readdirSync(routePath).includes("page.tsx");
    if (!hasRoutePage) continue; // skip nested layouts etc.

    for (const folder of requiredFolders) {
      const target = join(routePath, folder);
      if (!existsSync(target)) {
        missing.push(`${routePath} に ${folder} が存在しません`);
      }
    }

    // check container structure
    const containersPath = join(routePath, "_containers");
    if (existsSync(containersPath)) {
      const containerDirs = listDirectories(containersPath);
      if (containerDirs.length === 0) {
        missing.push(`${containersPath} にコンテナディレクトリがありません`);
      }
      for (const name of containerDirs) {
        const dir = join(containersPath, name);
        for (const file of ["index.ts", "container.tsx", "presentational.tsx"]) {
          if (!existsSync(join(dir, file))) {
            missing.push(`${dir}/${file} が存在しません`);
          }
        }
      }
    }
  }
}

if (missing.length) {
  console.error("Private Folder 構成チェックに失敗しました:");
  for (const msg of missing) {
    console.error(` - ${msg}`);
  }
  process.exit(1);
}

console.log("Private Folder 構成チェックは成功しました ✨");
