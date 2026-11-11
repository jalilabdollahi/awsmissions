// Granite Analytics: nightly warehouse exporter.
// Connects to the warehouse database (port 5432) from inside the analytics VPC
// and returns how many rows would be exported.
export const handler = async (event) => {
  const host = process.env.WAREHOUSE_HOST;
  const tables = event.tables ?? [];
  // The real implementation opens a pg connection to host:5432 here.
  return { host, tables: tables.length, rows: tables.reduce((n, t) => n + t.rows, 0) };
};
