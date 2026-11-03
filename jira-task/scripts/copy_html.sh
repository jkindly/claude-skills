#!/usr/bin/env bash
# Copy a Jira description to the macOS clipboard as rich HTML (pasted into Jira -> Info panels)
# plus a plain-text {panel} wiki-markup fallback.
# Usage: copy_html.sh <file.html>
set -euo pipefail

html_file="${1:?usage: copy_html.sh <file.html>}"
[ -f "$html_file" ] || { echo "No such file: $html_file" >&2; exit 1; }

osascript -l JavaScript - "$html_file" <<'JXA'
ObjC.import('AppKit');
ObjC.import('Foundation');

function run(argv) {
  const path = argv[0];
  // Long dashes are not wanted in Jira tasks; normalize them to a plain hyphen.
  const html = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null).js
    .replace(/[—–]/g, '-');

  const colors = { info: '#deebff', note: '#eae6ff', warning: '#fffae6' };
  let depth = 0;
  const text = html
    .replace(/<div data-panel-type="(\w+)">/g, (_, t) => `{panel:bgColor=${colors[t] || '#deebff'}}\n`)
    .replace(/<\/div>/g, '\n{panel}\n')
    .replace(/<(\/?)(ul|li)>/g, (_, close, tag) => {
      if (tag === 'ul') { depth += close ? -1 : 1; return ''; }
      return close ? '' : '\n' + '*'.repeat(depth) + ' ';
    })
    .replace(/<\/?(strong|b)>/g, '*')
    .replace(/<code>/g, '{{').replace(/<\/code>/g, '}}')
    .replace(/<\/p>\s*/g, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&amp;/g, '&')
    .replace(/\n{3,}/g, '\n\n')
    .trim();

  // Jira's editor merges the first pasted block into the paragraph under the cursor,
  // which unwraps the first panel. A leading empty paragraph takes that hit instead.
  const lead = /^\s*<p><br><\/p>/.test(html) ? '' : '<p><br></p>';
  const wrapped = '<meta charset="utf-8">' + lead + html;
  const pb = $.NSPasteboard.generalPasteboard;
  pb.clearContents;
  pb.setStringForType($(wrapped), $.NSPasteboardTypeHTML);
  pb.setStringForType($(text), $.NSPasteboardTypeString);
  return 'Copied to clipboard (HTML + plain text).';
}
JXA
