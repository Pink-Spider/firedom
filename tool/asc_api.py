"""App Store Connect API 최소 클라이언트 (ES256 JWT를 openssl로 서명, 외부 의존성 없음).

키는 `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`(git 외부)에서 읽는다.
환경변수 ASC_KEY_ID / ASC_ISSUER_ID로 덮어쓸 수 있다.
"""
import base64, json, subprocess, sys, time, tempfile, os, urllib.request, urllib.error

KEY_ID = os.environ.get('ASC_KEY_ID', '8FZTAA3T77')
ISSUER = os.environ.get('ASC_ISSUER_ID', 'fe387068-11c4-467b-b275-c7ba5d54a813')
KEY_PATH = os.path.expanduser(f'~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8')
BASE = 'https://api.appstoreconnect.apple.com'
APP_ID = '6790997319'


def _b64u(b):
    return base64.urlsafe_b64encode(b).rstrip(b'=').decode()


def _der_to_raw(sig):
    """DER ECDSA 서명 → JWS raw(r||s) 64바이트."""
    i = 2
    assert sig[i] == 2
    rl = sig[i + 1]
    r = sig[i + 2:i + 2 + rl]
    i += 2 + rl
    assert sig[i] == 2
    sl = sig[i + 1]
    s = sig[i + 2:i + 2 + sl]
    return r.lstrip(b'\x00').rjust(32, b'\x00') + s.lstrip(b'\x00').rjust(32, b'\x00')


def token():
    now = int(time.time())
    header = _b64u(json.dumps({'alg': 'ES256', 'kid': KEY_ID, 'typ': 'JWT'}).encode())
    payload = _b64u(json.dumps({'iss': ISSUER, 'iat': now, 'exp': now + 1200,
                                'aud': 'appstoreconnect-v1'}).encode())
    signing = f'{header}.{payload}'.encode()
    with tempfile.NamedTemporaryFile(delete=False) as f:
        f.write(signing)
        path = f.name
    der = subprocess.check_output(['openssl', 'dgst', '-sha256', '-sign', KEY_PATH, path])
    os.unlink(path)
    return f'{header}.{payload}.{_b64u(_der_to_raw(der))}'


def call(method, path, body=None):
    url = path if path.startswith('http') else BASE + path
    req = urllib.request.Request(url, method=method,
        headers={'Authorization': f'Bearer {token()}', 'Content-Type': 'application/json'},
        data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(req) as r:
            txt = r.read().decode()
            return json.loads(txt) if txt else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError(f'HTTP {e.code}: {e.read().decode()[:1200]}') from None


if __name__ == '__main__':
    method, path = sys.argv[1], sys.argv[2]
    arg = json.loads(sys.argv[3]) if len(sys.argv) > 3 else None
    print(json.dumps(call(method, path, arg), ensure_ascii=False, indent=1))
