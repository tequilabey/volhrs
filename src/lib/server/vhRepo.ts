//
// src/lib/server/vhRepo.ts
//
import { getPool } from "$lib/server/db";
import sql from "mssql";
import bcrypt from "bcryptjs";
import crypto from "node:crypto";

const TEMP_PASSWORD = "EL20_T3mp";

export type AuthUser = {
  UserId: number;
  LoginName: string;
  FirstName: string;
  LastName: string;
  Roles: string[];
};

export type ProjectPick = { ProjectId: number; Name: string };

export async function projectsGetPublic(): Promise<ProjectPick[]> {
  const pool = await getPool();
  const r = await pool.request().execute("vh.Projects_GetPublic");
  return r.recordset as ProjectPick[];
}
export async function projectsGetForUser(args:{ userId: number; }): Promise<ProjectPick[]> {
  const pool = await getPool();
  const req = pool.request();
  req.input("userId", sql.Int, args.userId);

  const r = await req.execute("vh.Projects_GetForUser");
  return r.recordset as ProjectPick[];
}

export async function timeEntriesInsert(args: {
  userId: number;
  projectId: number;
  entryDate: Date;
  minutes: number;
  notes: string | null;
}) {
  const pool = await getPool();
  const req = pool.request();

  req.input("UserId", sql.Int, args.userId);
  req.input("ProjectId", sql.Int, args.projectId);
  req.input("entryDate", sql.Date, args.entryDate); // or DateTime2
  req.input("Minutes", sql.Int, args.minutes);
  req.input("Notes", sql.NVarChar(4000), args.notes);

  return await req.execute("vh.TimeEntries_Insert");
}

export async function timeEntriesGetByUser(userId: number): Promise<{
  entries: { TimeEntryId: number; EntryDate: string; Minutes: number; Notes: string | null; ProjectName: string }[];
  totalMinutes: number;
}> {
  const pool = await getPool();
  const r = await pool.request()
    .input("UserId", sql.Int, userId)
    .execute("vh.TimeEntries_GetByUser");

  const rows = (r.recordsets?.[0] ?? []) as any[];
  const totals = (r.recordsets?.[1]?.[0] ?? {}) as any;

  const entries = rows.map((e) => ({
    ...e,
    Minutes: Number(e.Minutes ?? 0)
  }));

  return {
    entries,
    totalMinutes: totals.TotalMinutes ?? 0
  };
}

export async function projectsGetSummaryPublic(): Promise<{
  projects: { ProjectId: number; Name: string; TotalMinutes: number | null; LastActivityDate: string | null }[];
  recent: { EntryDate: string; Minutes: number; ProjectName: string }[];
}> {
  const pool = await getPool();
  const r = await pool.request().execute("vh.Projects_GetSummaryPublic");

  return {
    projects: (r.recordsets?.[0] ?? []) as any[],
    recent: (r.recordsets?.[1] ?? []) as any[]
  };
}

export async function projectsGetPublicDetail(projectId: number): Promise<{
  project: { ProjectId: number; Name: string; IsPublic: boolean; TotalMinutes: number | null; LastActivityDate: string | null } | null;
  recent: { EntryDate: string; Minutes: number; Notes: string | null }[];
}> {
  const pool = await getPool();
  const r = await pool.request()

  const project = (r.recordsets?.[0]?.[0] ?? null) as any;
  const recent = (r.recordsets?.[1] ?? []) as any[];

  return { project, recent };
}

/* **************************************
// user functions
*************************************** */
export async function usersCreate(args: {
  loginName: string;
  password: string;
  firstName: string;
  lastName: string;
  mobile?: string | null;
  email?: string | null;
}): Promise<{ userId: number }> {
  const loginName = args.loginName.trim();
  const firstName = args.firstName.trim();
  const lastName = args.lastName.trim();
  const password = args.password;

  // basic app-layer validation (fast feedback)
  if (!loginName) throw new Error("Login name is required.");
  if (!password || password.length < 8) throw new Error("Password must be at least 8 characters.");
  if (!firstName) throw new Error("First name is required.");
  if (!lastName) throw new Error("Last name is required.");

  const passwordHash = await bcrypt.hash(password, 12);

  const pool = await getPool();
  const r = await pool.request()
    .input("LoginName", sql.VarChar(50), loginName)
    .input("PasswordHash", sql.NVarChar(256), passwordHash) // if your column stayed [Password], keep param name but sproc uses PasswordHash
    .input("FirstName", sql.NVarChar(80), firstName)
    .input("LastName", sql.NVarChar(80), lastName)
    .input("Mobile", sql.NVarChar(20), args.mobile ?? null)
    .input("Email", sql.NVarChar(256), args.email ?? null)
    .output("UserId", sql.Int)
    .execute("el20.Users_Create");

  return { userId: Number(r.output.UserId) };
}

/* session stuff */

function sha256Bytes(input: string): Buffer {
  return crypto.createHash("sha256").update(input, "utf8").digest();
}

export async function usersVerifyLogin(args: {
  loginName: string;
  password: string;
}): Promise<AuthUser | null> {
  const loginName = args.loginName.trim();
  const pool = await getPool();

  const r0 = await pool.request().query("SELECT DB_NAME() as Db");
  console.log("Connected to DB:", r0.recordset[0].Db);
  
  const r = await pool.request()
    .input("LoginName", sql.VarChar(50), loginName)
    .execute("el20.Users_GetByLoginName");

  const row = r.recordset?.[0];
  if (!row) return null;

  const ok = await bcrypt.compare(args.password, row.PasswordHash);
  if (!ok) return null;

  const roles = await rolesGetActiveByUserId(row.UserId);

  return {
    UserId: row.UserId,
    LoginName: row.LoginName,
    FirstName: row.FirstName,
    LastName: row.LastName,
    Roles: roles
  };
}

export async function sessionsCreate(args: { userId: number; expiresAtUtc: Date }) {
  const token = crypto.randomBytes(32).toString("base64url"); // cookie value
  const tokenHash = sha256Bytes(token);

  const pool = await getPool();
  await pool.request()
    .input("UserId", sql.Int, args.userId)
    .input("TokenHash", sql.VarBinary(32), tokenHash)
    .input("ExpiresAtUtc", sql.DateTime2, args.expiresAtUtc)
    .execute("el20.Sessions_Create");

  return { token };
}

export async function sessionsGetUserByToken(token: string): Promise<(AuthUser & { sessionId: number }) | null> {
  const tokenHash = sha256Bytes(token);
  const pool = await getPool();

  const r = await pool.request()
    .input("TokenHash", sql.VarBinary(32), tokenHash)
    .execute("el20.Sessions_GetUserByTokenHash");

  const row = r.recordset?.[0];
  if (!row) return null;

  const roles = await rolesGetActiveByUserId(row.UserId);

  return {
    sessionId: row.SessionId,
    UserId: row.UserId,
    LoginName: row.LoginName,
    FirstName: row.FirstName,
    LastName: row.LastName,
    Roles: roles
  };
}

export async function sessionsTouch(args: { sessionId: number; newExpiresAtUtc: Date }) {
  const pool = await getPool();
  await pool.request()
    .input("SessionId", sql.BigInt, args.sessionId)
    .input("NewExpiresAtUtc", sql.DateTime2, args.newExpiresAtUtc)
    .execute("el20.Sessions_Touch");
}

export async function sessionsDelete(token: string) {
  const tokenHash = sha256Bytes(token);
  const pool = await getPool();
  await pool.request()
    .input("TokenHash", sql.VarBinary(32), tokenHash)
    .execute("el20.Sessions_Delete");
}

export async function rolesGetActiveByUserId(userId: number): Promise<string[]> {
  const pool = await getPool();
  const r = await pool.request()
    .input("UserId", sql.Int, userId)
    .execute("el20.Roles_GetActiveByUserId");

  return (r.recordset ?? []).map((x: any) => String(x.RoleCode));
}

/*
Projects maintenance for admins
*/
export type ProjectAdminRow = {
  ProjectId: number;
  Name: string;
  IsPublic: boolean;
};


/* **************************************
// projects maintenance functions
*************************************** */
export async function projectsListAll(): Promise<ProjectAdminRow[]> {
  const pool = await getPool();
  const r = await pool.request().execute("vh.Projects_ListAll");
  return (r.recordset ?? []).map((x: any) => ({
    ProjectId: x.ProjectId,
    Name: x.Name,
    IsPublic: Boolean(x.IsPublic)
  }));
}

export async function projectsUpsert(args: {
  projectId?: number | null;
  name: string;
  isPublic: boolean;
}): Promise<{ projectId: number }> {
  const pool = await getPool();
  const r = await pool.request()
    .input("ProjectId", sql.Int, args.projectId ?? null)
    .input("Name", sql.NVarChar(200), args.name)
    .input("IsPublic", sql.Bit, args.isPublic)
    .execute("vh.Projects_Upsert");

  // sproc returns a single row with ProjectId
  const id = Number(r.recordset?.[0]?.ProjectId);
  return { projectId: id };
}

export async function projectsDelete(projectId: number): Promise<void> {
  const pool = await getPool();
  await pool.request()
    .input("ProjectId", sql.Int, projectId)
    .execute("vh.Projects_Delete");
}

/* **************************************
// user maintenance functions
*************************************** */
export type AdminUserRow = {
  UserId: number;
  LoginName: string;
  FirstName: string;
  LastName: string;
  Email: string | null;
  Mobile: string | null;
  CreatedAt: string;
  Roles: string[];
};

export async function usersListAllAdmin(): Promise<AdminUserRow[]> {
  const pool = await getPool();
  const r = await pool.request().execute("el20.Users_ListAll");

  const users = (r.recordsets?.[0] ?? r.recordset ?? []) as any[];
  const roles = (r.recordsets?.[1] ?? []) as any[];

  const map = new Map<number, AdminUserRow>();
  for (const u of users) {
    map.set(u.UserId, {
      UserId: u.UserId,
      LoginName: u.LoginName,
      FirstName: u.FirstName,
      LastName: u.LastName,
      Email: u.Email ?? null,
      Mobile: u.Mobile ?? null,
      CreatedAt: u.CreatedAt,
      Roles: []
    });
  }

  for (const rr of roles) {
    const row = map.get(rr.UserId);
    if (row) row.Roles.push(String(rr.RoleCode));
  }

  return Array.from(map.values());
}

export async function usersUpsertAdmin(args: {
  userId?: number | null;
  loginName: string;
  firstName: string;
  lastName: string;
  email?: string | null;
  mobile?: string | null;
}): Promise<{ userId: number }> {
  const pool = await getPool();
  const r = await pool.request()
    .input("UserId", sql.Int, args.userId ?? null)
    .input("LoginName", sql.VarChar(50), args.loginName)
    .input("FirstName", sql.NVarChar(80), args.firstName)
    .input("LastName", sql.NVarChar(80), args.lastName)
    .input("Email", sql.NVarChar(256), args.email ?? "")
    .input("Mobile", sql.NVarChar(20), args.mobile ?? "")
    .execute("el20.Users_Upsert");

  const id = Number((r.recordset?.[0]?.UserId ?? r.recordsets?.[0]?.[0]?.UserId));
  return { userId: id };
}

export async function usersSetPasswordAdmin(args: { userId: number; password: string }): Promise<void> {
  if (!args.password || args.password.length < 8) {
    throw new Error("Password must be at least 8 characters.");
  }
  const passwordHash = await bcrypt.hash(args.password, 12);

  const pool = await getPool();
  await pool.request()
    .input("UserId", sql.Int, args.userId)
    .input("PasswordHash", sql.NVarChar(256), passwordHash)
    .execute("el20.Users_SetPasswordHash");
}

export async function rolesGrant(args: { userId: number; roleCode: string }): Promise<void> {
  const pool = await getPool();
  await pool.request()
    .input("UserId", sql.Int, args.userId)
    .input("RoleCode", sql.VarChar(30), args.roleCode)
    .execute("el20.Roles_Grant");
}

export async function rolesRevoke(args: { userId: number; roleCode: string }): Promise<void> {
  const pool = await getPool();
  await pool.request()
    .input("UserId", sql.Int, args.userId)
    .input("RoleCode", sql.VarChar(30), args.roleCode)
    .execute("el20.Roles_Revoke");
}

export async function usersDeleteAdmin(userId: number): Promise<void> {
  const pool = await getPool();
  await pool.request()
    .input("UserId", sql.Int, userId)
    .execute("el20.Users_Delete");
}
