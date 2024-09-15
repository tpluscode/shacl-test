#!/usr/bin/env node
import rdf from '@zazuko/env-node'
import formats from '@rdfjs-elements/formats-pretty'
import { argv } from 'node:process'

rdf.formats.import(formats)

// Default prefixes
let prefixes = ['sh', 'rdf', 'rdfs', 'xsd']

// Parse command-line arguments for prefixes
let currentPrefix = argv.indexOf('--prefixes')
let arg = argv[currentPrefix + 1]
while (arg && !arg.startsWith('--')) {
  const [key, value] = arg.split('=')
  if (value) {
    prefixes.push([key.replace('--prefixes', '').trim(), value.trim()])
  } else {
    prefixes.push(key.replace('--prefixes', '').trim())
  }
  currentPrefix++
  arg = argv[currentPrefix + 1]
}

;(async function () {
  const dataset = await rdf.dataset().import(rdf.formats.parsers.import('text/turtle', process.stdin))

  process.stdout.write(await dataset.serialize({ format: 'text/turtle', prefixes }))
})()
