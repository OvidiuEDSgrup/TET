select i.Pret as stoc_scriptic,s.stoc as stoc_calculat, ABS(isnull(i.Pret,0)-ISNULL(s.stoc,0)) as dif, n.Denumire,*
-- update inventar set pret=s.stoc
-- insert inventar select s.subunitate,'2012-08-31',s.gestiune,'',s.cod,s.stoc,s.stoc,'asis',getdate(),'' 
 from inventar i 
full outer join dbo.fStocuriCen('2012-08-31'
,null
,null
,null
,1
,1
,0
,null
,null
,null
,null
,null
,null
,null
,null
,null) s on s.subunitate=i.Subunitate and s.gestiune=i.Gestiunea and s.cod=i.Cod_produs
inner join nomencl n on n.Cod=ISNULL(s.cod,i.cod_produs)
where isnull(i.Data_inventarului,'2012-08-31')='2012-08-31' and isnull(i.Pret,0)<>isnull(s.stoc,0)
and (s.gestiune is null or s.gestiune in (select distinct gestiunea 
	from inventar where Data_inventarului='2012-08-31'))
and (i.Gestiunea is null or i.Gestiunea in ('101','211'))
order by ABS(isnull(i.Pret,0)-ISNULL(s.stoc,0)) desc
