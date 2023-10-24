# Terraform Start Stop Scheduler Module

## Requirements

### Softwares

The following dependencies must be available:

- Terraform >= 0.13.0
- Terraform Google Provider >= 4.34.0

### IAM Roles

A service account with the following roles must be used to provision the resources of this module:

- Storage Admin: `roles/storage.admin`
- PubSub Editor: `roles/pubsub.editor`
- Cloudscheduler Admin: `roles/cloudscheduler.admin`
- Cloudfunctions Developer: `roles/cloudfunctions.developer`

### Enable APIs

A project with the following APIs enabled must be used to host the resources of this module:

- Cloud Scheduler API - `cloudscheduler.googleapis.com`
- Cloud Function API - `cloudfunctions.googleapis.com`
- Eventarc API - `eventarc.googleapis.com`
- Cloud Run API - `run.googleapis.com`
- Cloud Build API - `cloudbuild.googleapis.com`
- Cloud SQL Admin API - `sqladmin.googleapis.com`
- Kubernetes Engine API - `container.googleapis.com`
