--exec RefacereStocuri '700.cj',null,null,null,null,null

select t.Denumire,s.Locatie,* from stocuri s left join terti t on t.Subunitate=s.Subunitate and t.Tert=s.Locatie
where s.Cod_gestiune like '700.cj'

--select * from stocuri s where s.Cod_gestiune like '211.cj' and s.Cod_intrare like 'st%' 
