#!/usr/bin/env python3
"""촬영한 스크린샷을 App Store와 Google Play에 올린다.

입력: `store_assets/screenshots/<prefix>/<locale>/NN_name.png`
      (`tool/screenshots.sh`가 만드는 구조)

    python3 tool/upload_screenshots.py            # 올릴 목록만 출력
    python3 tool/upload_screenshots.py --push     # 실제 업로드
    python3 tool/upload_screenshots.py --push --only en

App Store는 기존 스크린샷을 지우고 새로 올린다(순서를 맞추기 위해).
Play는 언어별 폰 스크린샷을 통째로 교체한다.
"""
import hashlib
import json
import os
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, 'store_assets', 'screenshots')

# 촬영 폴더(prefix) → App Store 디스플레이 타입
DISPLAY_TYPE = {'iphone65': 'APP_IPHONE_65', 'ipad129': 'APP_IPAD_PRO_3GEN_129'}
# 앱 로케일 → 스토어 로케일
ASC_LOCALE = {'ko': 'ko', 'en': 'en-US', 'ja': 'ja'}
PLAY_LOCALE = {'ko': 'ko-KR', 'en': 'en-US', 'ja': 'ja-JP'}
PLAY_IMAGE_TYPE = {'iphone65': 'phoneScreenshots'}


def collect(only=None):
    """{prefix: {locale: [경로…]}} — 파일명 순서가 스토어 노출 순서."""
    out = {}
    if not os.path.isdir(SHOTS):
        return out
    for prefix in sorted(os.listdir(SHOTS)):
        pdir = os.path.join(SHOTS, prefix)
        if not os.path.isdir(pdir) or prefix not in DISPLAY_TYPE:
            continue
        for locale in sorted(os.listdir(pdir)):
            ldir = os.path.join(pdir, locale)
            if not os.path.isdir(ldir) or (only and locale not in only):
                continue
            files = sorted(f for f in os.listdir(ldir) if f.endswith('.png'))
            if files:
                out.setdefault(prefix, {})[locale] = [os.path.join(ldir, f) for f in files]
    return out


def _raw(method, url, headers, body=None):
    req = urllib.request.Request(url, method=method, data=body, headers=headers)
    with urllib.request.urlopen(req) as r:
        return r.read()


def push_app_store(prefix, locale, paths):
    import asc_api as A
    display = DISPLAY_TYPE[prefix]
    asc_loc = ASC_LOCALE[locale]

    versions = A.call('GET', f'/v1/apps/{A.APP_ID}/appStoreVersions'
                      '?limit=5&fields[appStoreVersions]=versionString,appStoreState')
    editable = [v for v in versions['data']
                if v['attributes']['appStoreState'] == 'PREPARE_FOR_SUBMISSION']
    if not editable:
        raise SystemExit('편집 가능한 App Store 버전이 없습니다')
    version = editable[0]['id']

    locs = {l['attributes']['locale']: l['id'] for l in A.call(
        'GET', f'/v1/appStoreVersions/{version}/appStoreVersionLocalizations'
        '?fields[appStoreVersionLocalizations]=locale')['data']}
    if asc_loc not in locs:
        raise SystemExit(f'{asc_loc} 등록정보가 없습니다 (tool/store_listings.py 먼저)')

    sets = A.call('GET', f'/v1/appStoreVersionLocalizations/{locs[asc_loc]}/appScreenshotSets'
                  '?fields[appScreenshotSets]=screenshotDisplayType')
    existing = [s for s in sets['data']
                if s['attributes']['screenshotDisplayType'] == display]
    for s in existing:                       # 순서를 맞추려 기존 세트를 비운다
        A.call('DELETE', f"/v1/appScreenshotSets/{s['id']}")
    created = A.call('POST', '/v1/appScreenshotSets',
                     {'data': {'type': 'appScreenshotSets',
                               'attributes': {'screenshotDisplayType': display},
                               'relationships': {'appStoreVersionLocalization': {'data': {
                                   'type': 'appStoreVersionLocalizations',
                                   'id': locs[asc_loc]}}}}})
    set_id = created['data']['id']

    for path in paths:
        blob = open(path, 'rb').read()
        res = A.call('POST', '/v1/appScreenshots',
                     {'data': {'type': 'appScreenshots',
                               'attributes': {'fileSize': len(blob),
                                              'fileName': os.path.basename(path)},
                               'relationships': {'appScreenshotSet': {'data': {
                                   'type': 'appScreenshotSets', 'id': set_id}}}}})
        shot_id = res['data']['id']
        for op in res['data']['attributes']['uploadOperations']:
            headers = {h['name']: h['value'] for h in (op.get('requestHeaders') or [])}
            offset, length = op['offset'], op['length']
            _raw(op['method'], op['url'], headers, blob[offset:offset + length])
        A.call('PATCH', f'/v1/appScreenshots/{shot_id}',
               {'data': {'type': 'appScreenshots', 'id': shot_id,
                         'attributes': {'uploaded': True,
                                        'sourceFileChecksum': hashlib.md5(blob).hexdigest()}}})
        print(f'    {os.path.basename(path)}')


def push_play(prefix, locale, paths):
    import play_api as P
    image_type = PLAY_IMAGE_TYPE.get(prefix)
    if not image_type:
        print(f'    (Play는 {prefix} 미지원 — 건너뜀)')
        return
    lang = PLAY_LOCALE[locale]
    edit = P.call('POST', 'edits')['id']
    try:
        P.call('DELETE', f'edits/{edit}/images/{lang}/{image_type}')
        for path in paths:
            blob = open(path, 'rb').read()
            url = ('https://androidpublisher.googleapis.com/upload/androidpublisher/v3/'
                   f'applications/{P.PKG}/edits/{edit}/images/{lang}/{image_type}'
                   '?uploadType=media')
            _raw('POST', url, {'Authorization': f'Bearer {P.token()}',
                               'Content-Type': 'image/png',
                               'Content-Length': str(len(blob))}, blob)
            print(f'    {os.path.basename(path)}')
        P.call('POST', f'edits/{edit}:validate')
        P.call('POST', f'edits/{edit}:commit')
    except Exception:
        try:
            P.call('DELETE', f'edits/{edit}')
        except Exception:
            pass
        raise


def main():
    only = None
    if '--only' in sys.argv:
        only = {sys.argv[sys.argv.index('--only') + 1]}
    found = collect(only)
    if not found:
        raise SystemExit('올릴 스크린샷이 없습니다 — tool/screenshots.sh 를 먼저 실행하세요')

    for prefix, locales in found.items():
        for locale, paths in locales.items():
            print(f'{prefix}/{locale}: {len(paths)}장')
            for p in paths:
                print(f'    {os.path.basename(p)}')
    if '--push' not in sys.argv:
        print('\n업로드하려면 --push 를 붙여 실행하세요.')
        return

    for prefix, locales in found.items():
        for locale, paths in locales.items():
            print(f'\nApp Store {prefix}/{locale}')
            push_app_store(prefix, locale, paths)
            print(f'Play {prefix}/{locale}')
            push_play(prefix, locale, paths)
    print('\n업로드 완료')


if __name__ == '__main__':
    main()
