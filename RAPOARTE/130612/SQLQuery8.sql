;with 
predari as
	(select p.Subunitate, p.Tip, p.Cod, p.Gestiune, p.Cod_intrare
		,cant_predare=SUM(p.Cantitate)
		,val_predare=SUM(p.Cantitate*p.Pret_de_stoc)	
	from pozdoc p where p.Subunitate='1' and p.Tip='PP'
	group by p.Subunitate, p.Tip, p.Cod, p.Gestiune, p.Cod_intrare)
,consumuri as
	(select p.Subunitate, p.Tip, p.Cod, p.Gestiune, p.Cod_intrare
		,cant_consum=SUM(p.Cantitate)
		,val_consum=SUM(p.Cantitate*p.Pret_de_stoc)	
	from pozdoc p where p.Subunitate='1' and p.Tip='CM'
	group by p.Subunitate, p.Tip, p.Cod, p.Gestiune, p.Cod_intrare)
,transferuri as
	(select p.Subunitate, p.Tip, p.Cod
		,Gestiune=(case when p.Cantitate>=0.001 then p.Gestiune else p.Gestiune_primitoare end)
		,Cod_intrare=(case when p.Cantitate>=0.001 then p.Cod_intrare else p.Grupa end)
		,Gestiune_primitoare=(case when p.Cantitate>=0.001 then p.Gestiune_primitoare else p.Gestiune end)
		,Cod_intrare_primitor=(case when p.Cantitate>=0.001 then p.Grupa else p.Cod_intrare end)
	from pozdoc p where p.Subunitate='1' and p.Tip='TE' and abs(p.Cantitate)>=0.001)
,miscari as
	(select p.Subunitate, p.Tip, p.Cod, p.Gestiune, p.Cod_intrare, p.Gestiune_primitoare, p.Cod_intrare_primitor
	from transferuri p
	group by p.Subunitate, p.Tip, p.Cod, p.Gestiune, p.Cod_intrare, p.Gestiune_primitoare, p.Cod_intrare_primitor)
,coduri as
	(select p.Subunitate, p.Tip, p.Cod, Gestiune=convert(char(13),p.Gestiune), p.Cod_intrare, Nivel=0
	from predari p
	union all
	select p.Subunitate, p.Tip, p.Cod, m.Gestiune_primitoare, m.Cod_intrare_primitor, Nivel=p.Nivel+1
	from coduri p inner join miscari m on m.Subunitate=p.Subunitate and m.Cod=p.Cod 
		and m.Gestiune=p.Gestiune and m.Cod_intrare=p.Cod_intrare)
select * from coduri c where c.Nivel<=3
option (MAXRECURSION 2)