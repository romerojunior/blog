---
layout: post
title: "Use case: Infrastructure as code with Terraform CDK"
author: "Romero Galiza"
comments: true
---

## Why infrastructe as code?

As a response to the fast changing pace of nowadays market, operations teams
should spend less time on routine drudgery, but even with modern tools, the ease
of provisioning new infrastructure leads to an ever-growing portfolio of
systems, which often differ in implementatio, turning integration into
unnecessary puzzles.

According to Kief Morris (2016), infrastructure as code comes as an approach to
automate infrastructure based on practises from software development,
emphasizing idempotent, repeatable routines for provisioning and changing
systems and their configuration.

> *"The premise is that modern tooling can treat infrastructure as if it were*
> *software and data." (Kief Morris, 2016)*


## Problem description

With the advancements and increasing popularity of cloud providers, software
development teams are now closer to infrastructure than ever, however, it is
still somewhat unrealistic to expect software engineers to fully understand all
resources and architectural caveats that surrounds their application.

A handful of technologies have been developed to aid this task, such as
Terraform and Kubernetes.

Terraform builds an abstraction layer on the top of a variety of providers APIs,
such as AWS, GCP, Azure, Vault, and so on. Still, a deep understanding of these
APIs is necessary. As a software engineer you still need to take decisions on
how to use and apply them, which is ultimately followed by the decisions on how
to organize and structure your Terraform code base, which in finally followed by
the decision on how (and when) to apply such changes.

This collection of decisions can be overwhelming, specially when working with
architectures such as microservices, for example, Chris Richardson (2019)
discusses the importance of service decomposition and modularity, where services
are loosely coupled and communicate only via APIs, leading to leaner
applications. While true, this normally leads to undesired infrastructure
overhead.

A microservice requires at least the same level of attention to infrastructure
as a monolithic would.

## CDK

While Terraform and alternatives like AWS CloudFormation succeeded in their
mission, which is to codify cloud APIs into declarative configuration files,
keeping the infrastructure code base "DRY" is perhaps one of the biggest
challanges to this day, the market responded to this limitation with solutions
like Terragrunt, yet, it doesn't feel quite right.

CDK stands for cloud development kit. In practise, it is a SDK for cloud
resources management. This pattern was initially envisioned by AWS, with its
first public appearance dating back to 2019 at AWS re:Invent.

Soon enough, major initiatives (like Hashicorp Terraform) started to adopt this
pattern as an alternative to **declarative approaches** (where we describe an
intended goal rather than the steps to reach that goal).

Allowing engineers to pragmatically build and maintain cloud resources, using
well-known programming languages, such as TypeScript brought CDKs to the
spotlight.

## Approach

What if we could build a software to pragmatically create and orchestrate
resources across different providers based on a simplistic manifest file, thus
offering an unified abstraction layer to a set of reusable resources common to a
particular domain.

The proposed lifecycle:

* A sofware engineer should provide what resource they need in an abstract
  manner, like a "database", a "message queue topic", or a "secret".
* Automation builds their abstract resources with a flavoured implementation,
  common to a domain (or team).

## Convention over configuration

The aforementioned reusable resources convey an opinion on how application and
infrastructure components should look and behave. Various settings are taken as
"convention" rather than "configuration", which decreases the amount of
decisions an application developer has to make.

This could imply less flexibility, but it enforces a baseline standard from a
single, programable, and versionable source.


