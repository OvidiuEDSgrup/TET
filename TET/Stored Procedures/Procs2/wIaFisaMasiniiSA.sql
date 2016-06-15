--***
create procedure wIaFisaMasiniiSA @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@cod varchar(20)

	select
		@cod = @parXML.value('(/*/@codautovehicul)[1]', 'varchar(20)')
	
	select
		rtrim(a.Cod_deviz) as cod_deviz,
		convert(varchar(10), a.Data_lansarii, 103) as dataincepere,
		rtrim(isnull(t.Denumire, '')) as beneficiar,
		convert(decimal(15,2), a.Valoare_deviz) as valoaredeviz,
		convert(decimal(17,0), a.km_bord) as kmbord,
		rtrim(pdl.Denumire) as postlucru,
		(case when a.Stare = 0 then 'Neacceptat' 
			  when a.Stare = 1 then 'Lucru' 
			  when a.Stare = 2 then (case when a.Tip = 'B' then 'Finalizat - de facturat' else 'Finalizat' end)
				else 'Facturat' end) as stare
	from devauto a
	inner join Posturi_de_lucru pdl on pdl.Postul_de_lucru = a.Executant
	left join terti t on t.Tert = a.Beneficiar
	where a.Autovehicul = @cod
	order by a.Data_lansarii desc
	for xml raw, root('Date')

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
