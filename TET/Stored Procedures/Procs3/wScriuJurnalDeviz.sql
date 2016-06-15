--***
create procedure wScriuJurnalDeviz @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@utilizator varchar(20), @iDoc int

	declare @devize table (cod_deviz varchar(20), data datetime, stare int, explicatii varchar(max), detalii xml)

	exec sp_xml_preparedocument @iDoc output, @parXML
	
	insert into @devize(cod_deviz, data, stare, explicatii, detalii)
	select cod_deviz, data, stare, explicatii, detalii
	from openxml(@iDoc, '/row')
		with 
		(
			cod_deviz varchar(20) '@nrdeviz', 
			data datetime '@data',
			stare int '@stare',
			explicatii varchar(max) '@explicatii',
			detalii xml 'detalii/row'
		)
	exec sp_xml_removedocument @iDoc

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	if object_id('tempdb..#jurnalIntrodus') is not null
		drop table #jurnalIntrodus

	create table #jurnalIntrodus (idJurnal int, cod_deviz varchar(20))

	insert into JurnalDocumente (tip, numar, data, data_operatii, stare, explicatii, detalii, utilizator)
		output inserted.idJurnal, inserted.numar
		into #jurnalIntrodus(idJurnal, cod_deviz)
	select 'DA', cod_deviz, data, getdate(), isnull(stare, 0), explicatii, detalii, @utilizator
	from @devize

	set @parXML = (select idJurnal as idJurnal, cod_deviz as idContract from #jurnalIntrodus for xml raw )

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
