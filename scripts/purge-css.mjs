#!/usr/bin/env node
/**
 * Run PurgeCSS and write results back to the source CSS files.
 * The purgecss CLI often prints [] / skips writes with --config in this repo.
 */
import { createRequire } from "node:module"
import fs from "node:fs"
import path from "node:path"

const require = createRequire(import.meta.url)
const { PurgeCSS } = require("purgecss")
const config = require("../purgecss.config.js")

const results = await new PurgeCSS().purge(config)

if (!results.length) {
  console.error("purge-css: no CSS results (check purgecss.config.js css globs)")
  process.exit(1)
}

for (const result of results) {
  const outPath = path.resolve(result.file)
  fs.writeFileSync(outPath, result.css)
  const kb = (Buffer.byteLength(result.css) / 1024).toFixed(1)
  console.log(`purge-css: wrote ${path.relative(process.cwd(), outPath)} (${kb} KiB)`)
}
