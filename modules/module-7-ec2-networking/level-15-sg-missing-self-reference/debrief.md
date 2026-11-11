# Debrief: sharing a security group is not trust

A common misconception is that instances in the same security group can reach each other. They cannot: the *default* group has a self-referencing rule, but any group you create does not. A rule whose source is the group's own id says "any network interface that carries this group may connect", which is exactly what a cluster needs.

Why it beats a CIDR:
- It follows autoscaling and replacement: new nodes join the group and are instantly admitted; terminated ones disappear from the rule.
- It cannot be reached from outside the group, even from other hosts in the same subnet.

Gossip protocols (Serf, Consul, Cassandra, Redis Cluster...) commonly need *both* TCP and UDP, and the failure is silent: the nodes simply never see peers. When a cluster will not form, test each direction and protocol, and check the rule list per protocol rather than per port.
