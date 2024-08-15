---
title: Saving 37k USD yearly bill on AWS
date: 2023-01-22 20:00:00 +0700
categories: [DevOps]
tags: [aws, self-hosted]
---

**TL;DR**: I replaced AWS managed services with self-hosted solutions, resulting in a yearly savings of $37,000.

## A brief history of our infrastructure

Three years ago, at the beginning of our startup, we faced numerous challenges, both on the business and technical fronts. Our top priority was to deliver features as quickly as possible, such as launching the first Instagram live-commerce support in Malaysia. To avoid the complexities of managing our own infrastructure, we adopted AWS solutions for everything from databases and message queues to auto-scaling compute resources. We decided to set up both the Production and User Acceptance Testing (UAT) environments similarly, with the key difference being that UAT was designated for internal teams—including developers, QA, and Customer Success—while Production was reserved for our merchants.

We were also aware that this decision was a temporary solution, providing us the necessary time to grow into a successful startup. With this in mind, we aimed to use as many replaceable cloud components as possible. For example, we chose Kubernetes to avoid being locked into AWS ECS, RabbitMQ for queuing, MySQL and PostgreSQL for databases, and OpenSearch for full-text search, among others.

## Evaluate our UAT infrastructure

Because the UAT infrastructure is the same as the one used in our Production environment, it also extends reliability, scalability, and maintainability. For example, adding compute resources to EKS (Elastic Kubernetes Service on AWS) requires just a few changes in Terraform files, and new nodes can be up and running in 3-5 minutes. Another good example is CloudWatch; with minimal configuration, logs are readily available for debugging issues.

But do we really need the UAT environment to be as robust as the Production environment, especially considering the costs AWS charges for a non-critical setup? We agreed that perfection isn't necessary for the UAT environment, and the hardware costs were not justified. For example, the database can be down for a few minutes during maintenance, adding new compute can be slower if we manually spin up new nodes, and we could opt for an on-premise APM solution instead of the more expensive CloudWatch. It was time to start getting our hands dirty.

## EKS

One of the most important issues we faced with EKS is the limitation on the number of pods a node can support. In the UAT environment, we run lightweight applications that are small, numerous, and mostly idle. By increasing the pod-per-node limit, we can reduce the number of nodes required and save on costs.

Another consideration is the Extended Support charge for EKS. According to the [AWS EKS Extended Support Pricing](https://aws.amazon.com/blogs/containers/amazon-eks-extended-support-for-kubernetes-versions-pricing/) documentation, an additional $0.50 per hour (or $365 per month) is required for EKS clusters that are not on the Standard Support plan. Since maintaining Kubernetes version updates is only critical for our Production environment, we have decided not to extend this support to our UAT environment.

So, we chose to host [K3s](https://k3s.io/) on EC2 instances. The setup is straightforward, with one master node and several worker nodes. We also implemented backup and restore for our cluster by uploading SQLite snapshots to S3. For more information, refer to the [K3s Backup and Restore](https://docs.k3s.io/datastore/backup-restore) documentation.

Saving: **1504 USD/month** or **18048 USD/year**

| Name                                   | AWS Cost (USD/month) | Self-hosted Cost (USD/month) | Saving (USD/month) |
| -------------------------------------- | -------------------- | ---------------------------- | ------------------ |
| Kubernetes Master Node                 | 73                   | 34                           | 39                 |
| Kubernetes Worker Node                 | 1800                 | 700                          | 1100               |
| Kubernetes Extended Support Extra Cost | 365                  | 0                            | 365                |

## RabbitMQ

We replaced AWS RabbitMQ with a simple deployment on our Kubernetes cluster using the [Bitnami RabbitMQ Helmchart](https://github.com/bitnami/charts/tree/main/bitnami/rabbitmq).

Saving: **184 USD/month** or **2208 USD/year**

| Name          | AWS Cost (USD/month) | Self-hosted Cost (USD/month) | Saving (USD/month) |
| ------------- | -------------------- | ---------------------------- | ------------------ |
| RabbitMQ Node | 263                  | 79                           | 184                |

## MySQL and PostgreSQL

You might wonder why a startup would need to use two different SQL databases. This situation resulted from our migration from a modular system to microservices. We now operate with two SQL databases across different codebases. I don't like it, but we’re stuck with it for now.

We chose to install both MySQL and PostgreSQL on the same EC2 instance to save costs. The installation of both databases is straightforward; a few commands will get them up and running. Setting up a backup cron job to upload the backups to S3 will take a couple of hours. I’m serious about the backup cronjob, it will take more time than you might expect 😊.

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

Installing OpenSearch involves more complexities than installing MySQL or PostgreSQL because you need to configure both basic authentication and SSL to ensure proper functionality with the AWS OpenSearch SDK.

So, we chose to install OpenSearch and Nginx on an EC2 instance. OpenSearch serves as a basic search engine, while Nginx handles both basic authentication and SSL. For SSL generation and auto-renewal, `certbot` and the `python3-certbot-nginx` package are invaluable. They work like a charm and are very easy to use.

| Name                 | AWS Cost (USD/month) | Self-hosted Cost (USD/moth) | Saving (USD/month) |
| -------------------- | -------------------- | --------------------------- | ------------------ |
| OpenSearch Instances | 245                  | 69                          | 176                |
| OpenSearch Storage   | 49                   | 36                          | 13                 |

Saving: **189 USD/month** or **2268 USD/year**

## Cloudwatch and X-Ray

CloudWatch and X-Ray are the most difficult services to replace due to their convenience on AWS. We tested several open-source projects, such as Sentry, SigNoz, and Uptrace, but none provided the same experience as CloudWatch on AWS. Additionally, to avoid vendor lock-in, we chose OpenTelemetry as our primary observability platform. The challenging part was selecting an integration for OpenTelemetry. After some testing, we chose Uptrace as our integration because it integrates seamlessly with OpenTelemetry.

Self-hosting Uptrace is straightforward; you only need one EC2 instance and 200 GB of EBS storage.

| Name               | AWS Cost (USD/month) | Self-hosted Cost (USD/moth) | Saving (USD/month) |
| ------------------ | -------------------- | --------------------------- | ------------------ |
| Cloudwatch Logs    | 350                  | 79                          | 271                |
| Cloudwatch Metrics | 110                  | 0                           | 110                |
| X-Ray              | 55                   | 0                           | 55                 |

Saving: **436 USD/month** or **5232 USD/year**

**Note:** This change took twice as long as all other service replacements because we needed to alter our methods for collecting logs, metrics, and traces. This meant that code had to be updated to work with OpenTelemetry collectors, requiring thorough testing before deployment. Furthermore, some services cannot be easily integrated with OpenTelemetry due to AWS limitations or because the cost of making the change exceeds the cost of continuing with AWS. For such services, like AWS Lambda, we decided to retain CloudWatch and X-Ray integrations.

## Conclusion

By adjusting our expectations and system requirements, and by utilizing self-hosted services, we have successfully saved $35,000 annually. This journey has been quite a memorable one for our team and me. We've gained invaluable insights and reaped significant benefits from this process.

- My teammates have learned the challenges of maintaining on-premise services, gaining firsthand experience with the complexities involved.
- I have developed skills in training individuals to understand and manage on-premise services on Linux, enhancing our team's overall competency.
- Most importantly, our company has realized substantial cost savings, reducing our annual bill by $37,000.

It’s a win-win-win for us.

Highlights: saving **3130 USD/month** or **37620 USD/year**
