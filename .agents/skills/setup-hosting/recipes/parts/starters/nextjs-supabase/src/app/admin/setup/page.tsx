import { claimFirstAdmin } from "./actions";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";

export default function SetupPage() {
  return (
    <main className="mx-auto max-w-xl px-6 py-16">
      <Card>
        <CardHeader>
          <h1 className="text-2xl font-semibold tracking-tight">Set up the first administrator</h1>
          <p className="text-muted-foreground">Sign in with the invited owner account named in INITIAL_ADMIN_EMAIL.</p>
        </CardHeader>
        <CardContent>
          <form action={claimFirstAdmin} className="space-y-6">
            <Button type="submit">Finish owner setup</Button>
          </form>
        </CardContent>
      </Card>
    </main>
  );
}
