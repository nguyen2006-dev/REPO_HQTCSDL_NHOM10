"""Run after dotnet build. Standard-library checks; no SQL Server needed."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

root = Path(__file__).resolve().parents[1]
web = root / 'src' / 'FilmContest.Web'
configuration = os.getenv('BUILD_CONFIGURATION', 'Debug')
dll = web / 'bin' / configuration / 'net8.0' / 'FilmContest.Web.dll'
if not dll.exists():
    raise SystemExit('Run dotnet build src/FilmContest.Web first')
base = 'http://127.0.0.1:5088'
env = {**os.environ, 'ASPNETCORE_ENVIRONMENT': 'Development',
       'Jwt__Key': 'smoke-test-only-key-123456789012345678901234567890',
       'Bootstrap__AdminEmail': '', 'Bootstrap__AdminPassword': ''}
with tempfile.TemporaryFile() as log:
    proc = subprocess.Popen([os.getenv('DOTNET_EXE', 'dotnet'), str(dll),
                             '--urls', base, '--contentRoot', str(web)],
                            env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        for attempt in range(60):
            try:
                urllib.request.urlopen(base + '/Account/Login', timeout=2).close()
                break
            except (urllib.error.URLError, TimeoutError):
                if proc.poll() is not None:
                    log.seek(0)
                    raise RuntimeError(log.read().decode(errors='replace'))
                time.sleep(.2)
        checks = []
        with urllib.request.urlopen(base + '/health/live', timeout=5) as response:
            assert json.load(response)['status'] == 'alive'
            checks.append({'path': '/health/live', 'status': response.status})
        for path in ['/Account/Login', '/Account/Register', '/Admin', '/Judge', '/Studio']:
            with urllib.request.urlopen(base + path, timeout=5) as response:
                text = response.read().decode()
                assert response.status == 200
                assert '__RequestVerificationToken' in text
                if path in ['/Admin', '/Judge', '/Studio']:
                    assert response.url.endswith('/Account/Login')
                checks.append({'path': path, 'status': response.status,
                               'final': response.url.removeprefix(base), 'csrf': True})
        try:
            urllib.request.urlopen(urllib.request.Request(base + '/Account/Login',
                                                          data=b'Email=x&Password=y'))
            raise AssertionError('POST without CSRF was accepted')
        except urllib.error.HTTPError as ex:
            assert ex.code == 400
            checks.append({'path': 'POST without CSRF', 'status': ex.code})
        import re
        jar = __import__('http.cookiejar', fromlist=['CookieJar']).CookieJar()
        opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
        with opener.open(base + '/Account/Register') as response:
            html = response.read().decode()
        token = re.search(r'name="__RequestVerificationToken"[^>]*value="([^"]+)"', html).group(1)
        from urllib.parse import urlencode
        data = urlencode({'__RequestVerificationToken': token, 'Name': 'Tester', 'Email': 'test@example.com'}).encode()
        with opener.open(base + '/Account/Register', data=data) as response:
            assert response.status == 200
            assert 'validation-summary-errors' in response.read().decode()
            checks.append({'path': 'POST register missing password with valid CSRF', 'status': response.status})
        print(json.dumps(checks, indent=2))
        print('PASS HTTP smoke checks (no SQL workflow exercised)')
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()
