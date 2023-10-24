const functions = require("@google-cloud/functions-framework");
const container = require("@google-cloud/container");
const clusterClient = new container.ClusterManagerClient();

async function waitForOperation(project, location, operation) {
  while (operation.status !== "DONE") {
    await sleep(5000);
    [operation] = await clusterClient.getOperation({
      name: `projects/${project}/locations/${location}/operations/${operation.name}`,
    });
  }
}

functions.cloudEvent("startInstances", async (cloudEvent) => {
  try {
    const { project, zones } = await parsePayload(cloudEvent);
    const clusters = await listClusters(project, zones);
    await Promise.all(
      clusters.map(async (cluster) => {
        console.log(`Starting cluster ${cluster.name}`);
        await resizeClusterNodePool(project, cluster, 1);
      })
    );

    const message = `Successfully started ${clusters.length} cluster(s)`;
    console.log(message);
  } catch (err) {
    console.log(err);
  }
});

functions.cloudEvent("stopInstances", async (cloudEvent) => {
  try {
    const { project, zones } = await parsePayload(cloudEvent);
    const clusters = await listClusters(project, zones);
    await Promise.all(
      clusters.map(async (cluster) => {
        console.log(`Stopping cluster ${cluster.name}`);
        await resizeClusterNodePool(project, cluster, 0);
      })
    );

    const message = `Successfully stopped ${clusters.length} cluster(s)`;
    console.log(message);
  } catch (err) {
    console.log(err);
  }
});

const resizeClusterNodePool = async (project, cluster, nodePoolSize) => {
  for (nodePool of cluster.nodePools) {
    const name = `projects/${project}/locations/${cluster.location}/clusters/${cluster.name}/nodePools/${nodePool.name}`;
    // TODO: Should restore min and max node count settings when enable autoscaling
    const [autoscalingOperations] = await clusterClient.setNodePoolAutoscaling({
      name,
      autoscaling: {
        enabled: nodePoolSize > 0,
      },
    });
    await waitForOperation(project, cluster.location, autoscalingOperations);
    console.log(`Resizing node pool ${nodePool.name}`);
    const [resizeOperation] = await clusterClient.setNodePoolSize({
      name,
      nodeCount: nodePoolSize,
    });
    await waitForOperation(project, cluster.location, resizeOperation);
  }
};

const listClusters = async (project, zones) => {
  if (!zones || zones.length === 0) {
    const [{ clusters }] = await clusterClient.listClusters({
      parent: `projects/${project}/locations/-`,
    });
    console.log(`Found ${clusters.length} cluster(s) in all zones and regions`);
    return clusters;
  } else {
    let clusters = [];
    for (zone of zones) {
      const [{ clusters: clusterList }] = await clusterClient.listClusters({
        parent: `projects/${project}/locations/${zone}`,
      });
      console.log(`Found ${clusterList.length} cluster(s) in zone ${zone}`);
      clusters = clusters.concat(clusterList);
    }
    return clusters;
  }
};

const parsePayload = async (cloudEvent) => {
  let payload;
  try {
    payload = JSON.parse(
      Buffer.from(cloudEvent.data.message.data, "base64").toString()
    );
  } catch (err) {
    throw new Error("Invalid Pub/Sub message: " + err);
  }
  if (!payload.project) {
    payload.project = await clusterClient.getProjectId();
  }
  return payload;
};

const sleep = (time) => new Promise((resolve) => setTimeout(resolve, time));
