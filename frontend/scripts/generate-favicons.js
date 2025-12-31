#!/usr/bin/env node
/**
 * Generate favicon PNG files from SVG source
 * Run with: node scripts/generate-favicons.js
 */

import sharp from 'sharp'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'
import { readFileSync, writeFileSync } from 'fs'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const publicDir = join(__dirname, '../public')
const svgPath = join(publicDir, 'favicon.svg')

// Read SVG content
const svgContent = readFileSync(svgPath)

// Define sizes to generate
const sizes = [
  { name: 'favicon-16x16.png', size: 16 },
  { name: 'favicon-32x32.png', size: 32 },
  { name: 'apple-touch-icon.png', size: 180 },
  { name: 'android-chrome-192x192.png', size: 192 },
  { name: 'android-chrome-512x512.png', size: 512 },
]

async function generateFavicons() {
  console.log('Generating favicons from SVG...')

  for (const { name, size } of sizes) {
    const outputPath = join(publicDir, name)

    await sharp(svgContent, { density: 300 })
      .resize(size, size)
      .png()
      .toFile(outputPath)

    console.log(`  Created: ${name} (${size}x${size})`)
  }

  // Generate favicon.ico (multi-size ICO format)
  // For simplicity, we'll create a 32x32 PNG and rename it
  // Modern browsers prefer PNG/SVG anyway
  const ico16 = await sharp(svgContent, { density: 300 })
    .resize(16, 16)
    .png()
    .toBuffer()

  const ico32 = await sharp(svgContent, { density: 300 })
    .resize(32, 32)
    .png()
    .toBuffer()

  // Write 32x32 as ICO (browsers accept PNG in ICO container)
  writeFileSync(join(publicDir, 'favicon.ico'), ico32)
  console.log('  Created: favicon.ico (32x32)')

  console.log('\nAll favicons generated successfully!')
}

generateFavicons().catch(console.error)
