// Pinecrest Outfitters: outbound webhook relay.
// Signs each order event so partners can verify it really came from us.
import { createHmac } from "node:crypto";

export const ping = async () => ({ statusCode: 200, body: "relay alive" });

export const sign = async (event) => {
  const body = JSON.stringify(event.order);
  const signature = createHmac("sha256", process.env.SIGNING_KEY)
    .update(body)
    .digest("hex");

  return {
    statusCode: 202,
    partner: event.partner,
    signature,
    bytes: Buffer.byteLength(body),
  };
};
