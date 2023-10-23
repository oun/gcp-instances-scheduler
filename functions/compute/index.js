const functions = require("@google-cloud/functions-framework");
const compute = require("@google-cloud/compute");
const instancesClient = new compute.InstancesClient();
const operationsClient = new compute.ZoneOperationsClient();

async function waitForOperation(projectId, operation) {
  while (operation.status !== "DONE") {
    [operation] = await operationsClient.wait({
      operation: operation.name,
      project: projectId,
      zone: operation.zone.split("/").pop(),
    });
  }
}

functions.cloudEvent("startInstances", async (cloudEvent) => {
  try {
    const { project, zones, labels } = await parsePayload(cloudEvent);
    const instances = await listInstances(project, zones, labels);

    await Promise.all(
      instances.map(async (instance) => {
        console.log(`Starting instance ${instance.name}`);
        const [response] = await instancesClient.start({
          project,
          zone: instance.zone.split("/").pop(),
          instance: instance.name,
        });

        return waitForOperation(project, response.latestResponse);
      })
    );

    const message = `Successfully started ${instances.length} instance(s)`;
    console.log(message);
  } catch (err) {
    console.log(err);
  }
});

functions.cloudEvent("stopInstances", async (cloudEvent) => {
  try {
    const { project, zones, labels } = await parsePayload(cloudEvent);
    const instances = await listInstances(project, zones, labels);

    await Promise.all(
      instances.map(async (instance) => {
        console.log(`Stopping instance ${instance.name}`);
        const [response] = await instancesClient.stop({
          project,
          zone: instance.zone.split("/").pop(),
          instance: instance.name,
        });

        return waitForOperation(project, response.latestResponse);
      })
    );

    const message = `Successfully stopped ${instances.length} instance(s)`;
    console.log(message);
  } catch (err) {
    console.log(err);
  }
});

const listInstances = async (project, zones, labels) => {
  if (!zones || zones.length === 0) {
    return await listAllInstances(project, labels);
  } else {
    let instances = [];
    for (zone of zones) {
      const options = {
        filter: createLabelFilter(labels),
        project,
        zone,
      };
      const [instanceList] = await instancesClient.list(options);
      console.log(`Found ${instanceList.length} instance(s) in zone ${zone}`);
      instances = instances.concat(instanceList);
    }
    return instances;
  }
};

const listAllInstances = async (project, labels) => {
  let results = [];
  const options = {
    filter: createLabelFilter(labels),
    project,
    maxResults: 25,
  };

  for await (const [
    zone,
    instancesObject,
  ] of await instancesClient.aggregatedListAsync(options)) {
    const instances = instancesObject.instances;
    console.log(`Found ${instances.length} instance(s) in zone ${zone}`);

    if (instances && instances.length > 0) {
      results = results.concat(instances);
    }
  }
  return results;
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
    payload.project = await instancesClient.getProjectId();
  }
  return payload;
};

const createLabelFilter = (labels) => {
  if (!labels || Object.keys(labels).length === 0) {
    return null;
  }
  const filters = [];
  for (const [key, value] of Object.entries(labels)) {
    filters.push(`(labels.${key} = "${value}")`);
  }
  return filters.join(" AND ");
};
