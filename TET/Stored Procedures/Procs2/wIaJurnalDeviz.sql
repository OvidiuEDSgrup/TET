--***
create procedure wIaJurnalDeviz @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@f_stare varchar(20), @cod_deviz varchar(20)

	select
		@f_stare = '%' + isnull(@parXML.value('(/row/@f_stare)[1]', 'varchar(20)'), '') + '%',
		@cod_deviz = rtrim(@parXML.value('(/row/@nrdeviz)[1]', 'varchar(20)'))

	select
		convert(varchar(10), jd.data_operatii, 103) + ' ' + convert(varchar(8), jd.data_operatii, 108) as data,
		rtrim(jd.explicatii) as explicatii, jd.idJurnal as idJurnal, rtrim(jd.utilizator) as utilizator,
		convert(varchar(10), jd.data, 103) as datadoc,
		(case when jd.Stare = 0 then 'Neacceptat' when jd.Stare = 1 then 'Lucru'
		  when jd.Stare = 2 then (case when jd.detalii.value('(/row/@tip)[1]', 'varchar(1)') = 'B' then 'Finalizat - de facturat' else 'Finalizat' end)
		  else 'Facturat' end) + ' (' + convert(varchar(1), jd.stare) + ')' as stare
	from JurnalDocumente jd
	inner join devauto dv on dv.Cod_deviz = jd.numar
	where dv.Cod_deviz = @cod_deviz
		and (jd.stare like @f_stare or
			(case when jd.Stare = 0 then 'Neacceptat' 
				when jd.Stare = 1 then 'Lucru' 
				when jd.Stare = 2 then (case when jd.detalii.value('(/row/@tip)[1]', 'varchar(1)') = 'B'
					then 'Finalizat - de facturat' else 'Finalizat' end) 
						else 'Facturat' end) like @f_stare
		)
	order by jd.data
	for xml raw, root('Date')

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
