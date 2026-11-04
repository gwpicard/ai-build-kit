import "server-only";
import { BlobServiceClient, StorageSharedKeyCredential, BlobSASPermissions, SASProtocol,
  generateBlobSASQueryParameters } from "@azure/storage-blob";
import type { StorageConfig } from "../config";
import type { StoragePort, StoredObject } from "../port";

export function azureBlobStorage(config: Extract<StorageConfig, { adapter: "azure-blob" }>): StoragePort {
  const credential = new StorageSharedKeyCredential(config.account, config.accountKey);
  const container = new BlobServiceClient(config.endpoint, credential).getContainerClient(config.container);
  return {
    async save(key, bytes) {
      await container.getBlockBlobClient(key).uploadData(bytes, { blobHTTPHeaders: {
        blobContentType: "application/octet-stream", blobContentDisposition: "attachment", blobCacheControl: "no-store",
      } });
    },
    async fetch(key) { return container.getBlobClient(key).downloadToBuffer(); },
    async temporaryLink(key, seconds) {
      const signature = generateBlobSASQueryParameters({ containerName: config.container, blobName: key,
        version: "2025-11-05", permissions: BlobSASPermissions.parse("r"), expiresOn: new Date(Date.now() + seconds * 1000),
        protocol: config.endpoint.startsWith("https:") ? SASProtocol.Https : SASProtocol.HttpsAndHttp,
        contentDisposition: "attachment", cacheControl: "no-store" }, credential);
      return `${container.getBlobClient(key).url}?${signature}`;
    },
    async delete(key) { await container.getBlobClient(key).deleteIfExists(); },
    async list(prefix) {
      const objects: StoredObject[] = [];
      for await (const page of container.listBlobsFlat({ prefix }).byPage({ maxPageSize: 1000 })) {
        for (const item of page.segment.blobItems) objects.push({ key: item.name, size: item.properties.contentLength ?? 0 });
      }
      return objects;
    },
  };
}
