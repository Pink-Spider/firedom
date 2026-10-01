"""Google Play Developer API 최소 클라이언트 (서비스 계정 + openssl RS256, 외부 의존성 없음).

자격증명은 `secret/`(git 제외) 또는 환경변수 PLAY_SERVICE_ACCOUNT 경로에서 읽는다.
"""
import json, time, base64, subprocess, urllib.request, urllib.parse, urllib.error, os, tempfile

_SA_PATH = os.environ.get('PLAY_SERVICE_ACCOUNT') or os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'secret', 'firedom-507906-7f8cff18af69.json')
_SA = None


def service_account():
    """서비스 계정 JSON — 없으면 무엇을 두어야 하는지 알려주고 끝낸다."""
    global _SA
    if _SA is None:
        if not os.path.exists(_SA_PATH):
            raise SystemExit(
                f'Play 서비스 계정 JSON을 찾을 수 없습니다: {_SA_PATH}\n'
                '환경변수 PLAY_SERVICE_ACCOUNT로 경로를 지정할 수 있습니다.')
        with open(_SA_PATH) as f:
            _SA = json.load(f)
    return _SA


PKG = 'app.firedom.firedom'
BASE = f'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PKG}/'
_tok = {'v': None, 'exp': 0}

def b64u(b): return base64.urlsafe_b64encode(b).rstrip(b'=').decode()

def token():
    if _tok['v'] and time.time() < _tok['exp'] - 60: return _tok['v']
    now = int(time.time())
    sa = service_account()
    claim = {'iss': sa['client_email'], 'scope': 'https://www.googleapis.com/auth/androidpublisher',
             'aud': 'https://oauth2.googleapis.com/token', 'iat': now, 'exp': now + 3600}
    signing = f"{b64u(json.dumps({'alg':'RS256','typ':'JWT'}).encode())}.{b64u(json.dumps(claim).encode())}".encode()
    with tempfile.NamedTemporaryFile(delete=False, suffix='.pem') as f: f.write(sa['private_key'].encode()); key = f.name
    with tempfile.NamedTemporaryFile(delete=False) as f: f.write(signing); msg = f.name
    sig = subprocess.check_output(['openssl','dgst','-sha256','-sign',key,msg]); os.unlink(key); os.unlink(msg)
    jwt = signing.decode() + '.' + b64u(sig)
    data = urllib.parse.urlencode({'grant_type':'urn:ietf:params:oauth:grant-type:jwt-bearer','assertion':jwt}).encode()
    t = json.load(urllib.request.urlopen(urllib.request.Request('https://oauth2.googleapis.com/token', data=data)))
    _tok['v'], _tok['exp'] = t['access_token'], now + t.get('expires_in', 3600)
    return _tok['v']

def call(method, path, body=None, absolute=False):
    url = path if absolute else BASE + path
    req = urllib.request.Request(url, method=method,
        headers={'Authorization': f'Bearer {token()}', 'Content-Type': 'application/json'},
        data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(req) as r:
            txt = r.read().decode(); return json.loads(txt) if txt else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError(f'HTTP {e.code}: {e.read().decode()[:1200]}') from None
