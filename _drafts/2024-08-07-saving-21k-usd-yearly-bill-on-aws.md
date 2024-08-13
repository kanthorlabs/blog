---
title: Saving 21k USD yearly bill on AWS
date: 2023-01-22 20:00:00 +0700
categories: [DevOps]
tags: [aws]
---

TL;DR: I have replaced AWS managed with self-hosted service to reduce our yearly bill on AWS from 35k USD to 14k USD.

## A historical story about our infrastructure

Three years ago, at the begining of a young startup, we had to face many problems from business side to technical side. The most important thing was ship our feature as soon as possible, release a first Instagram live-commerce support on Malaysia for instance. So we throwed away the infrastructure headache by adopt AWs solution for our infrastructure setup from database, message queue, autoscalling compute, ... So we decide to let both Production and User Acceptance Testing (UAT) environment have the same setup except UAT is for internal team including developers, QA, Customer Success and Production is for our merchants.

We also aware that the decision is just a temporary solution which bought us enough time to become a successful startup. So we tried to use as many replacable cloud component as possible. For example we are using Kubernetes so we will not be locked in AWS ECS, RabbitMQ for queuing, MySQL and PostgreSQL for database, OpenSearch for fulltext search, ...

## Evaluate our UAT infrastructure

Because the UAT infrastructure is same as the one we have used on Production environment so it also extends the reliability, scalability and maintainability. For example, adding compute to EKS (Elastic Kubernetes Service on AWS) is just some changes in Terraform files and we will have new nodes on EKS in 3-5 minutes. Another good example is Cloudwatch, just some configuration and you have your log at your hand to debug production issue.

But do we need it good as it is? Expecially at the cost AWS charge us for just a non-important environment like that? We agreed that it's not fine. So it's time to start get our hand dirty.

It's also worth to note that even our junior developer can install, update, start or stop on-premise service smoothy. It's because we have internal traning about maintaining our service at home. Yeah it's me, the one who train them to setup their homelab. It's funny hah! So even on-premise service got issue, we can let anybody in our team to handle it.

So we agreed that hardware cost is not efficient, our people are happy to maintain on-premise service, and it's time to start the journey.

## EKS

One of most important issue we have facing with EKS is they limit how many pod a node can have. On UAT environment, we have lightweight applications that are tiny, plenty and mostly idle. So we can save money by increasing pod per node limit so that we can use fewer nodes

Another thing is Extended Support charge for EKS. According to the document of [AWS EKS Extended Support Pricing](https://aws.amazon.com/blogs/containers/amazon-eks-extended-support-for-kubernetes-versions-pricing/) you have to pay for additional $0.5/h (or $365 per month) for EKS cluster that is not in Standard Support version. Maintain Kubernetes version update on Production is enough for us, we don't want to maintain it on our UAT.

So we chose to host [k3s](https://k3s.io/) on EC2 instance. The setup is easy, one master node and some worker nodes. We also setup backup and restore for our cluster by uploading the snapsnot of SQLite to S3. You can find more information at [K3s Backup and Restore](https://docs.k3s.io/datastore/backup-restore)

Saving: **1139 USD/month** or **13668 USD/year**

| Name                   | AWS Cost (USD/month) | Self-hosted Cost (USD/month) | Saving (USD/month) |
| ---------------------- | -------------------- | ---------------------------- | ------------------ |
| Kubernetes Master Node | 73                   | 34                           | 39                 |
| Kubernetes Worker Node | 1800                 | 700                          | 1100               |

## MySQL and PostgreSQL

You will curious about how a startup need to use two different SQL databases? It's a consequence of migrating from modular system to micorservices. Now we are living in a world that have two SQL databases in different codebases.

We chose to install both MySQL and PostgreSQL in same EC2 instance to save cost. The installation of both MySQL and PostgreSQL are easy, just some commands and you can boot them up. Setup backup cronjob to uploading them into S3 will take you couple of hour ;D. I'm seriously about setup backup cronjob, it will take more time than you think

| Name                      | AWS Cost (USD/month) | Self-hosted Cost (USD/moth) | Saving (USD/month) |
| ------------------------- | -------------------- | --------------------------- | ------------------ |
| MySQL Instance            | 380                  | 69                          | 311                |
| MySQL Storage             | 55                   | 24                          | 31                 |
| MySQL Backup Storage      | 57                   | 15                          | 32                 |
| PostgreSQL Instance       | 380                  | 0                           | 380                |
| PostgreSQL Storage        | 55                   | 24                          | 31                 |
| PostgreSQL Backup Storage | 57                   | 15                          | 32                 |

Saving: **817 USD/month** or **9804 USD/year**

## OpenSearch

Install OpenSearch have more caveats than install MySQL or PostgreSQL by because you have to setup both basic authentication and SSL to get your install work as expect with AWS OpenSearch SDK.

So we chose to install OpenSearch and Nginx in a EC2 instance. OpenSearch is just a basic search engine and Nginx is responsible for both basic authentication and SSL.

| Name                 | AWS Cost (USD/month) | Self-hosted Cost (USD/moth) | Saving (USD/month) |
| -------------------- | -------------------- | --------------------------- | ------------------ |
| OpenSearch Instances | 245                  | 69                          | 176                |
| OpenSearch Storage   | 49                   | 36                          | 13                 |

Saving: **189 USD/month** or **2268 USD/year**
