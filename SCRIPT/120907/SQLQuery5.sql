--select * from stocuri s where s.Cod_intrare='' and abs(s.Stoc_initial)+abs(s.Intrari)+abs(s.Iesiri)>=0.001
exec yso_wOPReincadrareIesiri @sesiune='', @parXML='<row dataj="2012-08-01" datas="2012-09-07" cugolire="0"/>'
select * from pozdoc p where p.Tip_miscare='E' and p.Cod_intrare like 'ST%'
select distinct cod_intrare from pozdoc p where p.Tip_miscare='E' and p.Cod_intrare like '%-%'