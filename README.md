# kindest

## FluxCD Bootstrap

```bash

export GITHUB_TOKEN=$(gh auth token)
flux check --pre

flux bootstrap github \
  --token-auth \
  --owner=diskmanti \
  --repository=kindest\
  --branch=main \
  --path=clusters/main \
  --personal
```