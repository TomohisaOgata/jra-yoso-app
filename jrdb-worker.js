// Cloudflare Worker: configure JRDB_API_KEY, JRDB_AUTH_KEY as secrets.
// Restrict to personal use with Cloudflare Access before deployment.
// Do not put either key into GitHub Pages HTML.
export default {
 async fetch(request,env){
  const url=new URL(request.url);
  if(url.pathname!=="/races")return new Response("Not found",{status:404});
  const date=url.searchParams.get("racedate")||"";
  if(!/^\d{8}$/.test(date))return json({error:"Invalid racedate"},400);
  if(!env.JRDB_API_KEY||!env.JRDB_AUTH_KEY)return json({error:"JRDB credentials not configured"},503);
  try{
   const res=await fetch("https://api.bigtime.world/v1/tra?api_key="+encodeURIComponent(env.JRDB_API_KEY),{
    method:"POST",headers:{"Content-Type":"application/json","x-user-key":env.JRDB_AUTH_KEY},
    body:JSON.stringify({racedate:date})
   });
   if(!res.ok)return json({error:"JRDB request failed: "+res.status},502);
   const data=await res.json();
   if(!Array.isArray(data?.result?.data))return json({error:"Unexpected JRDB response"},502);
   const races=data.result.data.map(r=>({racekey:r.racekey,race_name:r.race_name}));
   return json({races},200);
  }catch(e){return json({error:"Upstream unavailable"},502);}
 }
};
function json(obj,status){return new Response(JSON.stringify(obj),{status,headers:{"Content-Type":"application/json; charset=utf-8","Cache-Control":"no-store"}});}
