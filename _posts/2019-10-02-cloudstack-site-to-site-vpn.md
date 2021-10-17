---
layout: post
title: "CloudStack: Site-to-Site VPN between regions"
author: "Romero Galiza"
comments: true
---

## Problem

How can I interconnect VPCs from different regions knowing that each region is controlled by its own cluster of management servers. Our scenario involves two different regions, for the sake of this example, let us name them simply RegionA and RegionB.

## Solution (irrelevant settings and values are ommited)

### Step 1: Create a VPC in each region

### Step 2: Create a Site-to-Site VPN for each VPC created in step 1

If you're using the UI, go to Networks (left-side menu), then click on the the RegionA VPC and then click on button Configure. You will be prompted with a diagram, click on Site-to-Site VPNs inside the VPC. There you must create a new endpoint with a public IP address (normally this should be automatically assigned). The idea behind this step is that each VPC in each region will have its own public endpoint. Repeat the step for RegionB. Save these addresses, we will need them later.

### Step 3: Create a Customer Gateway for each Region

When creating a customer gateway for RegionA, make sure it point to the RegionB Site-to-Site VPN endpoint address created in step 2 (it must go under the Gateway field), and RegionB customer gateway should point to RegionA Site-to-Site VPN endpoint.

![Cosmic]({{ "/assets/cosmic-gateway.png" | relative_url }})

* The CIDR list field must contain the networks (tiers) from the remote VPC, separated by comma. Only add networks that you would like to make accessible from within your VPC.

* Note that the customer gateway holds all IPSEC settings, these are a PSK, IKE and ESP settings, they should match between regions.

### Step 4: Create a VPN Connection for both RegionA and RegionB VPCs

Each VPN Connection should be associated with a VPN Customer Gateway, they should be selected within a dropdown menu. One of them must be marked as Passive (this instante will wait for the connection to be innitiated by the other region).
