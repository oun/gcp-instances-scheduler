const functions = require("@google-cloud/functions-framework");
const container = require("@google-cloud/container");
const clusterClient = new container.ClusterManagerClient();

const SHUTDOWN_TAINT_KEY = process.env.SHUTDOWN_TAINT_KEY ?? "scheduled-shutdown";
const SHUTDOWN_TAINT_VALUE = process.env.SHUTDOWN_TAINT_VALUE ?? "true";

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
    const { project, zones, labels } = await parsePayload(cloudEvent);
    const clusters = await listClusters(project, zones, labels);
    await Promise.all(
      clusters.map(async (cluster) => {
        console.log(`Starting cluster ${cluster.name}`);
        await removeShutdownNodePoolTaint(project, cluster);
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
    const { project, zones, labels } = await parsePayload(cloudEvent);
    const clusters = await listClusters(project, zones, labels);
    await Promise.all(
      clusters.map(async (cluster) => {
        console.log(`Stopping cluster ${cluster.name}`);
        await appendShutdownNodePoolTaint(project, cluster);
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
    console.log(`Resizing node pool ${cluster.name}/${nodePool.name}`);
    const [operation] = await clusterClient.setNodePoolSize({
      name,
      nodeCount: nodePoolSize,
    });
    await waitForOperation(project, cluster.location, operation);
  }
};

const appendShutdownNodePoolTaint = async (project, cluster) => {
  for (nodePool of cluster.nodePools) {
    const shutdownTaint = {
      key: SHUTDOWN_TAINT_KEY,
      value: SHUTDOWN_TAINT_VALUE,
      effect: "NO_EXECUTE",
    };
    const taints = [...nodePool.config.taints, shutdownTaint];
    console.log(
      `Appending shutdown node pool taint ${cluster.name}/${nodePool.name}`
    );
    await updateClusterNodePoolTaints(project, cluster, nodePool, taints);
  }
};

const removeShutdownNodePoolTaint = async (project, cluster) => {
  for (nodePool of cluster.nodePools) {
    const taints = nodePool.config.taints.filter(
      (taint) => taint.key !== SHUTDOWN_TAINT_KEY
    );
    console.log(
      `Removing shutdown node pool taint ${cluster.name}/${nodePool.name}`
    );
    await updateClusterNodePoolTaints(project, cluster, nodePool, taints);
  }
};

const updateClusterNodePoolTaints = async (
  project,
  cluster,
  nodePool,
  taints
) => {
  const name = `projects/${project}/locations/${cluster.location}/clusters/${cluster.name}/nodePools/${nodePool.name}`;
  const [operation] = await clusterClient.updateNodePool({
    name,
    taints: {
      taints,
    },
  });
  await waitForOperation(project, cluster.location, operation);
};

const listClusters = async (project, zones, labels) => {
  if (!zones || zones.length === 0) {
    let [{ clusters }] = await clusterClient.listClusters({
      parent: `projects/${project}/locations/-`,
    });
    clusters = filterLabels(clusters, labels);
    console.log(`Found ${clusters.length} cluster(s) in all zones and regions`);
    return clusters;
  } else {
    let clusters = [];
    for (zone of zones) {
      let [{ clusters: clusterList }] = await clusterClient.listClusters({
        parent: `projects/${project}/locations/${zone}`,
      });
      clusterList = filterLabels(clusterList, labels);
      console.log(`Found ${clusterList.length} cluster(s) in zone ${zone}`);
      clusters = clusters.concat(clusterList);
    }
    return clusters;
  }
};

const filterLabels = (clusters, labels) => {
  if (!labels || labels.length === 0) {
    return clusters;
  }
  return clusters
    .map((cluster) => ({
      ...cluster,
      nodePools: cluster.nodePools.filter((nodePool) =>
        containsLabels(nodePool, labels)
      ),
    }))
    .filter((cluster) => cluster.nodePools.length > 0);
};

const containsLabels = (nodePool, labels) => {
  const nodePoolLabels = nodePool.config.resourceLabels;
  for (labelKey of Object.keys(labels)) {
    if (
      !(
        labelKey in nodePoolLabels &&
        nodePoolLabels[labelKey] === labels[labelKey]
      )
    ) {
      return false;
    }
  }
  return true;
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
