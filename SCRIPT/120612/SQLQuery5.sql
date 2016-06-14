select * from pozdoc p where not exists 
(select 1 from doc d where d.Subunitate=p.Subunitate and d.Tip=p.Tip and d.Numar=p.Numar and d.Data=p.Data)

select * from yso_syssd s 
--where '118156' in (s.Numar,s.Factura)
order by s.Data_stergerii desc

select * from sysspd s 
where '118156' in (s.Numar,s.Factura)
order by s.Data_stergerii desc

select * from pozdoc s 
where '118156' in (s.Numar,s.Factura)
order by s.Data_operarii desc, s.Ora_operarii desc