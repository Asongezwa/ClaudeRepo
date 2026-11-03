# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Salesforce DX project (standard `sf project generate` template). All metadata source lives in the single package directory `force-app/main/default/` (source API version 68.0, no namespace). The metadata folders (`classes`, `triggers`, `lwc`, `aura`, `objects`, `layouts`, `flexipages`, `tabs`, `applications`, `permissionsets`, `staticresources`, `contentassets`) are scaffolded but currently empty.

The default target org is the alias `aiOrg` (set in `.sf/config.json`). Unless a command passes `--target-org`, it runs against that org.

## Commands

Install dependencies first with `npm install`. `node_modules` isn't present yet.

**Lint / format / unit test (LWC + Aura JS only):**
- `npm run lint`: ESLint over `**/{aura,lwc}/**/*.js`
- `npm test`: LWC Jest tests (`sfdx-lwc-jest`)
- Single test file: `npx sfdx-lwc-jest -- force-app/main/default/lwc/<component>/__tests__/<component>.test.js`
- Tests matching a name: `npx sfdx-lwc-jest -- -t "<test name>"`
- `npm run test:unit:watch`, `npm run test:unit:coverage`
- `npm run prettier` / `npm run prettier:verify`: formats Apex (`prettier-plugin-apex`), XML metadata (`@prettier/plugin-xml`), LWC HTML (`lwc` parser), and so on

**Salesforce CLI (`sf`):**
- Deploy: `sf project deploy start` (or `--source-dir force-app/main/default/classes/Foo.cls` for one file, or `--manifest manifest/package.xml`)
- Retrieve: `sf project retrieve start`
- Run Apex tests: `sf apex run test --test-level RunLocalTests --wait 10`. For one class, use `sf apex run test --class-names MyClassTest --result-format human --wait 10`
- Anonymous Apex: `sf apex run --file scripts/apex/hello.apex`
- SOQL: `sf data query --file scripts/soql/account.soql`
- Scaffold: `sf template generate apex class --name Foo --output-dir force-app/main/default/classes` (similar for `lightning component --type lwc`, `apex trigger`, and so on)
- Scratch org: `sf org create scratch --definition-file config/project-scratch-def.json --alias <alias>` (requires a Dev Hub)

## Conventions and tooling notes

- Apex has no local test runner. Apex tests run only in an org through `sf apex run test`. Jest covers only LWC JavaScript.
- LWC Jest tests go in `lwc/<component>/__tests__/`. `.forceignore` excludes `**/__tests__/**`, `package.xml`, and `jsconfig.json`/`.eslintrc.json` from deploys.
- Every metadata file needs its matching `-meta.xml` companion (for example `Foo.cls` plus `Foo.cls-meta.xml`) with `apiVersion` 68.0.
- `manifest/package.xml` uses wildcards only for code types (ApexClass/Trigger/Page/Component/TestSuite, Aura, LWC, StaticResource). Deploying with the manifest won't include objects, layouts, flexipages, tabs, apps, or permission sets. Use `--source-dir force-app` for those.
- Prettier uses `trailingComma: "none"`.
- Husky pre-commit runs `lint-staged`: Prettier on staged files, ESLint on Aura/LWC JS, and `sfdx-lwc-jest --bail --findRelatedTests` on changed LWC files. The directory isn't a git repo yet, so the hook doesn't run until `git init` + `npm install`.
- `.vscode/mcp.json` configures the `@salesforce/mcp` server (toolsets: orgs, metadata, data, users, testing) for the editor.
