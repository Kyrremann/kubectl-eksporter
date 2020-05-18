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
2. Tag with `git tag -a v1.3.0`
3. New release is automated created and pushed to Krew
