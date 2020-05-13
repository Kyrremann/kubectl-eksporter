kubectl-eksporter
==================

> A simple Ruby-script to export k8s resources, and removes a pre-defined set of fields for later import


## Usage

```
kubectl eksporter <resource> <name>
```

`-n / --namespace` and other arguments are supported by proxy.

The eksporter also supports piping.


### Example

```
$ kubectl eksporter ingress testapp
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  labels:
    app: testapp
    environment: default
  name: testapp
spec:
  rules:
  - host: testapp.local
    http:
      paths:
      - backend:
          serviceName: testapp
          servicePort: 80
        path: "/"
```

The following command wil give the same result.
```
$ kubectl get ingress testapp -o yaml | kubectl eksporter
```


## Install

First you need install [Krew](https://krew.dev), by following the [installation guide](https://github.com/kubernetes-sigs/krew#installation).

Then just run `kubectl krew install eksporter`


## Why Ruby?

Python didn't have a built-in yaml-converter, and Go is a hassle to work with when you need generic data structures.


## Release

1. Make changes to the code
2. Create a tar-archive of the code
   * `tar -czvf eksporter.tar.gz eksporter.rb LICENSE`
3. Create new release on [Github](https://github.com/Kyrremann/kubectl-eksporter/releases/new)
4. Update `eksporter.yaml` with new version and sha
   * `sha256sum eksporter.tar.gz`
5. Test new release with krew
   * `kubectl krew install --manifest eksporter.yaml --archive eksporter.tar.gz`
6. Create PR for (krew-index](https://github.com/kubernetes-sigs/krew-index)
7. Wait for merge
