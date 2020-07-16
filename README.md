# Octopus Helm Charts

This repository hosts official [Helm](https://helm.sh/) charts for [Octopus](https://github.com/cnrancher/octopus). These charts are used to deploy Octopus to the Kubernetes/k3s Cluster.

## Install Helm3

Read and follow the [Helm installation guide](https://helm.sh/docs/intro/install/).

**Note: The charts in this repository require Helm version 3.x or later.** 

## Add the Octopus Helm Chart repo

In order to be able to use the charts in this repository, add the name and URL to your Helm client:

```console
helm repo add octopus http://charts.cnrancher.cn/octopus
helm repo update
```

## Installing the Chart

To install the Octopus Chart into your Kubernetes/k3s cluster use:
```
kubectl create ns octopus-system
helm install --namespace octopus-system octopus octopus/octopus
```

After installation succeeds, you can get a status of Chart
```
helm status octopus
```

If you want to delete your Chart, use this command:
```
helm delete  octopus
```

The command removes nearly all the Kubernetes components associated with the
chart and deletes the release.

## Helm Chart and Octopus Support

Visit the [Octopus github issues](https://github.com/cnrancher/octopus/issues/) for support.

## License
Copyright (c) 2020 [Rancher Labs, Inc.](http://rancher.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
    
