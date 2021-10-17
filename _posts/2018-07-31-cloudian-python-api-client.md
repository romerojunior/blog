---
layout: post
title: "Cloudian Python API Client"
author: "Romero Jr"
comments: true
---

[Ceph](https://ceph.com/ceph-storage/object-storage/) has been my choice for object storage ever since Giant has been released somewhere in 2016, but recently I have had the change to experience a different (and proprietary) flavour within the terms of capacity and performance scalability, S3 interface support, and data durability.

[Cloudian® HyperStore®](https://cloudian.com/products/hyperstore/) tries to solve what one would perhaps use [Ceph Object Gateway](http://docs.ceph.com/docs/master/radosgw/) (radosgw), which is to provide highly scalable object storage with a compliant S3 interface and features.

During my "trial" I decided to contribute to their product by writing a Python API client, available [here](https://github.com/romerojunior/cloudian-api).

You can easily install it via pip:

```
pip install cloudianapi
```

An simple usage example would be instantiating the client and following the same API calls documented on their documentation, as below:

```python
from cloudianapi.client import CloudianAPIClient

client = CloudianAPIClient(
    url="https://admin-api.example.org",
    user="super-admin",
    key="s3cr3t",
    port=8080
)

# # Print all nodes from a given region and their respective used capacity:
for node in client.monitor.nodelist(region="eu-east"):
    print '{node}: {value} KB used'.format(
        value=client.monitor.host(nodeId=node)['diskUsedKb']['value'],
        node=node
    )

# Deleting user Cartman from a given group:
client.user(method="DELETE", userId="Cartman", groupId="ABC")

# Adding user Butters to a given group:
payload = {
    "userId": "Butters",
    "groupId": "ABC",
    "userType": "User"
}

client.user(method='PUT', json=payload)

# Print details about a given node:
print client.monitor.host(nodeId="node01")
```