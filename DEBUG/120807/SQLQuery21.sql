select * from coduri_tbl_debug_tmp


SELECT * from stocuri s where s.Cod like '1807CU3' AND s.Cod_gestiune='700'
select * from pozdoc p where p.Tip='TE' and p.Data='2012-08-07' and p.Numar like 2*10000+1 and p.Cod like '1807CU3'
select * from stocuri s where s.Cod like '1807CU3' 
and s.Cod_intrare in ('AI1001B','IMPL1CD') 
and s.Contract='9820290'

--select * from comenzi c where c.Comanda like '2840121245037'
select * from pozdoc p where p.Tip='te' and p.Factura='9820290' and p.Cod like '1807CU3'
select * from pozcon p where p.Contract='9820290' and p.Cod like '1807CU3'

--select * from pozdoc p where p.Tip='TE' 
--and p.Cod like '1807CU3' and p.Grupa in ('AI1001B','IMPL1CD')
--and p.Gestiune_primitoare='700'

select * from pozdoc p
where p.Cod like '1807CU3'
and p.Comanda <>''
--like '2840121245037'
and p.Gestiune_primitoare='700'