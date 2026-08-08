import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", {headers: cors});
  try {
    const authHeader=req.headers.get("Authorization"); if(!authHeader) throw new Error("غير مصرح");
    const url=Deno.env.get("SUPABASE_URL")!; const serviceRoleKey=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!; const anonKey=Deno.env.get("SUPABASE_ANON_KEY")!;
    const base=(Deno.env.get("QICARD_API_URL")||Deno.env.get("QICARD_API_BASE_URL")||"https://uat-sandbox-3ds-api.qi.iq/api/v1").replace(/\/$/,"");
    const username=Deno.env.get("QICARD_USERNAME"), password=Deno.env.get("QICARD_PASSWORD"), terminalId=Deno.env.get("QICARD_TERMINAL_ID");
    if(!username||!password||!terminalId) throw new Error("بيانات بوابة كي كارد غير مكتملة");
    const client=createClient(url,anonKey,{global:{headers:{Authorization:authHeader}}}); const {data:userData}=await client.auth.getUser(); const user=userData.user; if(!user) throw new Error("المستخدم غير مسجل دخول");
    const body=await req.json(); const bookingId=body?.booking_id; if(!bookingId) throw new Error("معرّف الحجز مطلوب");
    const admin=createClient(url,serviceRoleKey);
    const {data:booking,error:bookingError}=await admin.from("bookings").select("id,user_id,price,status").eq("id",bookingId).maybeSingle(); if(bookingError) throw bookingError; if(!booking||booking.user_id!==user.id) throw new Error("لا تملك صلاحية هذا الحجز");
    const {data:payment,error:paymentError}=await admin.from("payments").select("id,booking_id,qicard_payment_id").eq("booking_id",bookingId).maybeSingle(); if(paymentError) throw paymentError; if(!payment?.qicard_payment_id) throw new Error("لا توجد عملية كي كارد مرتبطة بهذا الحجز");
    const response=await fetch(`${base}/payment/${payment.qicard_payment_id}/status`,{headers:{Authorization:`Basic ${btoa(`${username}:${password}`)}`,"X-Terminal-Id":terminalId}});
    const qiData=await response.json().catch(()=>null); if(!response.ok||!qiData){const d=qiData?.error?.description||qiData?.error?.message; throw new Error(d?`بوابة كي كارد: ${d}`:`تعذر التحقق من الدفع (HTTP ${response.status})`);}
    if(Number(qiData.amount)!==Number(booking.price)||qiData.currency!=="IQD") throw new Error("بيانات الدفع لا تطابق قيمة الحجز");
    const raw=String(qiData.status||"").toUpperCase(), success=raw==="SUCCESS", failed=raw==="FAILED"||raw==="AUTHENTICATION_FAILED", mapped=success?"تم الدفع":failed?"فشل الدفع":"قيد معالجة الدفع", now=new Date().toISOString();
    const {error:ue}=await admin.from("payments").update({status:mapped,qicard_raw_status:raw,qicard_payment_type:qiData.paymentType??null,qicard_payment_system:qiData.details?.paymentSystem??null,qicard_rrn:qiData.details?.rrn??null,qicard_auth_id:qiData.details?.authId??null,qicard_updated_at:now,verified_at:success?now:null,verified_by:null}).eq("id",payment.id); if(ue) throw ue;
    if(success){const {error}=await admin.from("bookings").update({status:"مؤكد"}).eq("id",booking.id); if(error) throw error;}
    else if(failed){const {error}=await admin.from("bookings").update({status:"قيد انتظار الدفع"}).eq("id",booking.id); if(error) throw error;}
    return new Response(JSON.stringify({payment_status:mapped,qicard_status:raw,booking_status:success?"مؤكد":failed?"قيد انتظار الدفع":booking.status}),{status:200,headers:{...cors,"Content-Type":"application/json"}});
  } catch(error){return new Response(JSON.stringify({error:error instanceof Error?error.message:"حدث خطأ غير متوقع"}),{status:400,headers:{...cors,"Content-Type":"application/json"}});}
});