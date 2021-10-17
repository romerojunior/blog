---
layout: post
title: "Static Container Scanning with Clair and Klar (or Trivy)"
author: "Romero Galiza"
comments: true
---


## Introduction

Recently I came across this eye-opening [post](https://aws.amazon.com/blogs/containers/amazon-ecr-native-container-image-scanning/) about native security scanning in Amazon's Elastic Container Registry (ECR), and inspired by the architecture proposed by the authors I decided to document my pursuit on approaching a similar problem using an a set of open source solution. At that point I had no insight on what the community had to offer.

> When and how to scan images against common vulnerabilities using open source tooling?

On a personal note, I believe this question (or perhaps idea) might be biased by how we used to interact with less abstract resources, such as virtual machines. Vulnerability scanning for containerized applications certainly needs a fresh approach.

## Static Scanning

Static scanning refers to the act of checking an image against common security vulnerabilities before letting it hit production. Just like the authors of the Amazon's article, I will approach my problem from this front. To achieve my goal I will also be using [Clair](https://github.com/coreos/clair), an open source project for the static analysis of vulnerabilities in application containers (`appc` and `docker`).

![Scanning]({{ "/assets/registry.png" | relative_url }})

## Usage

> For more details on how to install Clair, please refer to their [official docs](https://github.com/coreos/clair/blob/master/Documentation/running-clair.md).

Think of Clair as an engine rather than an end user product. Once Clair is up and running, it will (after a while) aggregate information about vulnerabilities from [different sources](https://github.com/coreos/clair/blob/master/Documentation/drivers-and-data-sources.md) and expose an API which you (or an automated process) can interact with.

![Clair]({{ "/assets/clair.png" | relative_url }})

Dealing with Clair's API directly can be rather time consuming, instead I decided to check out [Klar](https://github.com/optiopay/klar), a command line tool to facilitate analysis of images stored in a private or public Docker registry using Clair. A command line API client. Klar is designed to be used as an integration tool, it relies on [enviroment variables](https://github.com/optiopay/klar#usage), which you can easily tame in any CI pipeline solution out there. Klar can be installed from [binaries or compiled from source](https://github.com/optiopay/klar/releases).

To test it locally:

```console
CLAIR_ADDR=http://your-clair-endpoint:6060 CLAIR_OUTPUT=Negligible JSON_OUTPUT=true CLAIR_THRESHOLD=10 klar ubuntu:latest
```

Klar follows the syntax `$ klar <image>`, whereas `<image>` should match the `REPOSITORY` string you see in `docker images` command output:

```console
$ docker images
REPOSITORY                 TAG                 IMAGE ID            CREATED             SIZE
quay.io/coreos/clair-git   latest              565aa423300b        7 months ago        423MB
postgres                   latest              599272bf538f        7 months ago        287MB

CLAIR_ADDR=http://your-clair-endpoint:6060 CLAIR_OUTPUT=Negligible JSON_OUTPUT=true CLAIR_THRESHOLD=10 klar quay.io/coreos/clair-git
```

The following result style is expected when using `JSON_OUTPUT=true`:

```json
{
  "LayerCount": 3,
  "Vulnerabilities": {
    "Critical": [
      {
        "Name": "RHSA-2018:3347",
        "NamespaceName": "centos:7",
        "Description": "The python-paramiko package provides a Python module that implements the SSH2 protocol for encrypted and authenticated connections to remote machines. Unlike SSL, the SSH2 protocol does not require hierarchical certificates signed by a powerful central authority. The protocol also includes the ability to open arbitrary channels to remote services across an encrypted tunnel. Security Fix(es): * python-paramiko: Authentication bypass in auth_handler.py (CVE-2018-1000805) For more details about the security issue(s), including the impact, a CVSS score, and other related information, refer to the CVE page(s) listed in the References section.",
        "Link": "https://access.redhat.com/errata/RHSA-2018:3347",
        "Severity": "Critical",
        "FixedBy": "0:2.1.1-9.el7",
        "FeatureName": "python-paramiko",
        "FeatureVersion": "2.1.1-4.el7"
      }
    ],
    "High": [
      {
        "Name": "RHSA-2019:0710",
        "NamespaceName": "centos:7",
        "Description": "Python is an interpreted, interactive, object-oriented programming language, which includes modules, classes, exceptions, very high level dynamic data types and dynamic typing. Python supports interfaces to many system calls and libraries, as well as to various windowing systems. Security Fix(es): * python: Information Disclosure due to urlsplit improper NFKC normalization (CVE-2019-9636) For more details about the security issue(s), including the impact, a CVSS score, acknowledgments, and other related information, refer to the CVE page(s) listed in the References section.",
        "Link": "https://access.redhat.com/errata/RHSA-2019:0710",
        "Severity": "High",
        "FixedBy": "0:2.7.5-77.el7_6",
        "FeatureName": "python",
        "FeatureVersion": "2.7.5-69.el7_5"
      },
      {
        "Name": "RHSA-2019:1294",
        "NamespaceName": "centos:7",
        "Description": "The Berkeley Internet Name Domain (BIND) is an implementation of the Domain Name System (DNS) protocols. BIND includes a DNS server (named); a resolver library (routines for applications to use when interfacing with DNS); and tools for verifying that the DNS server is operating correctly. Security Fix(es): * bind: Limiting simultaneous TCP clients is ineffective (CVE-2018-5743) For more details about the security issue(s), including the impact, a CVSS score, acknowledgments, and other related information, refer to the CVE page(s) listed in the References section.",
        "Link": "https://access.redhat.com/errata/RHSA-2019:1294",
        "Severity": "High",
        "FixedBy": "32:9.9.4-74.el7_6.1",
        "FeatureName": "bind-license",
        "FeatureVersion": "32:9.9.4-61.el7_5.1"
      }
    ]
  }
}
```

## Using Clair API directly

As explained, under the hood Klar will be contacting Clair API, but if you want to deal with it directly (implementing your own client, for example) you could find all information you need under their official API [documentation](https://coreos.com/clair/docs/2.0.1/api_v1.html).

To play around with it and run a scan on an image, you have to upload the image layer you would like to verify from your registry to Clair.

```console
curl -s -X POST http://your-clair-endpoint:6060/v1/layers --data @clair.json
```

The contents of `clair.json` are:

```text
{
  "Layer": {
    "Name": "sha256:123123773760869c33123123d1e5c4a91b15c5854987331459123123",
    "Path": "https://your-registry/v2/docker/some-image/blobs/sha256:123123773760869c33123123d1e5c4a91b15c5854987331459123123",
    "Headers": {
      "Authorization": "Basic 4Asdcc3ZjXHausdHAbns123TphUUNhaG4DASdw4eJQdjNRaAsd34J0="
    },
    "Format": "Docker"
  }
}
```

Clair only seems to care about the digest (`Layer.Name`) and an accessible path for tar file (`Layer.Path`) which represents the delta of that layer (the actual contents of that layer in a file system). These values can be retrieved from the registry your image is in.

Without Klar, you will need to verify all relevant layers manually, taking into account that empty layers generated by commands from Dockerfile like `CMD`, `EXPOSE` etc. never modify the content of the image and will always end up with the same digest:

```text
sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4
```

These can be ignored.

Again, metadata about fsLayers and their respective digest can be obtained from your registry manifests, for example:

```console
curl -s -X GET https://your-registry/v2/docker/some-image/manifests/latest
```

Once you feed clair with the layers you want to analyse, you will be able to retrieve scan results:

```console
curl -s -X GET  http://your-clair-endpoint:6060/v1/layers/sha256:123123773760869c33123123d1e5c4a91b15c5854987331459123123?features&vulnerabilities
```

The above will return a json object containing all vulnerabilities. Tedious process to go through manually.

## Alternative: Trivy

[Trivy](https://github.com/aquasecurity/trivy) is young but promising project, first found in Github about 6 months prior to the time I wrote this document. Their [latest release](https://github.com/aquasecurity/trivy/releases/tag/v0.1.7) contain binaries for different architectures, and it differs from Clair+Klar in the sense that it doesn't rely on any self-maintained database.

Ironically I decided to run a scan using Trivy on Clair's official docker image from my own laptop (running macOS Mojave), here's the result you might expect (all settings default):

```console
$ trivy quay.io/coreos/clair
1945-08-06T08:15:00.000+0100	INFO	Updating vulnerability database...
1945-08-06T08:15:10.000+0100	INFO	Updating ubuntu data...
 31675 / 31675 [================================================] 100.00% 15s
1945-08-06T08:15:25.000+0100	INFO	Updating amazon data...
 1445 / 1445 [================================================] 100.00% 2s
1945-08-06T08:15:27.000+0100	INFO	Updating nvd data...
 131396 / 131396 [================================================] 100.00% 1m31s
1945-08-06T08:16:58.000+0100	INFO	Updating alpine data...
 14000 / 14000 [================================================] 100.00% 4s
1945-08-06T08:17:02.000+0100	INFO	Updating redhat data...
 20675 / 20675 [================================================] 100.00% 11s
1945-08-06T08:17:13.000+0100	INFO	Updating debian data...
 29629 / 29629 [================================================] 100.00% 10s
1945-08-06T08:17:23.000+0100	INFO	Updating debian-oval data...
 63099 / 63099 [================================================] 100.00% 30s
1945-08-06T08:15:51.000+0100	INFO	Detecting Alpine vulnerabilities...

quay.io/coreos/clair (alpine 3.9.0)
===================================
Total: 35 (UNKNOWN: 1, LOW: 1, MEDIUM: 24, HIGH: 8, CRITICAL: 1)

+------------+------------------+----------+-------------------+---------------+-----------------------------------+
|  LIBRARY   | VULNERABILITY ID | SEVERITY | INSTALLED VERSION | FIXED VERSION |               TITLE               |
+------------+------------------+----------+-------------------+---------------+-----------------------------------+
| bzip2      | CVE-2019-12900   | HIGH     | 1.0.6-r6          | 1.0.6-r7      | bzip2: out-of-bounds write in     |
|            |                  |          |                   |               | function BZ2_decompress           |
+------------+------------------+          +-------------------+---------------+-----------------------------------+
| curl       | CVE-2019-5481    |          | 7.64.0-r1         | 7.64.0-r3     | curl: double free due to          |
|            |                  |          |                   |               | subsequent call of realloc()      |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-5482    |          |                   |               | curl: heap buffer overflow in     |
|            |                  |          |                   |               | function tftp_receive_packet()    |
+            +------------------+----------+                   +---------------+-----------------------------------+
|            | CVE-2019-5435    | MEDIUM   |                   | 7.64.0-r2     | curl: Integer overflows in        |
|            |                  |          |                   |               | curl_url_set() function           |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-5436    |          |                   |               | curl: TFTP receive                |
|            |                  |          |                   |               | heap buffer overflow in           |
|            |                  |          |                   |               | tftp_receive_packet() function    |
+------------+------------------+----------+-------------------+---------------+-----------------------------------+
| expat      | CVE-2018-20843   | HIGH     | 2.2.6-r0          | 2.2.7-r0      | expat: large number of colons     |
|            |                  |          |                   |               | in input makes parser consume     |
|            |                  |          |                   |               | high amount...                    |
+            +------------------+----------+                   +---------------+-----------------------------------+
|            | CVE-2019-15903   | MEDIUM   |                   | 2.2.7-r1      | expat: heap-based buffer          |
|            |                  |          |                   |               | over-read via crafted XML         |
|            |                  |          |                   |               | input                             |
+------------+------------------+          +-------------------+---------------+-----------------------------------+
| file       | CVE-2019-8904    |          | 5.35-r0           | 5.36-r0       | file: stack-based buffer          |
|            |                  |          |                   |               | over-read in do_bid_note in       |
|            |                  |          |                   |               | readelf.c                         |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-8905    |          |                   |               | file: stack-based buffer          |
|            |                  |          |                   |               | over-read in do_core_note in      |
|            |                  |          |                   |               | readelf.c                         |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-8906    |          |                   |               | file: out-of-bounds read in       |
|            |                  |          |                   |               | do_core_note in readelf.c         |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-8907    |          |                   |               | file: do_core_note in             |
|            |                  |          |                   |               | readelf.c allows remote           |
|            |                  |          |                   |               | attackers to cause a denial       |
|            |                  |          |                   |               | of...                             |
+            +------------------+----------+                   +---------------+-----------------------------------+
|            | CVE-2019-19218   | UNKNOWN  |                   | 5.36-r1       |                                   |
+------------+------------------+----------+-------------------+---------------+-----------------------------------+
| libarchive | CVE-2017-14501   | MEDIUM   | 3.3.2-r4          | 3.3.3-r0      | libarchive: Out-of-bounds read    |
|            |                  |          |                   |               | in parse_file_info                |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2017-14502   |          |                   |               | libarchive: Off-by-one error      |
|            |                  |          |                   |               | in the read_header function       |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2017-14503   |          |                   |               | libarchive: Out-of-bounds read    |
|            |                  |          |                   |               | in lha_read_data_none             |
+            +------------------+          +                   +---------------+-----------------------------------+
|            | CVE-2019-18408   |          |                   | 3.3.3-r1      | archive_read_format_rar_read_data |
|            |                  |          |                   |               | in                                |
|            |                  |          |                   |               | archive_read_support_format_rar.c |
|            |                  |          |                   |               | in libarchive before 3.4.0 has a  |
|            |                  |          |                   |               | use-after-free in a...            |
+------------+------------------+----------+-------------------+---------------+-----------------------------------+
| libssh2    | CVE-2019-3855    | CRITICAL | 1.8.0-r4          | 1.8.1-r0      | libssh2: Integer overflow in      |
|            |                  |          |                   |               | transport read resulting in       |
|            |                  |          |                   |               | out of bounds write...            |
+            +------------------+----------+                   +               +-----------------------------------+
|            | CVE-2019-3856    | MEDIUM   |                   |               | libssh2: Integer overflow in      |
|            |                  |          |                   |               | keyboard interactive handling     |
|            |                  |          |                   |               | resulting in out of bounds...     |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-3857    |          |                   |               | libssh2: Integer overflow in      |
|            |                  |          |                   |               | SSH packet processing channel     |
|            |                  |          |                   |               | resulting in out of...            |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-3858    |          |                   |               | libssh2: Zero-byte allocation     |
|            |                  |          |                   |               | with a specially crafted SFTP     |
|            |                  |          |                   |               | packed leading to an...           |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-3859    |          |                   |               | libssh2: Unchecked use of         |
|            |                  |          |                   |               | _libssh2_packet_require and       |
|            |                  |          |                   |               | _libssh2_packet_requirev          |
|            |                  |          |                   |               | resulting in out-of-bounds        |
|            |                  |          |                   |               | read                              |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-3860    |          |                   |               | libssh2: Out-of-bounds reads      |
|            |                  |          |                   |               | with specially crafted SFTP       |
|            |                  |          |                   |               | packets                           |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-3861    |          |                   |               | libssh2: Out-of-bounds reads      |
|            |                  |          |                   |               | with specially crafted SSH        |
|            |                  |          |                   |               | packets                           |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-3862    |          |                   |               | libssh2: Out-of-bounds memory     |
|            |                  |          |                   |               | comparison with specially         |
|            |                  |          |                   |               | crafted message channel           |
|            |                  |          |                   |               | request                           |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-3863    |          |                   |               | libssh2: Integer overflow         |
|            |                  |          |                   |               | in user authenticate              |
|            |                  |          |                   |               | keyboard interactive allows       |
|            |                  |          |                   |               | out-of-bounds writes              |
+------------+------------------+----------+-------------------+---------------+-----------------------------------+
| musl       | CVE-2019-14697   | HIGH     | 1.1.20-r3         | 1.1.20-r5     | musl libc through 1.1.23          |
|            |                  |          |                   |               | has an x87 floating-point         |
|            |                  |          |                   |               | stack adjustment imbalance,       |
|            |                  |          |                   |               | related...                        |
+------------+------------------+          +-------------------+---------------+-----------------------------------+
| nghttp2    | CVE-2019-9511    |          | 1.35.1-r0         | 1.35.1-r1     | HTTP/2: large amount of data      |
|            |                  |          |                   |               | requests leads to denial of       |
|            |                  |          |                   |               | service                           |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-9513    |          |                   |               | HTTP/2: flood using PRIORITY      |
|            |                  |          |                   |               | frames results in excessive       |
|            |                  |          |                   |               | resource consumption              |
+------------+------------------+----------+-------------------+---------------+-----------------------------------+
| openssl    | CVE-2019-1543    | MEDIUM   | 1.1.1a-r1         | 1.1.1b-r1     | openssl: ChaCha20-Poly1305        |
|            |                  |          |                   |               | with long nonces                  |
+            +------------------+          +                   +---------------+-----------------------------------+
|            | CVE-2019-1549    |          |                   | 1.1.1d-r0     | openssl: information              |
|            |                  |          |                   |               | disclosure in fork()              |
+            +------------------+          +                   +               +-----------------------------------+
|            | CVE-2019-1563    |          |                   |               | openssl: information              |
|            |                  |          |                   |               | disclosure in PKCS7_dataDecode    |
|            |                  |          |                   |               | and CMS_decrypt_set1_pkey         |
+            +------------------+----------+                   +               +-----------------------------------+
|            | CVE-2019-1547    | LOW      |                   |               | openssl: side-channel weak        |
|            |                  |          |                   |               | encryption vulnerability          |
+------------+------------------+----------+-------------------+---------------+-----------------------------------+
| sqlite     | CVE-2019-8457    | HIGH     | 3.26.0-r3         | 3.28.0-r0     | sqlite3: heap out-of-bound        |
|            |                  |          |                   |               | read in function rtreenode()      |
+            +------------------+----------+                   +---------------+-----------------------------------+
|            | CVE-2019-16168   | MEDIUM   |                   | 3.28.0-r1     | In SQLite through 3.29.0,         |
|            |                  |          |                   |               | whereLoopAddBtreeIndex in         |
|            |                  |          |                   |               | sqlite3.c can crash a browser     |
|            |                  |          |                   |               | or...                             |
+            +------------------+          +                   +---------------+-----------------------------------+
|            | CVE-2019-5018    |          |                   | 3.28.0-r0     | sqlite3: use-after-free in        |
|            |                  |          |                   |               | window function leading to        |
|            |                  |          |                   |               | remote code execution             |
+------------+------------------+----------+-------------------+---------------+-----------------------------------+
```
