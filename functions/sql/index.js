const functions = require("@google-cloud/functions-framework");
const sqladmin = require("@google-cloud/sql");
const clientOptions = {
  fallback: "rest",
};
const instancesClient = new sqladmin.SqlInstancesServiceClient(clientOptions);
const operationsClient = new sqladmin.SqlOperationsServiceClient(clientOptions);

async function waitForOperation(projectId, operation) {
  while (operation.status !== "DONE") {
    await sleep(5000);
    [operation] = await operationsClient.get({
      operation: operation.name,
      project: projectId,
    });
  }
}

functions.cloudEvent("startInstances", async (cloudEvent) => {
  try {
    const payload = await parsePayload(cloudEvent);
    const instances = await listInstances({
      ...payload,
      activationPolicy: "NEVER",
    });

    await Promise.all(
      instances.map(async (instance) => {
        console.log(`Starting instance ${instance.name}`);
        await updateActivationPolicy(instance, "ALWAYS");
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
    const payload = await parsePayload(cloudEvent);
    const instances = await listInstances({
      ...payload,
      activationPolicy: "ALWAYS",
    });

    await Promise.all(
      instances.map(async (instance) => {
        console.log(`Stopping instance ${instance.name}`);
        await updateActivationPolicy(instance, "NEVER");
      })
    );

    const message = `Successfully stopped ${instances.length} instance(s)`;
    console.log(message);
  } catch (err) {
    console.log(err);
  }
});

const updateActivationPolicy = async (instance, activationPolicy) => {
  const [response] = await instancesClient.patch({
    project: instance.project,
    instance: instance.name,
    body: {
      settings: {
        activationPolicy,
      },
    },
  });

  return waitForOperation(instance.project, response);
};

const listInstances = async ({ project, activationPolicy, labels }) => {
  const options = {
    filter: `(settings.activationPolicy = "${activationPolicy}") (state = "RUNNABLE") ${createLabelFilter(
      labels
    )}`,
    project,
  };
  const [{ items: instanceList }] = await instancesClient.list(options);
  console.log(`Found ${instanceList.length} instance(s)`);
  return instanceList;
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
    return "";
  }
  const filters = [];
  for (const [key, value] of Object.entries(labels)) {
    filters.push(`(settings.userLabels.${key} = "${value}")`);
  }
  return filters.join(" ");
};

const sleep = (time) => new Promise((resolve) => setTimeout(resolve, time));
