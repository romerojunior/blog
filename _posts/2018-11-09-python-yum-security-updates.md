---
layout: post
title: "Python: Yum Security Updates"
author: "Romero Galiza"
comments: true
---

I have seen a lot of engineers attempting to come up with ways to deal with security reports, automated patching and so on. Every scenario requires tailored solutions driven by both technicalities such as operational systems and applications, and business requirements. This attempt (or simply "side note") is specific for operational systems using YUM package manager (notably CentOS and RHEL).

Since Yum has been written in Python, it provides us with modules to properly deal with its API. Although not very friendly, the official documentation is available [here](http://yum.baseurl.org/api/).

At first the script below might seem redundant (you might be able to achieve the same result using the yum command line interface) and completely informal, but think of it as an example of how to use the YUM API. Imagine that instead of generating a pretty table as the output, you would like to serialize it within a JSON string and push it to a NoSQL database such as DynamoDB in order to implement a state machine allowing a certain business logic to act upon specific conditions.

```python
#!/usr/bin/env python

from __future__ import print_function
import yum
from yum.update_md import UpdateMetadata
from prettytable import PrettyTable

base = yum.YumBase()
base.setCacheDir()

enabled_repos = base.repos.listEnabled()

md_info = UpdateMetadata()

for repo in enabled_repos:
    try:
        md_info.add(repo)
    except yum.Errors.RepoMDError:
        continue

package_list = base.doPackageLists(
  pkgnarrow='updates',
  patterns='',
  ignore_case=True
)

table = PrettyTable(
  ['Severity', 'Id', 'Issued', 'Package', 'Version']
)

for pkg in package_list.updates:
    notice = md_info.get_notice(pkg.nvr)
    if notice:
        md = notice.get_metadata()
        if md['type'] == 'security':
            table.add_row(
                [
                    md['severity'],
                    md['update_id'],
                    md['issued'],
                    pkg.name,
                    str(pkg.evr)
                ]
            )

print(table)
```
