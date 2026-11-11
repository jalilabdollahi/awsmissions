// Marlowe Freight: invoice extractor.
// Every new PDF in an invoice bucket is registered in the billing ledger.
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";

const ddb = new DynamoDBClient({});

export const handler = async (event) => {
  const registered = [];
  for (const record of event.Records) {
    const bucket = record.s3.bucket.name;
    const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));
    const docId = `${bucket}/${key}`;
    await ddb.send(new PutItemCommand({
      TableName: "marlowe-invoice-ledger",
      Item: { doc_id: { S: docId }, status: { S: "registered" } },
    }));
    registered.push(docId);
  }
  return { registered };
};
