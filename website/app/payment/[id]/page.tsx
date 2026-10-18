import PaymentStatus from "./payment-status";
export default async function Page({params}: {params:Promise<{id:string}>}) { const {id}=await params; return <PaymentStatus id={id}/>; }
