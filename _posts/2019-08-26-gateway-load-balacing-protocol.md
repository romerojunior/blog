---
layout: post
title: "Gateway Load Balancing Protocol"
author: "Romero Jr"
comments: true
---

If you came this far you probably have seen acronyms such as VRRP (Virtual Router Redundancy Protocol) and perhaps HSRP (Hot Standby Router Protocol). They all share the same denominator: first hop redundancy. Speaking plainly, first hop redundancy can be achieved by a series of techniques which might include well-known protocols (focus of this discussion), virtual chassis (such as the one implemented by Juniper), clustered hardware (mostly found on firewalls modules and load balancers), and so on. Gateway Load Balancing Protocol is a proprietary alternative - developed by Cisco - for protocol like VRRP, HSRP, and CARP.

The main advantage GLBP offers is (as its name suggests) the traffic load balancing within a pool of GLBP aware devices, where all routers will actively forward traffic. Both VRRP and HSRP provides you with an active-backup architecture, which depending on the set-up might represent a waste of forwarding capacity, making engineers wonder: "Why must I use only one if I could be using both?"

Load balancing, or more specifically: load sharing, however, can also be accomplished with VRRP or HSRP by simply using multiple instances of themselves. For example: VLANs 10, 20 and 30 might have the highest HSRP priority set to Router-A, and VLANs 40 and 50 to Router-B. This kind of set-up can easily become complex and difficult to maintain, which makes it an unusual practice, not to mention that the amount of traffic being forwarded per second by each of these VLANs is unpredictable, resulting in a highly discrepant load in each of the routers.

As already stated, GLBP's task it to maintain a list of routing devices, allowing every device in that list to route traffic in a round-robin manner. This behaviour is completely transparent for the hosts pointing to the GLBP virtual IP address, and it will bring as result a better back-plane capacity usage together with the so expected redundancy.

Behind the curtains each physical device will receive a virtual MAC address, and whenever an ARP request is received (querying the MAC address of virtual IP address) GLBP will instruct a real router to answer with its virtual physical address, therefore, the host will end up with an ARP entry containing the virtual IP address associated with a virtual MAC address, of Router-B, for i.e. Schematically we have:

![GLBP Diagram]({{ "/assets/glbp.png" | relative_url }})

For a second request, GLBP will instruct a different router to send a reply, and so on. Besides the basic round-robin method, GLBP also supports host-dependent and weighted balancing (check official documentation for more details). The AVG acronymn (R1, diagram above) stands for Active Virtual Gateway, his role is to be the primary device answering in behalf of the virtual IP address, he is the one sending out ARP replies for all active routers in the GLBP pool (R1, R2 and R3, diagram above). The remaining routers in the pool are called AVF (Active Virtual Forwarder) in the GLBP terminology. Please note that the AVG has a dual role in this play, he will also act as a AVF by fowarding traffic.

In case the AVG fails, another will be elected based on a pre-defined priority (highest comes first). In case one of the AVF fails, another AVF will start answering for its virtual MAC address. The heartbeat (a well-known technique that defines when a member of a generic cluster is dead or alive) is done through the exchange of 'Hello' messages, and each cluster might contain up to four members.

'Hello' messages are sent out to the multicast IP address 224.0.0.102, encapsulated within UDP datagrams on port 3222, its PDU possess 60 bytes (plus 8 extra bytes for the UDP header).

![Wireshark GLBP]({{ "/assets/wireshark_glbp.png" | relative_url }})

If you are familiar with VRRP or HSRP, the configuration steps will be particularly comforting, as the following:

```
R1(config-if)# glbp <instance number> ?
  authentication  Authentication method
  forwarder       Forwarder configuration
  ip              Enable group and set virtual IP address
  load-balancing  Load balancing method
  name            Redundancy name
  preempt         Overthrow lower priority designated routers
  priority        Priority level
  timers          Adjust GLBP timers
  weighting       Gateway weighting and tracking
```

GLBP must be configured in all AVF, they must hold the same IP address (not necessarily under the same instance number). The priority option will determine the AVG, and its default value is 100. You also might want to set up preemption. Remember: deterministic environments are easier to maintain over time.