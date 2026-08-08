import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
const DEFAULT_FINISH_URL="https://aliyaseenhasn-hue.github.io/astshara/#/payment-result";
Deno.serve(async(req:Request)=>{
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 try{
  const authHeader=req.headers.get("Authorization"); if(!authHeader) throw new Error("غير مصرح");
  const url=Deno.env.get("SUPABASE_URL")!,serviceRoleKey=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,anonKey=Deno.env.get("SUPABASE_ANON_KEY")!;
  const base=(Deno.env.get("QICARD_API_URL")||Deno.env.get("QICARD_API_BASE_URL")||"https://uat-sandbox-3ds-api.qi.iq/api/v1").replace(/\/$/,"");
  const username=Deno.env.get("QICARD_USERNAME"),password=Deno.env.get("QICARD_PASSWORD"),terminalId=Deno.env.get("QICARD_TERMINAL_ID");
  if(!username||!password||!terminalId) throw new Error("لم يتم إعداد بيانات بوابة كي كارد كاملة");
  const admin=createClient(url,serviceRoleKey),client=createClient(url,anonKey,{global:{headers:{Authorization:authHeader}}});
  const {data:userData,error:authError}=await client.auth.getUser(); if(authError||!userData.user) throw new Error("المستخدم غير مسجل دخول");
  const body=await req.json(),bookingId=body?.booking_id; if(!bookingId) throw new Error("معرّف الحجز مطلوب");
  const {data:booking,error:be}=await admin.from("bookings").select("id,user_id,price,status,lawyer_approved").eq("id",bookingId).maybeSingle(); if(be) throw be; if(!booking||booking.user_id!==userData.user.id) throw new Error("لا تملك صلاحية الدفع لهذا الحجز");
  if(booking.status!=="قيد انتظار الدفع") throw new Error("الحجز غير متاح للدفع في حالته الحالية"); if(booking.price==null||Number(booking.price)<=0) throw new Error("قيمة الحجز غير صالحة للدفع");
  const {data:existing,error:ee}=await admin.from("payments").select("id,qicard_payment_id,status").eq("booking_id",bookingId).order("created_at",{ascending:false}).limit(1); if(ee) throw ee;
  const latest=existing?.[0]; if(latest?.qicard_payment_id&&latest.status==="تم الدفع") throw new Error("تم دفع هذا الحجز مسبقاً");
  const requestId=crypto.randomUUID(),credentials=btoa(`${username}:${password}`),configuredFinish=Deno.env.get("QICARD_FINISH_URL")||DEFAULT_FINISH_URL;
  const finishUrl=`${configuredFinish}${configuredFinish.includes("?")?"&":"?"}booking_id=${encodeURIComponent(bookingId)}&request_id=${encodeURIComponent(requestId)}`;
  const webhookUrl=Deno.env.get("QICARD_WEBHOOK_URL")||`${url}/functions/v1/qicard-webhook`;
  const qiResponse=await fetch(`${base}/payment`,{method:"POST",headers:{"Content-Type":"application/json",Accept:"application/json",Authorization:`Basic ${credentials}`,"X-Terminal-Id":terminalId},body:JSON.stringify({requestId,amount:Number(booking.price),currency:"IQD",locale:"ar_IQ",finishPaymentUrl:finishUrl,notificationUrl:webhookUrl,additionalInfo:{bookingId,requestId},appChannel:false})});
  const raw=await qiResponse.text(); let qiData:any; try{qiData=JSON.parse(raw)}catch{qiData=null;}
  if(!qiResponse.ok||!qiData?.paymentId||!qiData?.formUrl){const d=qiData?.error?.description||qiData?.error?.message||raw.slice(0,300); throw new Error(`بوابة كي كارد: ${d||`HTTP ${qiResponse.status}`}`);}
  const paymentData={amount:booking.price,payment_method:"Qi Card",status:"قيد معالجة الدفع",qicard_payment_id:qiData.paymentId,qicard_request_id:requestId,qicard_raw_status:String(qiData.status||"CREATED").toUpperCase(),qicard_updated_at:new Date().toISOString()};
  if(latest?.id){const {error}=await admin.from("payments").update(paymentData).eq("id",latest.id);if(error)throw error;}else{const {error}=await admin.from("payments").insert({...paymentData,booking_id:bookingId});if(error)throw error;}
  const {error:se}=await admin.from("bookings").update({status:"قيد معالجة الدفع"}).eq("id",bookingId).eq("status","قيد انتظار الدفع");if(se)throw se;
  return new Response(JSON.stringify({paymentId:qiData.paymentId,formUrl:qiData.formUrl,finishUrl}),{headers:{...cors,"Content-Type":"application/json"}});
 }catch(error){return new Response(JSON.stringify({error:error instanceof Error?error.message:"حدث خطأ غير متوقع"}),{status:400,headers:{...cors,"Content-Type":"application/json"}});}
});