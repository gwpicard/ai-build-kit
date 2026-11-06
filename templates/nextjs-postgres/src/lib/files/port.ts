export interface StoredObject {
  key: string;
  size: number;
}

// Internal adapter contract. App callers use the permission-checked port in index.ts.
export interface StoragePort {
  save(key: string, bytes: Uint8Array): Promise<void>;
  fetch(key: string): Promise<Uint8Array>;
  temporaryLink(key: string, seconds: number): Promise<string>;
  delete(key: string): Promise<void>;
  list(prefix: string): Promise<StoredObject[]>;
}
