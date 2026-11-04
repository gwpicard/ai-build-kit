import "server-only";
import { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand, ListObjectsV2Command } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import type { StorageConfig } from "../config";
import type { StoragePort, StoredObject } from "../port";

export function s3Storage(config: Extract<StorageConfig, { adapter: "s3" }>): StoragePort {
  // The SDK credential chain supports environment credentials and workload roles.
  const client = new S3Client({ region: config.region, endpoint: config.endpoint,
    forcePathStyle: config.forcePathStyle });
  const object = (key: string) => ({ Bucket: config.bucket, Key: key });
  return {
    async save(key, bytes) {
      await client.send(new PutObjectCommand({ ...object(key), Body: bytes,
        ContentType: "application/octet-stream", ContentDisposition: "attachment", CacheControl: "no-store" }));
    },
    async fetch(key) {
      const result = await client.send(new GetObjectCommand(object(key)));
      if (!result.Body) throw new Error("File content is unavailable");
      return result.Body.transformToByteArray();
    },
    temporaryLink(key, seconds) {
      return getSignedUrl(client, new GetObjectCommand({ ...object(key),
        ResponseContentDisposition: "attachment", ResponseCacheControl: "no-store" }), { expiresIn: seconds });
    },
    async delete(key) { await client.send(new DeleteObjectCommand(object(key))); },
    async list(prefix) {
      const objects: StoredObject[] = [];
      let token: string | undefined;
      do {
        const page = await client.send(new ListObjectsV2Command({ Bucket: config.bucket, Prefix: prefix,
          ContinuationToken: token }));
        for (const item of page.Contents ?? []) {
          if (item.Key !== undefined) objects.push({ key: item.Key, size: item.Size ?? 0 });
        }
        token = page.IsTruncated ? page.NextContinuationToken : undefined;
        if (page.IsTruncated && !token) throw new Error("Storage listing returned no continuation token");
      } while (token);
      return objects;
    },
  };
}
