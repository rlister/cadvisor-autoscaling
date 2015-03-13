# cAdvisor Autoscaling

## Wut?

So, I had this VPC in AWS, pretty locked-down and minimalist, and
inside this VPC ran several microservices from autoscaling groups, and
I was all like, what's running?

So this runs inside your VPC, gets a list of instances for your
autoscaling groups, and hits cAdvisor on each instance private IP to
find out what containers are running. Simples.

## Configure

Set env vars:

```
AWS_DEFAULT_REGION
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

or, actually, don't. Use IAM roles instead like the cool kids.

Limit set of autoscaling groups to list by setting
`CADVISOR_AUTOSCALING_MATCH` to a regex to match group name.

## Run

```
bundle exec unicorn -p 3000 -c config/unicorn.rb
```

## Docker

Comes with a `Dockerfile`. Build your own, or pull from hub.

```
docker run -d -e CADVISOR_AUTOSCALING_MATCH='^foo-' -p 3000:3000 rlister/cadvisor-autoscaling
```
