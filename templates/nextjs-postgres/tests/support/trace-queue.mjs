import { PgBoss } from 'pg-boss';

// Observe the real worker's claims over IPC without changing queue behaviour.
const fetch = PgBoss.prototype.fetch;
PgBoss.prototype.fetch = async function (...args) {
  const jobs = await fetch.apply(this, args);
  for (const job of jobs) process.send?.({ event: 'claimed', id: job.id });
  return jobs;
};
