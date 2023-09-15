# Copacetic Action

This action patches vulnerable containers using [Copa](https://github.com/project-copacetic/copacetic). Copacetic Action is supported with Copa version 0.3.0 and later.

## Inputs

## `image`

**Required** The image reference to patch.

## `image-report`

**Required** The trivy json vulnerability report of the image to patch.

## `patched-tag`

**Required** The new patched image tag.

## `buildkit-version`

**Optional** The buildkit version used in the action, default is latest.

## `copa-version`

**Optional** The Copa version used in the action, default is latest.

## `buildkitd-address`

**Optional** The address of buildkitd service, default is `tcp://127.0.0.1:8888`.

## Output

## `patched-image`

Image reference of the resulting patched image.

## Example usage

```
on: [push]

jobs:
    test:
        runs-on: ubuntu-latest

        strategy:
          fail-fast: false
          matrix:
            # provide relevant list of images to scan on each run
            images: ['docker.io/library/nginx:1.21.6', 'docker.io/openpolicyagent/opa:0.46.0', 'docker.io/library/hello-world:latest']

        steps:
        - name: Set up Docker Buildx
          uses: docker/setup-buildx-action@ecf95283f03858871ff00b787d79c419715afc34

        - name: Generate Trivy Report
          uses: aquasecurity/trivy-action@465a07811f14bebb1938fbed4728c6a1ff8901fc
          with:
            scan-type: 'image'
            format: 'json'
            output: 'report.json'
            ignore-unfixed: true
            vuln-type: 'os'
            image-ref: ${{ matrix.images }}

        - name: Check Vuln Count
          id: vuln_cout
          run: |
            report_file="report.json"
            vuln_count=$(jq '.Results | length' "$report_file")
            echo "vuln_count=$vuln_count" >> $GITHUB_OUTPUT

        - name: Copa Action
          if: steps.vuln_cout.outputs.vuln_count != '0'
          id: copa
          uses: project-copacetic/copa-action@v1.0.0
          with:
            image: ${{ matrix.images }}
            image-report: 'report.json'
            patched-tag: 'patched'
            buildkit-version: 'v0.11.6'
            # optional, default is latest
            copa-version: '0.3.0'
            # optional, default is tcp://127.0.0.1:8888
            buildkitd-address: 'unix:///var/run/docker.sock`

        - name: Login to Docker Hub
          if: steps.copa.conclusion == 'success'
          id: login
          uses: docker/login-action@465a07811f14bebb1938fbed4728c6a1ff8901fc
          with:
            username: 'user'
            password: ${{ secrets.DOCKERHUB_TOKEN }}

        - name: Docker Push Patched Image
          if: steps.login.conclusion == 'success'
          run: |
            docker push ${{ steps.copa.outputs.patched-image }}

```
