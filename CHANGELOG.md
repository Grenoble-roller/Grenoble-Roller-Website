# Changelog

## 2026-09-13 (WIP)
- **Layout/Responsive Polish** (t_af269092): Implement visual polish based on audit findings from t_383b4d77
  - Normalize page layout rhythm and container widths
  - Align navbar and footer with content shell
  - Establish coherent typography hierarchy (visual vs semantic)
  - Standardize button system (height, hover, focus)
  - Improve responsive behavior (breakpoints, overflow)
  - Consolidated CSS utilities into main stylesheet
  - Regressions: ✅ All tests pass

## 2026-09-13 (Published)
- **Optimize LCP** (t_b83c242c): Optimized Grenoble Roller homepage critical rendering path, image delivery, and semantic structure based on SEO audit
  - Implemented comprehensive SEO improvements with structured data, meta tags, and page speed optimizations

## 2026-09-12 (Published)
- **OpenCode Go Cost Guard** (t_f0672d4a): Implemented OpenCode Go cost guard: PAID tier enforcement, auto-route denial for expensive models, multi-stage drift detection
  - All 6 acceptance criteria verified
  - All tests pass, all validations pass
  - Protection: PAID tier only, with 30-minute drift detection window

## 2026-09-12 (Published)
- **Fix README.md all stale counts** (t_c9f5c442): Fixed all 3 stale counts in cockpit/piblox/omniroute/registry/README.md: models 38→43, pool_members 60→65, quota_buckets 11→12
  - Verified against validate_registry.py output

## 2026-09-12 (Published)
- **Build Registry + Refresh/Query Tooling** (t_0208787b): Implemented OmniRoute routing registry + tooling at cockpit/piblox/omniroute/registry/
  - routing-policy.yaml captures 6 pools (pool-chat/code/light/vision/hindsight/hindsight-mm), 38 unique models, 16 consumers

## 2026-09-12 (Published)
- **Build Registry + Refresh/Query Tooling** (t_dfb2b539): Built routing registry (SQLite + YAML policy) and tooling for OmniRoute
  - All 4 acceptance criteria verified: routing-policy.yaml with 6 pools, 3 context classes, 16 consumers, 12 rules, 11 quota buckets