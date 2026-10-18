"use client";
import {useEffect,useState} from "react";
import Link from "next/link";
import {createBrowserClient} from "@/lib/supabase";
import {useCart} from "@/lib/cart";
export default function PaymentStatus({id}:{id:string}) {
 const [message,setMessage]=useState("Checking payment with the restaurant…"); const {clear}=useCart();
 useEffect(()=>{let stopped=false; const check=async()=>{
  const query=new URLSearchParams(location.search); const outcome=query.get("checkout");
  if(query.get("source")==="mobile"){setMessage("Return to the Rasta’s Peri Q app to check your payment. Your order appears there after Yoco confirms it. If you cancelled or payment failed, your app cart stays saved.");return;}
  const {data,error}=await createBrowserClient().from("checkout_intents").select("payment_status").eq("id",id).maybeSingle();
  if(stopped)return;
  if(data?.payment_status==="paid"){clear(); location.replace(`/order/${id}/?new=1`);return;}
  setMessage(error?"Could not check payment. Please check again shortly; your cart is saved.":data?.payment_status==="failed"||outcome==="failure"?"Payment failed. No order was placed. Your cart is saved.":outcome==="cancel"?"Payment cancelled. No order has been placed. Your cart is saved.":"Waiting for Yoco confirmation. You can safely close this page; a successful payment will still create your order.");
 }; void check();const timer=setInterval(()=>void check(),3000);return()=>{stopped=true;clearInterval(timer);};},[id,clear]);
 return <main className="site-shell py-20"><h1 className="text-3xl font-black">Your card payment</h1><p role="status" className="my-6">{message}</p><Link href="/checkout/">Return to checkout</Link></main>;
}
