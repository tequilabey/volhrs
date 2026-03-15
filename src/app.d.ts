declare global {
  namespace App {
    interface Locals {
      user: import("$lib/server/vhRepo").AuthUser | null;
      sessionToken: string | null;
      sessionId: number | null;
      roles: string[];
    }
  }
}

export {};
