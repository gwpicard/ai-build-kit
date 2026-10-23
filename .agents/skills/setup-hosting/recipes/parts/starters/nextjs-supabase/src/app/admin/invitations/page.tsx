import { invitePerson } from "./actions";
import { requireRole } from "@/lib/supabase/authorize";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default async function InvitationsPage() {
  const access = await requireRole(["admin"]);
  if ("error" in access) {
    return <main className="mx-auto max-w-xl p-8">{access.error}</main>;
  }
  return (
    <main className="mx-auto max-w-xl px-6 py-16">
      <Card>
        <CardHeader>
          <h1 className="text-2xl font-semibold tracking-tight">Invite a team member</h1>
        </CardHeader>
        <CardContent>
          <form action={invitePerson} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="email">Email address</Label>
              <Input id="email" name="email" type="email" autoComplete="email" required />
            </div>
            <Button type="submit">Send invitation</Button>
          </form>
        </CardContent>
      </Card>
    </main>
  );
}
