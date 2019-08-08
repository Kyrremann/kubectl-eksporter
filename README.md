kubeflow-eksporter
==================

> A simple Ruby-script to export k8s resources, and removes a pre-defined set of fields for later import


## Usage

```
kubectl eksporter <resource> <name>
```

`-n / --namespace` is supported by proxy.


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


## Install

First you need install [Krew](https://krew.dev), by following the [installation guide](https://github.com/kubernetes-sigs/krew#installation).

Then just run `kubectl krew install eksporter`


## Why Ruby?

Python didn't have a built-in yaml-converter, and Go is a hassle to work with when you need generic data structures.
