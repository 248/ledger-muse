#!/usr/bin/env bash
set -euo pipefail

fail=0
front="frontend"

assert_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "missing file: $path"
    fail=1
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  if ! grep -qE "$pattern" "$file"; then
    echo "missing pattern in $file: $pattern"
    fail=1
  fi
}

assert_file "$front/package.json"
assert_contains "$front/package.json" '"dev": "next dev"'
assert_contains "$front/package.json" '"build": "next build"'
assert_contains "$front/package.json" '"lint": "next lint"'
assert_contains "$front/package.json" '"type-check": "next check"'
assert_contains "$front/package.json" '"test": "vitest run"'

assert_contains "$front/package.json" '"next"'
assert_contains "$front/package.json" '"react"'
assert_contains "$front/package.json" '"react-dom"'
assert_contains "$front/package.json" '"typescript"'
assert_contains "$front/package.json" '"eslint"'
assert_contains "$front/package.json" '"prettier"'
assert_contains "$front/package.json" '"tailwindcss"'
assert_contains "$front/package.json" '"autoprefixer"'
assert_contains "$front/package.json" '"postcss"'
assert_contains "$front/package.json" '"vitest"'
assert_contains "$front/package.json" '"@testing-library/react"'
assert_contains "$front/package.json" '"@testing-library/jest-dom"'
assert_contains "$front/package.json" '"jsdom"'
assert_contains "$front/package.json" '"@types/node"'
assert_contains "$front/package.json" '"@types/react"'
assert_contains "$front/package.json" '"@types/react-dom"'

assert_file "$front/tsconfig.json"
assert_file "$front/next.config.mjs"
assert_file "$front/tailwind.config.ts"
assert_file "$front/postcss.config.mjs"
assert_file "$front/app/layout.tsx"
assert_file "$front/app/page.tsx"
assert_file "$front/app/globals.css"
assert_file "$front/.eslintrc.json"
assert_file "$front/prettier.config.mjs"
assert_file "$front/vitest.config.ts"
assert_file "$front/test/setup.ts"

exit $fail
