#!/usr/bin/env python3
"""lib/l10n/parts/*.json → lib/l10n/app_{ko,en,ja}.arb 병합.

parts 파일 형식 (키 → 언어별 문자열 + 메타):
  {
    "homeTitle": {"ko": "홈", "en": "Home", "ja": "ホーム", "desc": "탭 이름"},
    "snapDelta": {"ko": "전월 대비 {delta}", "en": "{delta} vs last month", "ja": "前月比 {delta}",
                  "placeholders": {"delta": {"type": "String"}}}
  }
키는 전체 parts에서 유일해야 한다. 병합 후 `fvm flutter gen-l10n`을 돌린다.
"""
import json, pathlib, sys, collections

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
parts_dir = root / 'parts'
LANGS = ['ko', 'en', 'ja']

merged = collections.OrderedDict()
owner = {}
errors = []
for part in sorted(parts_dir.glob('*.json')):
    try:
        data = json.loads(part.read_text(encoding='utf-8'))
    except json.JSONDecodeError as e:
        errors.append(f'{part.name}: JSON 오류 {e}')
        continue
    for key, entry in data.items():
        if key in merged:
            errors.append(f'중복 키 {key}: {owner[key]} vs {part.name}')
            continue
        missing = [l for l in LANGS if l not in entry]
        if missing:
            errors.append(f'{part.name}:{key} 누락 언어 {missing}')
            continue
        merged[key] = entry
        owner[key] = part.name

if errors:
    print('\n'.join(errors), file=sys.stderr)
    sys.exit(1)

for lang in LANGS:
    out = collections.OrderedDict()
    out['@@locale'] = lang
    for key in sorted(merged):
        entry = merged[key]
        out[key] = entry[lang]
        if lang == 'ko':
            meta = {}
            if entry.get('desc'):
                meta['description'] = entry['desc']
            if entry.get('placeholders'):
                meta['placeholders'] = entry['placeholders']
            if meta:
                out['@' + key] = meta
    (root / f'app_{lang}.arb').write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'merged {len(merged)} keys from {len(list(parts_dir.glob("*.json")))} parts')
