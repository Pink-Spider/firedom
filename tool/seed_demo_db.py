#!/usr/bin/env python3
"""스토어 스크린샷용 시연 데이터를 시뮬레이터의 앱 DB에 직접 넣는다.

앱 코드를 건드리지 않고(디버그 플래그 불필요) 같은 데이터로 언어·통화만 바꿔
촬영할 수 있게 한다. 촬영 절차는 `tool/screenshots.md` 참고.

    python3 tool/seed_demo_db.py <simulator-udid> en USD
"""
import json
import os
import subprocess
import sqlite3
import sys
import time
import uuid

BUNDLE = 'app.firedom.firedom'
# 통화별 시연 금액 (최소 단위: KRW·JPY는 원/엔, USD는 센트)
DEMO = {
    'KRW': dict(assets=120_000_000, saving=2_000_000, spend=2_500_000,
                income=4_800_000, expense=2_800_000, base=138_000_000),
    'USD': dict(assets=9_000_000, saving=150_000, spend=200_000,
                income=360_000, expense=210_000, base=10_400_000),
    'JPY': dict(assets=12_000_000, saving=200_000, spend=250_000,
                income=480_000, expense=280_000, base=13_800_000),
}
ACCOUNTS = [
    # (한국어 이름, 영어, 일본어, 자산군, 부채 여부)
    ('예금', 'Savings', '預金', 'cash', 0),
    ('주식', 'Stocks', '株式', 'equity', 0),
    ('연금계좌', 'Pension account', '年金口座', 'pension', 0),
    ('부동산', 'Real estate', '不動産', 'real_estate', 0),
    ('대출', 'Loans', 'ローン', 'other', 1),
    ('기타', 'Other', 'その他', 'other', 0),
]
NAME_COL = {'ko': 0, 'en': 1, 'ja': 2}


def ym_add(ym, months):
    total = (ym // 100) * 12 + (ym % 100 - 1) + months
    return (total // 12) * 100 + (total % 12 + 1)


def db_path(udid):
    out = subprocess.check_output(
        ['xcrun', 'simctl', 'get_app_container', udid, BUNDLE, 'data'], text=True).strip()
    return os.path.join(out, 'Documents', 'firedom.sqlite')


def seed(path, locale, currency):
    d = DEMO[currency]
    now = int(time.time() * 1000)
    today = time.localtime()
    this_ym = today.tm_year * 100 + today.tm_mon
    started = ym_add(this_ym, -7)

    con = sqlite3.connect(path)
    cur = con.cursor()
    for table in ('snapshot_items', 'snapshots', 'milestones', 'scenarios',
                  'accounts', 'plans', 'settings'):
        cur.execute(f'DELETE FROM {table}')

    for key, value in (('locale', locale), ('currency', currency),
                       ('entitlement.premium', True), ('theme_mode', 'system')):
        cur.execute('INSERT INTO settings (key, value, updated_at) VALUES (?,?,?)',
                    (key, json.dumps(value), now))

    plan_id = str(uuid.uuid4())
    cur.execute(
        'INSERT INTO plans (id, created_at, updated_at, revision_group, is_active, fire_type,'
        ' birth_ym, current_assets, monthly_saving, real_return_bp, volatility_bp,'
        ' monthly_spend_retire, swr_bp, life_expectancy, started_ym)'
        ' VALUES (?,?,?,?,1,?,?,?,?,?,?,?,?,?,?)',
        (plan_id, now, now, plan_id, 'custom', ym_add(started, -36 * 12), d['assets'],
         d['saving'], 450, 1200, d['spend'], 400, 90, started))

    account_ids = []
    col = NAME_COL[locale]
    for i, row in enumerate(ACCOUNTS):
        aid = str(uuid.uuid4())
        account_ids.append(aid)
        cur.execute(
            'INSERT INTO accounts (id, created_at, updated_at, name, asset_class,'
            ' account_type, is_liability, include_in_fire, sort_order)'
            ' VALUES (?,?,?,?,?,?,?,1,?)',
            (aid, now, now, row[col], row[3], 'normal', row[4], i))

    # 최근 7개월 기록 — 저축이 쌓이며 궤도가 조금씩 올라간다
    weights = [0.30, 0.42, 0.18, 0.10]
    for i in range(6, -1, -1):
        ym = ym_add(this_ym, -i)
        grow = 6 - i
        sid = str(uuid.uuid4())
        cur.execute(
            'INSERT INTO snapshots (id, created_at, updated_at, ym, income, expense)'
            ' VALUES (?,?,?,?,?,?)', (sid, now, now, ym, d['income'], d['expense']))
        for idx, w in enumerate(weights):
            amount = round(d['base'] * w) + (d['saving'] * grow if idx < 2 else 0)
            cur.execute(
                'INSERT INTO snapshot_items (id, created_at, updated_at, snapshot_id,'
                ' account_id, amount) VALUES (?,?,?,?,?,?)',
                (str(uuid.uuid4()), now, now, sid, account_ids[idx], amount))
    con.commit()
    con.close()


def main():
    if len(sys.argv) != 4:
        raise SystemExit('사용법: seed_demo_db.py <udid> <ko|en|ja> <KRW|USD|JPY>')
    udid, locale, currency = sys.argv[1:4]
    path = db_path(udid)
    if not os.path.exists(path):
        raise SystemExit(f'앱 DB가 없습니다 — 앱을 한 번 실행하세요: {path}')
    seed(path, locale, currency)
    print(f'시연 데이터 삽입 완료 ({locale}/{currency})\n  {path}')


if __name__ == '__main__':
    main()
