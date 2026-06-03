mkdir -p ssl
# Generate self-signed cert with SAN for titus.local.
# The SAN (subjectAltName) is required for modern TLS hostname verification;
# CN-only matching is no longer accepted by browsers or httpx/Python ssl.
openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout ssl/key.pem -out ssl/cert.pem \
  -days 365 \
  -subj "/C=GB/ST=Cambridgeshire/L=Cambridge/O=HerdedCats/CN=web" \
  -addext "subjectAltName=DNS:titus.local,DNS:web,DNS:localhost,IP:127.0.0.1"
