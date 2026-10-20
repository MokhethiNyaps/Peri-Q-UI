-- Historic production-like rows created BEFORE the card-only migration.
insert into public.orders (id,user_id,customer_name,customer_phone,order_type,payment_method,total_price,status,estimated_minutes,delivery_address,client_request_id,payment_proof_path,payment_status,paid_at,payment_amount_cents,yoco_payment_id,yoco_mode,created_at) values
 ('aaaaaaaa-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','Bob','0839876543','pickup','cash_collection',45.00,'completed',20,null,'legacy-cash-01',null,'unpaid',null,null,null,null, now() - interval '40 days'),
 ('aaaaaaaa-0000-0000-0000-000000000002','22222222-2222-2222-2222-222222222222','Bob','0839876543','delivery','eft',120.00,'ready',40,'1 Old Road','legacy-eft-01','22222222-2222-2222-2222-222222222222/aaaaaaaa-0000-0000-0000-000000000002/proof.jpg','unpaid',null,null,null,null, now() - interval '20 days'),
 ('aaaaaaaa-0000-0000-0000-000000000003','11111111-1111-1111-1111-111111111111','Alice','0821234567','pickup','yoco',99.00,'completed',25,null,'legacy-yoco-01',null,'paid', now() - interval '5 days', 9900,'pay_legacy_1','test', now() - interval '5 days');

insert into public.order_items (order_id,menu_item_id,item_name,item_description,item_image_path,item_category,unit_price,quantity,selected_add_ons)
select id,'kota-1','Chicken Kota','Legacy item','assets/images/kota.png','mains',
       case when payment_method='eft' then 90.00 else 45.00 end,
       case when payment_method='eft' then 1 else 1 end,'[]'::jsonb
from public.orders;

insert into public.payments (order_id,yoco_checkout_id,amount_cents,status,yoco_payment_id,mode)
values ('aaaaaaaa-0000-0000-0000-000000000003','co_legacy_1',9900,'succeeded','pay_legacy_1','test');

insert into public.yoco_webhook_events (id,type,payload,yoco_checkout_id,processed,processed_at)
values ('evt_legacy_1','payment.succeeded','{"id":"evt_legacy_1"}'::jsonb,'co_legacy_1',true, now() - interval '5 days');
