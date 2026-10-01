#!/usr/bin/env python3
"""`docs/스토어_등록_문구.md` §5의 en/ja 등록정보를 읽어 양대 스토어에 올린다.

문서가 유일한 출처다 — 손으로 콘솔에 옮겨 적다 생기는 어긋남을 막는다.
한국어 등록정보(§1·§2)는 건드리지 않는다.

    python3 tool/store_listings.py          # 추출 결과와 길이 검증만
    python3 tool/store_listings.py --push   # App Store + Play에 반영

App Store 설명 필드는 `✓`·`■`·`—`를 거부한다(INVALID_CHARACTERS). 문서에 이미
안전한 표기로 적혀 있으며, 아래 검증이 다시 한 번 막는다.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

DOC = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   'docs', '스토어_등록_문구.md')
FORBIDDEN = '✓■—'
APP_STORE_VERSION_STATE = 'PREPARE_FOR_SUBMISSION'

PRIVACY = {'ko': 'https://pink-spider.github.io/firedom-privacy/',
           'en-US': 'https://pink-spider.github.io/firedom-privacy/en/',
           'ja': 'https://pink-spider.github.io/firedom-privacy/ja/'}
SUPPORT = {'ko': 'https://pink-spider.github.io/firedom-privacy/support.html',
           'en-US': 'https://pink-spider.github.io/firedom-privacy/en/support.html',
           'ja': 'https://pink-spider.github.io/firedom-privacy/ja/support.html'}


def _doc():
    with open(DOC, encoding='utf-8') as f:
        return f.read()


def _section(text, start, end):
    i = text.index(start)
    return text[i:text.index(end, i)]


def _cell(block, label):
    m = re.search(r'^\|\s*' + re.escape(label) + r'\s*\|\s*`([^`]+)`\s*\|', block, re.M)
    if not m:
        raise SystemExit(f'문서에서 {label!r} 행을 찾지 못했습니다')
    return m.group(1)


def _code(block, after):
    m = re.search(r'```\n(.*?)\n```', block[block.index(after):], re.S)
    if not m:
        raise SystemExit(f'문서에서 {after!r} 코드블록을 찾지 못했습니다')
    return m.group(1)


def load():
    doc = _doc()
    en_b = _section(doc, '### 5-1. App Store — English', '### 5-2.')
    ja_b = _section(doc, '### 5-2. App Store — 日本語', '### 5-3.')
    play_b = _section(doc, '### 5-3. Google Play', '### 5-4.')

    app_store = {
        'en-US': dict(name=_cell(en_b, 'Name'), subtitle=_cell(en_b, 'Subtitle'),
                      keywords=_cell(en_b, 'Keywords'), promo=_cell(en_b, 'Promotional text'),
                      description=_code(en_b, '**Description**')),
        'ja': dict(name=_cell(ja_b, '名前'), subtitle=_cell(ja_b, 'サブタイトル'),
                   keywords=_cell(ja_b, 'キーワード'), promo=_cell(ja_b, 'プロモーションテキスト'),
                   description=_code(ja_b, '**説明**')),
    }
    rows = dict((k, (en, ja)) for k, en, ja in re.findall(
        r'^\|\s*(App name|Short description)\s*\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|', play_b, re.M))
    play = {
        'en-US': dict(title=rows['App name'][0], short=rows['Short description'][0],
                      full=_strip_links(app_store['en-US']['description'])),
        'ja-JP': dict(title=rows['App name'][1], short=rows['Short description'][1],
                      full=_strip_links(app_store['ja']['description'])),
    }
    return app_store, play


def _strip_links(text):
    """Play용: 끝의 약관·처리방침 링크 두 줄 제거 (EULA는 Apple 전용 필드)."""
    lines = text.rstrip().splitlines()
    while lines and (not lines[-1].strip() or lines[-1].startswith(
            ('Terms of Use', 'Privacy Policy', '利用規約', 'プライバシーポリシー'))):
        lines.pop()
    return '\n'.join(lines).rstrip()


def validate(app_store, play):
    limits_as = {'name': 30, 'subtitle': 30, 'keywords': 100, 'promo': 170, 'description': 4000}
    limits_play = {'title': 30, 'short': 80, 'full': 4000}
    problems = []
    for locale, d in app_store.items():
        for key, value in d.items():
            if len(value) > limits_as[key]:
                problems.append(f'App Store {locale}.{key} {len(value)}자 > {limits_as[key]}')
            bad = [c for c in FORBIDDEN if c in value]
            if bad:
                problems.append(f'App Store {locale}.{key} 금지 기호 {bad}')
    for locale, d in play.items():
        for key, limit in limits_play.items():
            if len(d[key]) > limit:
                problems.append(f'Play {locale}.{key} {len(d[key])}자 > {limit}')
    return problems


def push_app_store(app_store):
    import asc_api as A
    versions = A.call('GET', f'/v1/apps/{A.APP_ID}/appStoreVersions'
                      '?limit=5&fields[appStoreVersions]=versionString,appStoreState')
    editable = [v for v in versions['data']
                if v['attributes']['appStoreState'] == APP_STORE_VERSION_STATE]
    if not editable:
        raise SystemExit('편집 가능한 App Store 버전이 없습니다 '
                         '(ASC에서 새 버전을 먼저 만드세요)')
    version = editable[0]['id']
    print(f"  버전 {editable[0]['attributes']['versionString']}")

    have = {l['attributes']['locale']: l['id'] for l in A.call(
        'GET', f'/v1/appStoreVersions/{version}/appStoreVersionLocalizations'
        '?fields[appStoreVersionLocalizations]=locale')['data']}
    for locale, src in app_store.items():
        attrs = {'description': src['description'], 'keywords': src['keywords'],
                 'promotionalText': src['promo'], 'supportUrl': SUPPORT[locale]}
        if locale in have:
            A.call('PATCH', f'/v1/appStoreVersionLocalizations/{have[locale]}',
                   {'data': {'type': 'appStoreVersionLocalizations', 'id': have[locale],
                             'attributes': attrs}})
        else:
            A.call('POST', '/v1/appStoreVersionLocalizations',
                   {'data': {'type': 'appStoreVersionLocalizations',
                             'attributes': dict(attrs, locale=locale),
                             'relationships': {'appStoreVersion': {'data': {
                                 'type': 'appStoreVersions', 'id': version}}}}})
        print(f'  {locale} 설명·키워드 반영')

    infos = A.call('GET', f'/v1/apps/{A.APP_ID}/appInfos?fields[appInfos]=state')
    editable_info = [i for i in infos['data']
                     if i['attributes']['state'] != 'READY_FOR_DISTRIBUTION']
    if not editable_info:
        print('  (편집 가능한 appInfo 없음 — 이름·부제는 건너뜀)')
        return
    info = editable_info[0]['id']
    loc_ids = {l['attributes']['locale']: l['id'] for l in A.call(
        'GET', f'/v1/appInfos/{info}/appInfoLocalizations'
        '?fields[appInfoLocalizations]=locale')['data']}
    for locale, src in app_store.items():
        attrs = {'name': src['name'], 'subtitle': src['subtitle'],
                 'privacyPolicyUrl': PRIVACY[locale]}
        if locale in loc_ids:
            A.call('PATCH', f'/v1/appInfoLocalizations/{loc_ids[locale]}',
                   {'data': {'type': 'appInfoLocalizations', 'id': loc_ids[locale],
                             'attributes': attrs}})
        else:
            A.call('POST', '/v1/appInfoLocalizations',
                   {'data': {'type': 'appInfoLocalizations',
                             'attributes': dict(attrs, locale=locale),
                             'relationships': {'appInfo': {'data': {
                                 'type': 'appInfos', 'id': info}}}}})
        print(f'  {locale} 이름·부제·처리방침 반영')


def push_play(play):
    import play_api as P
    edit = P.call('POST', 'edits')['id']
    try:
        for lang, d in play.items():
            P.call('PUT', f'edits/{edit}/listings/{lang}',
                   {'language': lang, 'title': d['title'],
                    'shortDescription': d['short'], 'fullDescription': d['full']})
            print(f'  {lang} 반영')
        P.call('POST', f'edits/{edit}:validate')
        P.call('POST', f'edits/{edit}:commit')
        print('  커밋 완료')
    except Exception:
        P.call('DELETE', f'edits/{edit}')
        raise


def main():
    app_store, play = load()
    print('문서에서 읽은 등록정보:')
    for locale, d in app_store.items():
        print(f"  App Store {locale:6s} {d['name']!r} / 설명 {len(d['description'])}자")
    for locale, d in play.items():
        print(f"  Play      {locale:6s} {d['title']!r} / 설명 {len(d['full'])}자")

    problems = validate(app_store, play)
    if problems:
        print('\n문제:')
        for p in problems:
            print('  ', p)
        raise SystemExit('문서를 고친 뒤 다시 실행하세요. 아무것도 반영하지 않았습니다.')
    print('\n길이·기호 검증 통과')

    if '--push' not in sys.argv:
        print('반영하려면 --push 를 붙여 실행하세요.')
        return
    print('\nApp Store:')
    push_app_store(app_store)
    print('Google Play:')
    push_play(play)


if __name__ == '__main__':
    main()
