import type { Generated, JSONColumnType } from "kysely";

interface RecordRow {
  id: Generated<string>;
  owner_id: string;
  title: string;
}

export interface Database {
  files: RecordRow & { storage_scope: string };
  "job_runtime.schedules": {
    name: string;
    checked_at: Generated<Date>;
  };
  "job_runtime.heartbeats": {
    id: string;
    mode: "worker" | "timer";
    seen_at: Generated<Date>;
    stopped: boolean;
  };
  records: RecordRow;
  withheld: RecordRow;
  "audit.events": {
    id: Generated<string>;
    table_name: string;
    record_id: string;
    operation: "INSERT" | "UPDATE" | "DELETE";
    actor_id: string | null;
    actor_role: string | null;
    old_row: JSONColumnType<Record<string, unknown> | null>;
    new_row: JSONColumnType<Record<string, unknown> | null>;
    occurred_at: Generated<Date>;
  };
}
