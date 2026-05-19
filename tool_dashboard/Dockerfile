FROM python:3.12-slim

ENV PORT=8501

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libmariadb-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . .

RUN pip3 install --no-cache-dir --no-compile -r requirements.txt

# Fix Streamlit bug: _get_provider_logout_url calls load_server_metadata()
# without awaiting it (it's a coroutine in the Authlib Starlette client), and
# the function itself is sync while its caller _auth_logout is async, so
# asyncio.run() would fail with "event loop already running".
# Fix: make _get_provider_logout_url async and properly await the call.
#  Reference: Streamlit github PRs #11901 (fix), #12693 (refix), #13571 (regression)
RUN python3 << 'PYEOF'
import sys
path = next(p for p in sys.path if 'site-packages' in p) + '/streamlit/web/server/starlette/starlette_auth_routes.py'
content = open(path).read()
patches = [
    (
        'def _get_provider_logout_url(request: Request) -> str | None:',
        'async def _get_provider_logout_url(request: Request) -> str | None:',
    ),
    (
        "        # Load OIDC metadata - Authlib's Starlette client uses async methods\n        # but load_server_metadata is synchronous in both implementations\n        metadata = client.load_server_metadata()",
        "        # load_server_metadata is async in the Starlette client; await it.\n        metadata = await client.load_server_metadata()",
    ),
    (
        '    provider_logout_url = _get_provider_logout_url(request)',
        '    provider_logout_url = await _get_provider_logout_url(request)',
    ),
]
for old, new in patches:
    assert old in content, f'Streamlit logout patch: pattern not found (version changed?): {old[:60]}'
    content = content.replace(old, new)
open(path, 'w').write(content)
print('Streamlit logout patch applied (3 changes)')
PYEOF

EXPOSE ${PORT}

HEALTHCHECK CMD curl --fail http://localhost:${PORT}/_stcore/health

ENTRYPOINT /bin/bash run_dashboard.sh --port=${PORT} --streamlit-path=streamlit
