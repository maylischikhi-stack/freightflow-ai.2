import {NextResponse} from "next/server";
import {createClient} from "@/lib/supabase/server";

const FIELDS = [
 ["supplier","Fournisseur"],["consignee","Destinataire"],["invoice_number","Numéro de facture"],
 ["currency","Devise"],["total_amount","Montant total"],["gross_weight","Poids brut"],
 ["net_weight","Poids net"],["packages","Nombre de colis"],["container_numbers","Numéro de conteneur"],
 ["bill_of_lading_number","Numéro de connaissement"],["air_waybill_number","Numéro AWB"]
];
function unwrap(v:any):any { if(v&&typeof v==="object"&&!Array.isArray(v)&&"value" in v)return v.value; return v; }
function canonical(v:any):string { const x=unwrap(v); if(x==null||x==="")return ""; if(Array.isArray(x))return x.map(canonical).sort().join("|"); if(typeof x==="object")return JSON.stringify(x); return String(x).trim().toLowerCase().replace(/\s+/g," "); }

export async function POST(req:Request){
 const sb=await createClient();const {data:{user}}=await sb.auth.getUser();
 if(!user)return NextResponse.json({error:"Authentification requise"},{status:401});
 const body=await req.json();const ids=Array.isArray(body.documentIds)?[...new Set(body.documentIds)].slice(0,10):[];
 if(ids.length<2)return NextResponse.json({error:"Sélectionnez au moins deux documents."},{status:400});
 const {data:docs,error}=await sb.from("documents").select("id,file_name,document_type,shipment_id,extracted_data,company_id").eq("user_id",user.id).in("id",ids);
 if(error||!docs||docs.length!==ids.length)return NextResponse.json({error:"Un ou plusieurs documents sont introuvables."},{status:404});
 if(docs.some(d=>!d.extracted_data))return NextResponse.json({error:"Tous les documents doivent avoir été extraits avant comparaison."},{status:409});
 const shipmentIds=[...new Set(docs.map(d=>d.shipment_id ?? "__no_shipment__"))];
 const companyIds=[...new Set(docs.map(d=>d.company_id ?? "__no_company__"))];
 if(shipmentIds.length>1)return NextResponse.json({error:"Les documents doivent appartenir au même dossier d'expédition."},{status:400});
 if(companyIds.length>1)return NextResponse.json({error:"Impossible de comparer des documents de sociétés différentes."},{status:400});
 const anomalies:any[]=[];
 for(const [key,label] of FIELDS){
  const values=docs.map(d=>({doc:d,value:unwrap((d.extracted_data as any)?.[key])})).filter(x=>x.value!==undefined&&x.value!==null&&x.value!=="");
  const distinct=[...new Set(values.map(x=>canonical(x.value)))];
  if(distinct.length>1){
   for(const item of values) anomalies.push({document_id:item.doc.id,user_id:user.id,company_id:item.doc.company_id,field_name:key,severity:["total_amount","currency","container_numbers","bill_of_lading_number","air_waybill_number"].includes(key)?"high":"medium",description:`Divergence détectée pour « ${label} » entre les documents sélectionnés. Valeur trouvée : ${String(item.value)}`});
  }
 }
 if(anomalies.length){
  const {error:insertError}=await sb.from("anomalies").insert(anomalies);
  if(insertError)return NextResponse.json({error:`Comparaison terminée, mais sauvegarde des anomalies impossible : ${insertError.message}`,anomalies},{status:500});
 }
 return NextResponse.json({compared:docs.length,anomalyCount:anomalies.length,anomalies});
}
