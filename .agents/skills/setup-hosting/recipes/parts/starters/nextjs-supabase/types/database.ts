export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      roles: {
        Row: { user_id: string; role: "admin" | "member"; created_at: string };
        Insert: { user_id: string; role?: "admin" | "member"; created_at?: string };
        Update: { user_id?: string; role?: "admin" | "member"; created_at?: string };
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: { access_token_hook: { Args: { event: Json }; Returns: Json } };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
