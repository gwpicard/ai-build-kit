export function localDatabaseUrls(): { admin: string; owner: string; app: string; auth: string };
export function reportFailure(error: { code?: string }): void;
