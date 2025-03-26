const { CloudWatchLogsClient, CreateExportTaskCommand } = require('@aws-sdk/client-cloudwatch-logs');

const client = new CloudWatchLogsClient({ region: 'eu-central-1' });

exports.handler = async (event) => {
  const logGroups = ['/ecs/app-task', '/ecs/jenkins-task', '/ecs/jenkins-task']; // Jenkins logs include pipeline
  const bucket = process.env.BUCKET_NAME;
  const now = new Date();
  const fromTime = new Date(now.getTime() - 48 * 60 * 60 * 1000);

  for (const logGroup of logGroups) {
    const prefix = logGroup === '/ecs/jenkins-task' ? 'pipeline' : 'ecs'; // Pipeline logs to pipeline/
    const params = {
      destination: bucket,
      logGroupName: logGroup,
      from: Math.floor(fromTime.getTime()),
      to: Math.floor(now.getTime()),
      destinationPrefix: `${prefix}/${logGroup.split('/').pop()}`
    };

    try {
      const command = new CreateExportTaskCommand(params);
      await client.send(command);
      console.log(`Export task created for ${logGroup}`);
    } catch (err) {
      console.error(`Error exporting ${logGroup}:`, err);
    }
  }

  return { statusCode: 200, body: 'Export tasks triggered' };
};