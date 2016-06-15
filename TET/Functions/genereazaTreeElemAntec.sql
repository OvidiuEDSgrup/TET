create function [dbo].[genereazaTreeElemAntec] (@id int, @parinte varchar(20))
returns xml
as
begin
	return 
	(	
		select 
			RTRIM(e.element) as cod, RTRIM(e.descriere) as _grupare,(case when e.procent=1 then '( '+RTRIM(e.formula)+' )*'+CONVERT(varchar(5),e.valoare_implicita) else RTRIM(e.formula) end) as pret,
			convert(decimal(10,2),p.pret) as valoare,CONVERT(varchar(6),e.valoare_implicita*100)+'%' as cantitate, (case when e.procent=1 then 'E' else '' end) as subtip,
			(case when procent=1 then 'Procent' else '-' end) as um,'E' as tip,convert(decimal(10,2),p.pret/a.curs) as valuta,
			(RTRIM(e.descriere) +' ('+rtrim(p.cod)+')') as denumireCod,dbo.genereazaTreeElemAntec(@id, e.element),RTRIM(descriere) as denumire,
			@id as idAntec, p.id as id
		from pozAntecalculatii p
		left join antecalculatii a on p.idp=a.idPoz and p.tip='E' and a.idAntec=@id
		inner join elemantec e on e.element=p.cod and e.element_parinte=@parinte and p.idp=a.idPoz
		order by element
		for xml raw,type
	)
end
