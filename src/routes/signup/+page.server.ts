import { fail } from "@sveltejs/kit";
import { usersCreate } from "$lib/server/vhRepo";

function asStr(v: FormDataEntryValue | null) {
  return typeof v === "string" ? v : "";
}

export const actions = {
  default: async ({ request }) => {
    const fd = await request.formData();

    const values = {
      loginName: asStr(fd.get("loginName")),
      firstName: asStr(fd.get("firstName")),
      lastName: asStr(fd.get("lastName")),
      email: asStr(fd.get("email")),
      mobile: asStr(fd.get("mobile"))
      // password intentionally NOT echoed back
    };

    const password = asStr(fd.get("password"));

    try {
      await usersCreate({
        loginName: values.loginName,
        password,
        firstName: values.firstName,
        lastName: values.lastName,
        email: values.email || null,
        mobile: values.mobile || null
      });

      // success: return ok + blank values so the form clears
      return { ok: true, values: { loginName: "", firstName: "", lastName: "", email: "", mobile: "" } };
    } catch (e: any) {
      const msg = String(e?.message ?? "Sign up failed.");
      return fail(400, { error: msg, values });
    }
  }
};
