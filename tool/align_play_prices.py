#!/usr/bin/env python3
"""Google Play 구독 가격을 App Store 가격에 맞춘다.

왜 필요한가: 두 스토어가 원화 기준가를 각자 환산해 같은 통화에서도 값이 어긋난다
(2026-10-01 실측: 미국 연간 App Store $22.99 vs Play $28.99). 국가를 넓히기 전에 맞춘다.

원칙
- **같은 통화인 지역만** 맞춘다. 통화 자체가 다른 지역(약 30곳)은 환율을 임의로 만들지 않고 건너뛴다
- 기존 구독자 가격은 바뀌지 않는다. 신규 구독자에게만 적용된다
  (이관은 Play `basePlans.batchMigratePrices`를 따로 호출해야 하고, 인상 시 구독자 동의 절차가 붙는다)
- 한국은 양쪽이 ₩39,000 / ₩4,900으로 같아 변경 대상이 아니다

실행 (실결제에 영향을 주므로 사람이 직접):
    python3 tool/align_play_prices.py            # 드라이런 — 변경 목록만 출력
    python3 tool/align_play_prices.py --apply    # 실제 적용
"""
import copy
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import asc_api
import play_api


PERMISSION_HELP = """
가격을 쓸 권한이 없습니다 (HTTP 403 PERMISSION_DENIED).

이 서비스 계정은 구독을 **읽을** 수는 있고 테스트 트랙 출시도 되지만,
상품 카탈로그(구독·인앱상품) **수정** 권한이 없습니다. 실제로
`GET subscriptions`는 통과하는데 `GET inappproducts`와
`PATCH subscriptions`는 403입니다.

해결: Play Console → 사용자 및 권한 → 아래 계정 → 앱 권한에서
**'스토어 등록정보 관리'(Manage store presence)** 를 켠 뒤 다시 실행하세요.
이 권한이 가격·인앱 상품·가격 템플릿 수정을 담당합니다.
('주문 및 정기 결제 관리'는 환불·해지용이라 가격 수정이 안 됩니다.)
    {email}
권한 변경은 보통 몇 분이지만 최대 48시간까지 걸릴 수 있습니다.

API로는 이 권한을 스스로 부여할 수 없습니다 — grants API를 쓰려면 호출하는
자격증명에 계정 수준 사용자 관리 권한(CAN_MANAGE_PERMISSIONS)이 있어야 하고,
이 서비스 계정에는 없습니다. Play Console에서 사람이 켜야 합니다.

권한을 늘리고 싶지 않다면 Play Console에서 직접 수정해야 합니다
(기본 플랜 → 지역별 가격). 지역이 100곳을 넘어 수작업은 권하지 않습니다.
"""

SUBS = {  # Play productId → ASC subscription id
    'firedom_39000_1y': '6809275273',
    'firedom_4900_1m': '6809277491',
}

# 소수점이 없는 통화 — Play price의 nanos를 0으로 둬야 한다
ZERO_DECIMAL = {
    'JPY', 'KRW', 'VND', 'CLP', 'ISK', 'HUF', 'TWD', 'COP', 'PYG', 'UGX', 'RWF',
    'XAF', 'XOF', 'XPF', 'BIF', 'DJF', 'GNF', 'KMF', 'MGA', 'VUV', 'IDR', 'KZT',
}

# ASC territory(alpha-3) → Play regionCode(alpha-2)
A3_A2 = {
    'AFG': 'AF', 'AGO': 'AO', 'AIA': 'AI', 'ALA': 'AX', 'ALB': 'AL', 'ANT': 'AN',
    'ARE': 'AE', 'ARG': 'AR', 'ARM': 'AM', 'ATG': 'AG', 'AUS': 'AU', 'AUT': 'AT',
    'AZE': 'AZ', 'BEL': 'BE', 'BEN': 'BJ', 'BES': 'BQ', 'BFA': 'BF', 'BGR': 'BG',
    'BHR': 'BH', 'BHS': 'BS', 'BIH': 'BA', 'BLM': 'BL', 'BLR': 'BY', 'BLZ': 'BZ',
    'BMU': 'BM', 'BOL': 'BO', 'BRA': 'BR', 'BRB': 'BB', 'BRN': 'BN', 'BTN': 'BT',
    'BWA': 'BW', 'CAN': 'CA', 'CHE': 'CH', 'CHL': 'CL', 'CHN': 'CN', 'CIV': 'CI',
    'CMR': 'CM', 'COD': 'CD', 'COG': 'CG', 'COL': 'CO', 'CPV': 'CV', 'CRI': 'CR',
    'CUB': 'CU', 'CUW': 'CW', 'CYM': 'KY', 'CYP': 'CY', 'CZE': 'CZ', 'DEU': 'DE',
    'DMA': 'DM', 'DNK': 'DK', 'DOM': 'DO', 'DZA': 'DZ', 'ECU': 'EC', 'EGY': 'EG',
    'ESP': 'ES', 'EST': 'EE', 'ETH': 'ET', 'FIN': 'FI', 'FJI': 'FJ', 'FRA': 'FR',
    'FSM': 'FM', 'GAB': 'GA', 'GBR': 'GB', 'GEO': 'GE', 'GGY': 'GG', 'GHA': 'GH',
    'GIN': 'GN', 'GLP': 'GP', 'GMB': 'GM', 'GNB': 'GW', 'GNQ': 'GQ', 'GRC': 'GR',
    'GRD': 'GD', 'GTM': 'GT', 'GUF': 'GF', 'GUY': 'GY', 'HKG': 'HK', 'HND': 'HN',
    'HRV': 'HR', 'HUN': 'HU', 'IDN': 'ID', 'IMN': 'IM', 'IND': 'IN', 'IRL': 'IE',
    'IRQ': 'IQ', 'ISL': 'IS', 'ISR': 'IL', 'ITA': 'IT', 'JAM': 'JM', 'JEY': 'JE',
    'JOR': 'JO', 'JPN': 'JP', 'KAZ': 'KZ', 'KEN': 'KE', 'KGZ': 'KG', 'KHM': 'KH',
    'KIR': 'KI', 'KNA': 'KN', 'KOR': 'KR', 'KWT': 'KW', 'LAO': 'LA', 'LBN': 'LB',
    'LBR': 'LR', 'LBY': 'LY', 'LCA': 'LC', 'LIE': 'LI', 'LKA': 'LK', 'LTU': 'LT',
    'LUX': 'LU', 'LVA': 'LV', 'MAC': 'MO', 'MAF': 'MF', 'MAR': 'MA', 'MCO': 'MC',
    'MDA': 'MD', 'MDG': 'MG', 'MDV': 'MV', 'MEX': 'MX', 'MKD': 'MK', 'MLI': 'ML',
    'MLT': 'MT', 'MMR': 'MM', 'MNE': 'ME', 'MNG': 'MN', 'MOZ': 'MZ', 'MRT': 'MR',
    'MSR': 'MS', 'MTQ': 'MQ', 'MUS': 'MU', 'MWI': 'MW', 'MYS': 'MY', 'MYT': 'YT',
    'NAM': 'NA', 'NCL': 'NC', 'NER': 'NE', 'NFK': 'NF', 'NGA': 'NG', 'NIC': 'NI',
    'NLD': 'NL', 'NOR': 'NO', 'NPL': 'NP', 'NRU': 'NR', 'NZL': 'NZ', 'OMN': 'OM',
    'PAK': 'PK', 'PAN': 'PA', 'PER': 'PE', 'PHL': 'PH', 'PLW': 'PW', 'PNG': 'PG',
    'POL': 'PL', 'PRT': 'PT', 'PRY': 'PY', 'PSE': 'PS', 'PYF': 'PF', 'QAT': 'QA',
    'REU': 'RE', 'ROU': 'RO', 'RUS': 'RU', 'RWA': 'RW', 'SAU': 'SA', 'SEN': 'SN',
    'SGP': 'SG', 'SLB': 'SB', 'SLE': 'SL', 'SLV': 'SV', 'SOM': 'SO', 'SPM': 'PM',
    'SRB': 'RS', 'STP': 'ST', 'SUR': 'SR', 'SVK': 'SK', 'SVN': 'SI', 'SWE': 'SE',
    'SWZ': 'SZ', 'SXM': 'SX', 'SYC': 'SC', 'TCA': 'TC', 'TCD': 'TD', 'THA': 'TH',
    'TJK': 'TJ', 'TKM': 'TM', 'TON': 'TO', 'TTO': 'TT', 'TUN': 'TN', 'TUR': 'TR',
    'TWN': 'TW', 'TZA': 'TZ', 'UGA': 'UG', 'UKR': 'UA', 'URY': 'UY', 'USA': 'US',
    'UZB': 'UZ', 'VCT': 'VC', 'VEN': 'VE', 'VGB': 'VG', 'VNM': 'VN', 'VUT': 'VU',
    'WLF': 'WF', 'WSM': 'WS', 'YEM': 'YE', 'ZAF': 'ZA', 'ZMB': 'ZM', 'ZWE': 'ZW',
}
A2_A3 = {v: k for k, v in A3_A2.items()}



def region_metadata():
    """Google이 지금 기대하는 지역 버전과 지역별 결제 통화.

    `pricing:convertRegionPrices`는 가격 계산기라 아무것도 수정하지 않는다.
    지역 버전을 하드코딩하면 과거 버전의 통화 규칙으로 검증돼 거부된다
    (2022/02는 아르헨티나를 USD로 보지만 2026/01은 ARS다).
    """
    res = play_api.call('POST', 'pricing:convertRegionPrices',
                        {'price': {'currencyCode': 'USD', 'units': '1', 'nanos': 0}})
    version = res['regionVersion']['version']
    expected = {code: entry['price']['currencyCode']
                for code, entry in res.get('convertedRegionPrices', {}).items()
                if entry.get('price')}
    return version, expected


def asc_currency_by_territory():
    """ASC 지역 → 통화 코드."""
    out, nxt = {}, '/v1/territories?limit=200'
    while nxt:
        d = asc_api.call('GET', nxt)
        for t in d['data']:
            out[t['id']] = t['attributes']['currency']
        nxt = d.get('links', {}).get('next')
    return out


def asc_prices(sub_id, currency_of):
    """ASC 구독의 지역별 고객가 → {territory: (currency, price)}."""
    d = asc_api.call(
        'GET',
        f'/v1/subscriptions/{sub_id}/prices'
        '?include=subscriptionPricePoint,territory&limit=200')
    inc = {i['id']: i for i in d.get('included', [])}
    out = {}
    for p in d['data']:
        rel = p.get('relationships') or {}
        terr = ((rel.get('territory') or {}).get('data') or {}).get('id')
        ppid = ((rel.get('subscriptionPricePoint') or {}).get('data') or {}).get('id')
        if not (terr and ppid):
            continue
        price = ((inc.get(ppid) or {}).get('attributes') or {}).get('customerPrice')
        if price is not None:
            out[terr] = (currency_of.get(terr), float(price))
    return out


def money(currency, amount):
    """Play price 형식 {currencyCode, units, nanos}."""
    if currency in ZERO_DECIMAL:
        return {'currencyCode': currency, 'units': str(int(round(amount)))}
    units, rem = divmod(int(round(amount * 100)), 100)
    out = {'currencyCode': currency, 'units': str(units)}
    if rem:
        out['nanos'] = rem * 10_000_000
    return out


def same(a, b):
    keys = ('currencyCode', 'units', 'nanos')
    return {k: str(a.get(k, 0)) for k in keys} == {k: str(b.get(k, 0)) for k in keys}


def main():
    apply_changes = '--apply' in sys.argv
    regions_version, expected_currency = region_metadata()
    print(f'Play 지역 버전 {regions_version} 기준\n')
    currency_of = asc_currency_by_territory()
    plans, blocked = {}, []

    for product_id, sub_id in SUBS.items():
        target = asc_prices(sub_id, currency_of)
        sub = play_api.call('GET', f'subscriptions/{product_id}')
        patched = copy.deepcopy(sub)
        changed, other_currency, out_of_scope = [], [], []

        for base_plan in patched['basePlans']:
            for region in base_plan.get('regionalConfigs', []):
                a2 = region['regionCode']
                # 진실은 Google이 이 지역에 기대하는 통화다. 저장된 값이 기대와
                # 어긋나면 **우리가 손대지 않은 지역이라도** PATCH 전체가 거부된다
                # (updateMask=basePlans는 전체 목록을 다시 검증한다).
                expects = expected_currency.get(a2)
                stored = region.get('price', {}).get('currencyCode')
                if expects and stored and stored != expects:
                    blocked.append((a2, stored, expects))
                    continue
                a3 = A2_A3.get(a2)
                if not a3 or a3 not in target:
                    out_of_scope.append(a2)
                    continue
                currency, amount = target[a3]
                if stored != currency:
                    other_currency.append(a2)
                    continue
                want = money(currency, amount)
                if not same(region['price'], want):
                    changed.append((a2, currency,
                                    region['price'].get('units'), want.get('units')))
                    region['price'] = want
            # 개별 등록되지 않은 지역의 fallback — Apple 미국/유로존 가격에 맞춘다
            fallback = base_plan.get('otherRegionsConfig')
            if fallback:
                usa, deu = target.get('USA'), target.get('DEU')
                if usa and usa[0] == 'USD':
                    fallback['usdPrice'] = money('USD', usa[1])
                if deu and deu[0] == 'EUR':
                    fallback['eurPrice'] = money('EUR', deu[1])

        plans[product_id] = patched
        print(f'=== {product_id}')
        print(f'  변경 {len(changed)} | 통화 달라 건너뜀 {len(other_currency)} '
              f'| 대상 외 {len(out_of_scope)}')
        for row in sorted(changed)[:8]:
            print('   ', row)

    if blocked:
        print('\n저장된 통화가 Google 기대값과 다른 지역이 있습니다 '
              '(지역, 저장됨, 기대):')
        for row in sorted(set(blocked)):
            print('   ', row)
        raise SystemExit(
            '\n이 지역이 섞여 있으면 PATCH 전체가 거부됩니다 '
            '(updateMask=basePlans는 전 지역을 다시 검증한다).\n'
            'Play Console에서 해당 지역 통화를 먼저 맞춘 뒤 다시 실행하세요. '
            '아무 가격도 바꾸지 않았습니다.')

    if not apply_changes:
        print('\n드라이런입니다. 실제로 바꾸려면 --apply 를 붙여 실행하세요.')
        return

    for product_id, body in plans.items():
        try:
            res = play_api.call(
                'PATCH',
                f'subscriptions/{product_id}?updateMask=basePlans'
                f'&regionsVersion.version={regions_version}'
                '&latencyTolerance=PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_SENSITIVE',
                body)
        except RuntimeError as err:
            if 'HTTP 403' in str(err):
                raise SystemExit(PERMISSION_HELP.format(
                    email=play_api.service_account()['client_email'])) from None
            raise
        shown = {r['regionCode']: r['price']
                 for r in res['basePlans'][0]['regionalConfigs']
                 if r['regionCode'] in ('KR', 'US', 'JP', 'GB', 'DE')}
        print(f'{product_id} 적용 완료 — {json.dumps(shown, ensure_ascii=False)}')


if __name__ == '__main__':
    main()
