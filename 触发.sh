curl \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/yiguihai/shadowsocks_install/actions/workflows/build.yml/dispatches \
  -u "yiguihai:Personal access tokens" \
  -d '{"ref": "dev", "inputs": {"ssh": "no","reset": "no"}}'
  
curl -u "yiguihai:Personal access tokens" https://api.github.com
