---
layout: post
title: "Infrastructure as code with Terraform CDK"
author: "Romero Galiza"
comments: true
---

## Why infrastructure as code?

As a response to the fast changing pace of nowadays market, operations teams
should spend less time on routine drudgery, but even with modern tools, the ease
of provisioning new infrastructure leads to an ever-growing portfolio of
systems, which often greatly differ in implementation, turning integration into
unnecessary time consuming puzzles.

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
Terraform and Helm.

Terraform builds an abstraction layer on the top of a variety of providers APIs,
such as AWS, GCP, Azure, Vault, Kubernetes, and so on. Still, a deep
understanding of these APIs is necessary. As a software engineer you still need
to make decisions on how to use their resources, which is ultimately followed by
the decision on how to organize and structure your Terraform code base, which is
then finally followed by the decision on how (and when) to apply such changes
(this last decision often implemented in continuous integration and delivery
routines).

This collection of decisions can be overwhelming, specially when working with
architectures such as microservices. Chris Richardson (2019) discusses the
importance of service decomposition and modularity in microservices, where
applications are loosely coupled and communicate only via APIs, leading to a
leaner code base. While true, this normally leads to an undesired infrastructure
overhead.

A microservice has similar infrastructure requirement to a monolith application,
it still needs data persistency, networking, security and observability.

## Decoupling strategy

Each application (or service) is contained in its own versioned repository and
should be aware, **at an abstract level**, what its own infrastructure
components and requirements are.

At this point, a language (or simply contract) where such components and
requirements can be universally described is needed. One way to approach this
is through a simplistic `.json` manifest, for example:

```json
{
  "infrastructureComponents": [
    {
      "componentType": "database",
      "name": "example",
      "properties": {
        "diskSizeGB": 20,
        "engine": {
          "type": "postgres",
          "version": "12"
        }
      }
    }
  ]
}
```

From the software engineer perspective, the example above removes the need for
understanding how or where this abstract "database" will be concretized.

It is clear that resources as complex as databases can posses a massive
amount of properties, therefore, this language or contract must come with a set
of well documented default values.

The team itself must determine what the defaults are. For example, these values
could be taken as "the recommended values for a minimal workload", where "a
minimal workload" consists of X, Y and Z.

With the above sorted out, we still need a tool to digest such manifests.

> While Terraform and alternatives like AWS CloudFormation succeeded in their
> mission, which is to codify cloud APIs into declarative configuration files,
> keeping the infrastructure code base "DRY" is perhaps one of the biggest
> challanges to this day, the market responded to this limitation with solutions
> like Terragrunt, yet, it doesn't feel quite right.
>
> CDK stands for cloud development kit. In practise, it is a SDK for cloud
> resources management. This pattern was initially envisioned by AWS, with its
> first public appearance dating back to 2019 during AWS re:Invent, in Las Vegas.
>
> Soon enough, major initiatives (like Hashicorp Terraform) started to adopt this
> pattern as an alternative to **declarative approaches** (where we describe an
> intended goal rather than the steps to reach that goal).
>
> Allowing engineers to pragmatically build and maintain cloud resources using
> well-known programming languages such as TypeScript quickly brought CDKs to the
> spotlight.

## Digesting manifests

You can rely on Terraform CDK to pragmatically create and orchestrate resources
across different providers based on such simplistic manifest file, which is the
basis for an unified abstraction layer to a set of reusable resources common to
a particular domain (or team).

Take the the proposed workflow, for example:

1. A sofware engineer provides what resource they need for an application named
   ABC in an abstract manner, like a "database", a "message queue topic", or a
   "secret".
2. An automated process builds the requested set of resources with an
   opinionated implementation that has been previously agreed upon. That is, the
   process itself knows where and how to build such resources based on minimal
   user input.
3. A second software engineer provides what resource they need for an
   application named XYZ in an abstract manner.
4. The same automated process from step 2 builds the requested set of resources
   with the same opinionated implementation.

Updating resouces works in the same way. Terraform CDK still relies on
plain Terraform. It synthetizes a plan based on controlled flow written in a
given programming language.

> ### Convention over configuration
>
> The aforementioned resources convey an opinion on how application and
> infrastructure components should look and behave. Various settings are taken as
> "convention" rather than "configuration", which decreases the amount of
> decisions a software engineer has to make.
>
> This could imply less flexibility, but it enforces a baseline standard from a
> single, programable, and versionable source.

## Gambling

The Terraform CDK project is still in its early stages. Committing all your
automation efforts into this single solution is still a gamble and its risks
must be carefully considered when off-loading infrastructure responsibility from
the daily software engineering tasks.

**A conservative implementation that can help mitigating some of the risks is to
still rely on plain Terraform modules as illustrated below.**

![Conservative architecture]({{ "/assets/cdk.svg" | relative_url }})

In this pattern "business logic" is decoupled from your Modules.

Modules answer the question of "what" (needs to be created or modified), and CDK
answers the question of "how" through control flows.
