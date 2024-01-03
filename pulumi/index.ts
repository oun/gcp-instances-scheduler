import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as random from "@pulumi/random";

const config = new pulumi.Config();
const gcpConfig = new pulumi.Config("gcp");

const region = gcpConfig.require("region");
const scheduledProject = config.require("scheduledProject");
const startJobSchedule = config.get("startJobSchedule") || "0 8 * * 1-5";
const stopJobSchedule = config.get("stopJobSchedule") || "0 20 * * 1-5";
const timeZone = config.get("timeZone") || "Etc/UTC";
const defaultMessage = `{"project": "${scheduledProject}"}`;
const startMessage = config.get("startMessage") || defaultMessage;
const stopMessage = config.get("stopMessage") || defaultMessage;
const shutdownTaintKey = config.get("shutdownTaintKey") || "scheduled-shutdown";
const shutdownTaintValue = config.get("shutdownTaintValue") || "true";

const startTopic = new gcp.pubsub.Topic("start-topic", {
  name: "start-instance-event",
});

const stopTopic = new gcp.pubsub.Topic("stop-topic", {
  name: "stop-instance-event",
});

const startJob = new gcp.cloudscheduler.Job("start-job", {
  name: "start-instances",
  schedule: startJobSchedule,
  timeZone: timeZone,
  pubsubTarget: {
    topicName: startTopic.id,
    data: btoa(startMessage),
  },
});

const stopJob = new gcp.cloudscheduler.Job("stop-job", {
  name: "stop-instances",
  schedule: stopJobSchedule,
  timeZone: timeZone,
  pubsubTarget: {
    topicName: stopTopic.id,
    data: btoa(stopMessage),
  },
});

const bucketPrefix = new random.RandomId("bucket-prefix", {
  byteLength: 8,
});

const bucket = new gcp.storage.Bucket("bucket", {
  name: pulumi.interpolate `gcf-source-${bucketPrefix.hex}`,
  location: region,
  uniformBucketLevelAccess: true,
});

const serviceAccountConfigs = [
  {
    accountId: "start-stop-gce-function",
    displayName: "Cloud Function Service Account",
    roles: ["roles/compute.instanceAdmin.v1"],
  },
  {
    accountId: "start-stop-sql-function",
    displayName: "Cloud Function Service Account",
    roles: ["roles/cloudsql.editor"],
  },
  {
    accountId: "start-stop-gke-function",
    displayName: "Cloud Function Service Account",
    roles: ["roles/container.clusterAdmin"],
  },
];

const serviceAccounts: { [key: string]: gcp.serviceaccount.Account } = {};

for (const { accountId, displayName, roles } of serviceAccountConfigs) {
  const serviceAccount = new gcp.serviceaccount.Account(`${accountId}-sa`, {
    accountId,
    displayName,
  });
  roles.forEach((role, index) => {
    new gcp.projects.IAMMember(`${accountId}-role-${index}`, {
      member: serviceAccount.member,
      project: scheduledProject,
      role,
    });
  });
  serviceAccounts[accountId] = serviceAccount;
}

const functionConfigs: Array<{
  name: string;
  description: string;
  entryPoint: string;
  sourceDir: string;
  pubsubTopic: pulumi.Input<string>;
  serviceAccountId: string;
  environmentVariables?: { [key: string]: string };
}> = [
  {
    name: "start-gce-instances",
    description: "Function for starting Compute Engine instances",
    entryPoint: "startInstances",
    sourceDir: "../functions/gce",
    pubsubTopic: startTopic.id,
    serviceAccountId: "start-stop-gce-function",
  },
  {
    name: "stop-gce-instances",
    description: "Function for stopping Compute Engine instances",
    entryPoint: "stopInstances",
    sourceDir: "../functions/gce",
    pubsubTopic: stopTopic.id,
    serviceAccountId: "start-stop-gce-function",
  },
  {
    name: "start-sql-instances",
    description: "Function for starting Cloud SQL instances",
    entryPoint: "startInstances",
    sourceDir: "../functions/sql",
    pubsubTopic: startTopic.id,
    serviceAccountId: "start-stop-sql-function",
  },
  {
    name: "stop-sql-instances",
    description: "Function for stopping Cloud SQL instances",
    entryPoint: "stopInstances",
    sourceDir: "../functions/sql",
    pubsubTopic: stopTopic.id,
    serviceAccountId: "start-stop-sql-function",
  },
  {
    name: "start-gke-node-pools",
    description: "Function for starting GKE node pools",
    entryPoint: "startInstances",
    sourceDir: "../functions/gke",
    pubsubTopic: startTopic.id,
    serviceAccountId: "start-stop-gke-function",
    environmentVariables: {
      SHUTDOWN_TAINT_KEY: shutdownTaintKey,
      SHUTDOWN_TAINT_VALUE: shutdownTaintValue,
    },
  },
  {
    name: "stop-gke-node-pools",
    description: "Function for stopping GKE node pools",
    entryPoint: "stopInstances",
    sourceDir: "../functions/gke",
    pubsubTopic: stopTopic.id,
    serviceAccountId: "start-stop-gke-function",
    environmentVariables: {
      SHUTDOWN_TAINT_KEY: shutdownTaintKey,
      SHUTDOWN_TAINT_VALUE: shutdownTaintValue,
    },
  },
];

for (const {
  name,
  description,
  entryPoint,
  sourceDir,
  pubsubTopic,
  serviceAccountId,
  environmentVariables,
} of functionConfigs) {
  const object = new gcp.storage.BucketObject(`${name}-function-source`, {
    name: `${name}/function-source.zip`,
    bucket: bucket.name,
    source: new pulumi.asset.FileArchive(sourceDir),
  });

  const func = new gcp.cloudfunctionsv2.Function(`${name}-function`, {
    name,
    location: region,
    description,
    buildConfig: {
      runtime: "nodejs18",
      entryPoint,
      source: {
        storageSource: {
          bucket: bucket.name,
          object: object.name,
        },
      },
    },
    serviceConfig: {
      minInstanceCount: 0,
      maxInstanceCount: 3,
      availableMemory: "256M",
      timeoutSeconds: 540,
      environmentVariables,
      ingressSettings: "ALLOW_INTERNAL_ONLY",
      allTrafficOnLatestRevision: true,
      serviceAccountEmail: serviceAccounts[serviceAccountId].email,
    },
    eventTrigger: {
      pubsubTopic,
      eventType: "google.cloud.pubsub.topic.v1.messagePublished",
      triggerRegion: region,
      retryPolicy: "RETRY_POLICY_DO_NOT_RETRY",
    },
  });
}
