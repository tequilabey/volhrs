import { fail } from '@sveltejs/kit';
import { usersVerifyLogin, sessionsCreate } from '$lib/server/vhRepo';

const COOKIE_NAME = 'vh_session';
const DAYS_90 = 90 * 24 * 60 * 60;

export const actions = {
  default: async ({ request, cookies, url }) => {
    console.log('LOGIN action started');

    try {
      const fd = await request.formData();
      const loginName = String(fd.get('loginName') ?? '').trim();
      const password = String(fd.get('password') ?? '');

      console.log('Login attempt:', { loginName });

      if (!loginName || !password) {
        return fail(400, { error: 'Login name and password are required.', values: { loginName } });
      }

      console.log('Calling usersVerifyLogin...');
      const user = await usersVerifyLogin({ loginName, password });
      console.log('usersVerifyLogin result:', user);

      if (!user) {
        return fail(400, { error: 'Invalid login.', values: { loginName } });
      }

      const expiresAtUtc = new Date(Date.now() + DAYS_90 * 1000);

      console.log('Creating session...');
      const { token } = await sessionsCreate({ userId: user.UserId, expiresAtUtc });
      console.log('Session created');

      cookies.set(COOKIE_NAME, token, {
        path: '/',
        httpOnly: true,
        sameSite: 'lax',
        secure: url.protocol === 'https:',
        maxAge: DAYS_90
      });

      console.log('Login success (returning ok:true)');
      return { ok: true };
    } catch (err: any) {
      console.error('LOGIN FAILURE:', err);
      return fail(500, { error: 'Server error during login.' });
    }
  }
};
