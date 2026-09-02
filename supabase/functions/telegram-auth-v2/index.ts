import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN')!;
const BOT_USERNAME = (Deno.env.get('TELEGRAM_BOT_USERNAME') || 'Astshara_app_bot').replace(/^@/, '');
const WEBHOOK_SECRET = Deno.env.get('TELEGRAM_WEBHOOK_SECRET') || '';
const admin = createClient(SUPABASE_URL, SERVICE_ROLE, { auth: { autoRefreshToken: false, persistSession: false } });
const authClient = createClient(SUPABASE_URL, ANON_KEY, { auth: { autoRefreshToken: false, persistSession: false } });
const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Content-Type': 'application/json; charset=utf-8' };
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: cors });
const normalizeDigits = (value: string) => String(value || '')
  .replace(/[٠-٩]/g, char => String('٠١٢٣٤٥٦٧٨٩'.indexOf(char)))
  .replace(/[۰-۹]/g, char => String('۰۱۲۳۴۵۶۷۸۹'.indexOf(char)));
const normalizePhone = (value: string) => {
  let phone = normalizeDigits(value).trim().replace(/\s+/g, '').replace(/[^0-9+]/g, '');
  if (phone.startsWith('+')) phone = phone.slice(1);
  if (phone.startsWith('00')) phone = phone.slice(2);
  if (phone.startsWith('0')) phone = `964${phone.slice(1)}`;
  if (!phone.startsWith('964')) phone = `964${phone}`;
  return phone;
};
const phoneCandidates = (phone: string) => [phone, `0${phone.slice(3)}`, `+${phone}`];
const normalizeCode = (value: string) => normalizeDigits(value).replace(/\s/g, '');
const sha256 = async (text: string) => { const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text)); return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join(''); };
const randomCode = () => String(Math.floor(100000 + Math.random() * 900000));
const randomPassword = () => crypto.randomUUID() + crypto.randomUUID();
const syntheticEmail = (phone: string) => `telegram.${phone}@login.astshara.app`;

async function telegram(method: string, body: Record<string, unknown>) {
  const response = await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/${method}`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body) });
  const data = await response.json(); if (!data.ok) throw new Error(data.description || `Telegram ${method} failed`); return data.result;
}
async function ensureWebhook() {
  const body: Record<string, unknown> = { url: `${SUPABASE_URL}/functions/v1/telegram-auth-v2?webhook=1`, allowed_updates: ['message'], drop_pending_updates: false };
  if (WEBHOOK_SECRET) body.secret_token = WEBHOOK_SECRET;
  await telegram('setWebhook', body);
}
async function findProfile(phone: string) { const { data, error } = await admin.from('profiles').select('*').in('phone', phoneCandidates(phone)).limit(1).maybeSingle(); if (error) throw new Error(`تعذر التحقق من الرقم: ${error.message}`); return data; }
async function findTelegramProfile(telegramUserId: number) { const { data, error } = await admin.from('profiles').select('*').eq('telegram_user_id', telegramUserId).limit(1).maybeSingle(); if (error) throw new Error(`تعذر التحقق من حساب Telegram: ${error.message}`); return data; }

async function start(phoneRaw: string, mode = 'login', fullName?: string, role?: string) {
  const phone = normalizePhone(phoneRaw);
  if (!/^9647\d{9}$/.test(phone)) throw new Error('رقم الهاتف العراقي غير صحيح');
  const isSignup = mode === 'signup';
  if (isSignup) {
    if (!fullName || fullName.trim().length < 3) throw new Error('الاسم الكامل مطلوب');
    if (role !== 'user' && role !== 'lawyer') throw new Error('نوع الحساب غير صحيح');
    if (await findProfile(phone)) throw new Error('هذا الرقم مرتبط بحساب آخر. يرجى استخدام رقم هاتف آخر أو تسجيل الدخول بالحساب المرتبط به.');
  }
  await ensureWebhook();
  const requestToken = crypto.randomUUID();
  const expires = new Date(Date.now() + 600000).toISOString();
  await admin.from('telegram_login_requests').update({ status: 'expired' }).eq('phone', phone).in('status', ['waiting', 'code_sent']);
  const { error } = await admin.from('telegram_login_requests').insert({ request_token: requestToken, phone, status: 'waiting', attempts: 0, expires_at: expires, mode: isSignup ? 'signup' : 'login', full_name: isSignup ? fullName.trim() : null, role: isSignup ? role : null });
  if (error) throw new Error(`تعذر إنشاء طلب Telegram: ${error.message}`);
  return { ok: true, request_token: requestToken, telegram_url: `https://t.me/${BOT_USERNAME}?start=${requestToken}` };
}

async function webhook(req: Request) {
  if (WEBHOOK_SECRET && req.headers.get('x-telegram-bot-api-secret-token') !== WEBHOOK_SECRET) return json({ ok: false }, 401);
  const update = await req.json(); const message = update?.message; if (!message?.chat?.id) return json({ ok: true });
  const chatId = Number(message.chat.id); const text = String(message.text || '').trim(); const arg = text.match(/^\/start(?:\s+(.+))?$/i)?.[1]?.trim();
  if (!arg) { await telegram('sendMessage', { chat_id: chatId, text: 'مرحباً بك في بوت استشارة ⚖️\nاضغط «بدء» من رابط التسجيل في التطبيق، ثم أرسل /start.' }); return json({ ok: true }); }
  const { data: request, error } = await admin.from('telegram_login_requests').select('*').eq('request_token', arg).maybeSingle();
  if (error || !request || new Date(request.expires_at).getTime() <= Date.now() || request.status === 'expired') { await telegram('sendMessage', { chat_id: chatId, text: 'انتهت صلاحية طلب التسجيل. ارجع إلى تطبيق استشارة واطلب رمزاً جديداً.' }); return json({ ok: true }); }
  const code = randomCode(); const hash = await sha256(`${code}:${arg}`);
  const { error: updateError } = await admin.from('telegram_login_requests').update({ telegram_user_id: chatId, telegram_username: message.from?.username ?? null, telegram_first_name: message.from?.first_name ?? null, telegram_last_name: message.from?.last_name ?? null, code_hash: hash, status: 'code_sent', attempts: 0 }).eq('id', request.id);
  if (updateError) throw new Error(updateError.message);
  await telegram('sendMessage', { chat_id: chatId, text: `رمز التحقق الخاص بك في استشارة: ${code}\n\nالرمز صالح لمدة 10 دقائق. لا تشاركه مع أي شخص.` });
  return json({ ok: true });
}

async function verify(requestToken: string, rawCode: string) {
  const code = normalizeCode(rawCode); if (!/^\d{6}$/.test(code)) throw new Error('رمز التحقق يجب أن يتكون من 6 أرقام');
  const { data: request, error } = await admin.from('telegram_login_requests').select('*').eq('request_token', requestToken).maybeSingle();
  if (error) throw new Error(error.message); if (!request) throw new Error('طلب التحقق غير موجود'); if (!request.telegram_user_id || request.status !== 'code_sent') throw new Error('لم تصل إشارة Telegram بعد. افتح Telegram واضغط «بدء» من رابط استشارة، ثم انتظر وصول الرمز.');
  if (new Date(request.expires_at).getTime() <= Date.now()) { await admin.from('telegram_login_requests').update({ status: 'expired' }).eq('id', request.id); throw new Error('انتهت صلاحية رمز التحقق. اطلب رمزاً جديداً'); }
  if ((request.attempts ?? 0) >= 5) throw new Error('تم تجاوز عدد المحاولات المسموح بها. اطلب رمزاً جديداً');
  const expected = await sha256(`${code}:${requestToken}`);
  if (expected !== request.code_hash) { await admin.from('telegram_login_requests').update({ attempts: (request.attempts ?? 0) + 1 }).eq('id', request.id); throw new Error('رمز التحقق غير صحيح'); }
  const phone = request.phone; const mode = request.mode || 'login'; const profile = await findProfile(phone); const telegramProfile = await findTelegramProfile(Number(request.telegram_user_id));
  if (telegramProfile && (!profile || telegramProfile.id !== profile.id)) throw new Error(mode === 'signup' ? 'حساب Telegram هذا مرتبط بحساب موجود مسبقاً. يرجى تسجيل الدخول بالحساب المرتبط به.' : 'حساب Telegram هذا مرتبط بحساب آخر. يرجى استخدام الحساب المرتبط به.');
  if (mode === 'signup' && profile) throw new Error('هذا الرقم مرتبط بحساب آخر. يرجى استخدام رقم هاتف آخر أو تسجيل الدخول بالحساب المرتبط به.');
  let authUser: any; const email = syntheticEmail(phone); const password = randomPassword();
  if (profile?.auth_id) {
    const { data, error: userError } = await admin.auth.admin.getUserById(profile.auth_id); if (userError) throw new Error(`تعذر استرجاع الحساب: ${userError.message}`); authUser = data.user;
    const patch: any = { password, user_metadata: { ...(authUser.user_metadata || {}), full_name: profile.full_name, role: profile.role } }; if (!authUser.email) { patch.email = email; patch.email_confirm = true; }
    const { error: updateUserError } = await admin.auth.admin.updateUserById(authUser.id, patch); if (updateUserError) throw new Error(`تعذر تجهيز حساب الدخول: ${updateUserError.message}`);
    const { error: profileError } = await admin.from('profiles').update({ telegram_user_id: request.telegram_user_id, updated_at: new Date().toISOString() }).eq('id', profile.id);
    if (profileError) { if (profileError.code === '23505') throw new Error('حساب Telegram هذا مرتبط بحساب موجود مسبقاً. يرجى تسجيل الدخول بالحساب المرتبط به.'); throw new Error(`تعذر ربط Telegram: ${profileError.message}`); }
  } else if (mode === 'signup') {
    const role = request.role === 'lawyer' ? 'lawyer' : 'user'; const fullName = String(request.full_name || '').trim(); if (fullName.length < 3) throw new Error('الاسم الكامل مطلوب');
    const { data: created, error: createError } = await admin.auth.admin.createUser({ email, password, email_confirm: true, phone: `+${phone}`, phone_confirm: true, user_metadata: { full_name: fullName, role } });
    if (createError) { const duplicate = /already|exists|registered|duplicate/i.test(createError.message); if (duplicate) throw new Error('هذا الرقم مرتبط بحساب آخر. يرجى استخدام رقم هاتف آخر أو تسجيل الدخول بالحساب المرتبط به.'); throw new Error(`تعذر إنشاء الحساب: ${createError.message}`); }
    authUser = created.user;
    const { error: insertError } = await admin.from('profiles').insert({ auth_id: authUser.id, phone, email, full_name: fullName, role, telegram_user_id: request.telegram_user_id });
    if (insertError) { await admin.auth.admin.deleteUser(authUser.id); if (insertError.code === '23505') throw new Error('حساب Telegram هذا مرتبط بحساب موجود مسبقاً. يرجى تسجيل الدخول بالحساب المرتبط به.'); throw new Error(`تعذر إنشاء ملف المستخدم: ${insertError.message}`); }
  } else if (profile) { throw new Error('تعذر ربط حساب Telegram بالحساب الموجود. يرجى التواصل مع الدعم.'); }
  else { throw new Error('لم يتم العثور على حساب مرتبط بهذا الرقم. يرجى إنشاء حساب أولاً.'); }
  const { data: login, error: loginError } = await authClient.auth.signInWithPassword({ email, password });
  if (loginError || !login.session) throw new Error(`تعذر إنشاء جلسة الدخول: ${loginError?.message || 'الجلسة غير متاحة'}`);
  await admin.from('telegram_login_requests').update({ status: 'verified', verified_at: new Date().toISOString() }).eq('id', request.id);
  return { ok: true, access_token: login.session.access_token, refresh_token: login.session.refresh_token, userId: authUser.id };
}

Deno.serve(async (req) => {
  try {
    if (req.method === 'OPTIONS') return new Response('ok', { status: 200, headers: cors });
    const url = new URL(req.url); if (url.searchParams.get('webhook') === '1') return await webhook(req); if (req.method !== 'POST') return json({ ok: false, error: 'Method not allowed' }, 405);
    const body = await req.json(); if (body.action === 'start') return json(await start(body.phone, body.mode || 'login', body.full_name, body.role)); if (body.action === 'verify') return json(await verify(body.request_token, body.code)); return json({ ok: false, error: 'إجراء غير معروف' }, 400);
  } catch (error) {
    console.error(error); const message = error instanceof Error ? error.message : String(error); const status = /مرتبط بحساب|مرتبط بحساب آخر|غير صحيح|غير موجود|انتهت|تجاوز|يجب أن|افتح Telegram|مطلوب|نوع الحساب|استخدام الحساب المرتبط/.test(message) ? 400 : 500; return json({ ok: false, error: message }, status);
  }
});
