export async function setFirstAdminRole(
  saveRole: () => Promise<void>,
  refreshSession: () => Promise<void>,
) {
  await saveRole();
  await refreshSession();
}
