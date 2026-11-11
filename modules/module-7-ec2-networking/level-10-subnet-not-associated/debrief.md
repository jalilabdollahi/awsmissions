# Debrief: associations connect tables to subnets

A route table does nothing until it is associated with a subnet (or gateway). Here nothing was wrong with the routes. The association pointed at the neighbour: the private database subnet got the internet route, and the app subnet was left on the main table.

This type of mix-up is easy to make because names like `public` live on the route table while the exposure is a property of the *subnet it is attached to*. It is also dangerous: it does not only break the app, it quietly exposes the database tier. The scanner finding was the only symptom on that side.

Real-world tips:
- Audit with `describe-route-tables` and check each subnet's *effective* table, not just the tables.
- Infrastructure as code (CloudFormation `SubnetRouteTableAssociation`, Terraform `aws_route_table_association`) makes the pairing explicit and reviewable.
- A subnet can have only one route table, but one table can serve many subnets. Re-associating replaces the old link instantly.
