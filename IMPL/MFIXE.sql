select * from mfixini where Numar_de_inventar like 'TEST01'
select * from mfix where Numar_de_inventar like 'TEST01'
select * from fisamf where Numar_de_inventar like 'TEST01'

select * from tehnpoz where 
isnull((select sum(s.stoc) from dbo.stocuri s where s.subunitate='1' and s.tip_gestiune='C' and s.cod_gestiune='101' and s.cod=tehnpoz.cod and s.stoc>=0.001 and s.contract=''),0)>0