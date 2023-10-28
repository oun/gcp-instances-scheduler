# Kubernetes Engine Node Pool Start Stop Clound Functions

GCP Cloud functions to start and stop Kubernetes Engine node pool.

## Getting Started

Install NodeJS v18.x

```
nvm install --lts=Hydrogen
```

Install dependencies:

```
npm install
```

## Run Functions Locally

Run start instance function:

```
npm run start
```

Run stop instance function:

```
npm run stop
```

## Test Function Locally

Resize all cluster node pools in my-project-id:

```
data=$(echo '{"project": "my-project-id"}' | base64)
curl --location 'http://localhost:8080' \
--header 'ce-id: 123451234512345' \
--header 'ce-specversion: 1.0' \
--header 'ce-time: 2020-01-02T12:34:56.789Z' \
--header 'ce-type: google.cloud.pubsub.topic.v1.messagePublished' \
--header 'ce-source: //pubsub.googleapis.com/projects/MY-PROJECT/topics/MY-TOPIC' \
--header 'Content-Type: application/json' \
--data '{
    "message": {
        "data": "'"$data"'",
        "attributes": {
            "attr1": "attr1-value"
        }
    },
    "subscription": "projects/MY-PROJECT/subscriptions/MY-SUB"
}'
```

## Deployment

Create a pubsub topics:

```
gcloud pubsub topics create start-instance-event
gcloud pubsub topics create stop-instance-event
```

Deploy cloud functions

```
gcloud functions deploy start-gke-node-pools \
--gen2 \
--runtime=nodejs18 \
--region=asia-southeast1 \
--source=. \
--entry-point=startInstances \
--trigger-topic=start-instance-event

gcloud functions deploy stop-gke-node-pools \
--gen2 \
--runtime=nodejs18 \
--region=asia-southeast1 \
--source=. \
--entry-point=stopInstances \
--trigger-topic=stop-instance-event
```

## Trigger Pub/Sub Function

Publish a message to start all regional and zonal cluster node pools in the project my-project-id:

```
gcloud pubsub topics publish start-instance-event \
--message='{"project": "my-project-id"}'
```

Publish a message to stop zonal cluster node pools in asia-southeast1-c zone and my-project-id project:

```
gcloud pubsub topics publish stop-instance-event \
--message='{"project": "my-project-id", "zones": ["asia-southeast1-c"]}'
```

Publish a message to stop cluster node pools with resource label environment=dev in my-project-id project:

```
gcloud pubsub topics publish stop-instance-event \
--message='{"project": "my-project-id", labels: {"environment": "dev"}}'
```

Check function logs to see the result:

```
gcloud functions logs read \
  --gen2 \
  --region=asia-southeast1 \
  --limit=5 \
  start-gke-node-pools
```

## Pub/Sub Message

### Fields

| Field     | Description                        | Default                |
| --------- | ---------------------------------- | ---------------------- |
| `project` | Project containing GKE clusters    | Cloud Function project |
| `zones`   | List of zones                      | All zones              |
| `labels`  | List of node pools resource labels | Empty                  |

### Example Pub/Sub Message

All zonal and regional clusters in the my-project-id project:

```
{
  "project": "my-project-id"
}
```

All zonal clusters in the my-project-id project and asia-southeast1-a, us-west1-b zones:

```
{
  "project": "my-project-id",
  "zones": [
    "asia-southeast1-a",
    "us-west1-b"
  ]
}
```

All cluster node pools with resource label owner=james and environment=dev in the my-project-id project:

```
{
  "project": "my-project-id",
  "labels": {
    "owner": "james"
    "environment": "dev"
  }
}
```