select cantitate*(case when 0=1 then 0 when 0=1 then ((case when 0=0 and not (0=1 and a.tip_gestiune='A') then b.pret 
else b.pret_cu_amanuntul end) 
/ isnull((select top 1 curs.curs from curs where curs.valuta='   ' and curs.data <= b.data order by curs.data DESC), 1)) 
	when 0=0 and not (0=1 and a.tip_gestiune='A') then a.pret else a.pret_cu_amanuntul end)
	from tempdb..balst77121 a 
left outer join nomencl n on a.cod=n.cod 
left outer join stocuri b on a.subunitate=b.subunitate and a.tip_gestiune=b.tip_gestiune and a.gestiune=b.cod_gestiune and a.cod=b.cod and a.cod_intrare=b.cod_intrare 
where isnull(n.grupa,'') like rtrim('             ')+'%' and isnull(n.UM,'') like rtrim('   ')+'%' and (0=0 or isnull(right(n.tip_echipament,20),'')='                    ') and (0=0 or a.tip_gestiune in ('F', 'T') or a.gestiune in (select gestiune from gesttmpid where HostId='7712')) 
and (' '='' or ' '='M' and left(a.cont,3) not in ('345','354','371','357') or ' '='P' and left(a.cont,3) in ('345','354') or ' '='A' and left(a.cont,3) in ('371','357')) and (0=0 or isnull(n.loc_de_munca,'')='                                                                                                                                                      ') 
	
select SUM(cantitate*pret) from tempdb..balst77801 l