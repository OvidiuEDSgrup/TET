
CREATE procedure wOPPreluareDateCititorPontaj @sesiune varchar(50), @parXML XML
as
begin try
	declare @tippreluare int, @datainceput datetime, @datasfarsit datetime, @marca varchar(6), @mesaj varchar(500), @docPontaj xml

	set @tippreluare = @parXML.value('(/*/@tippreluare)[1]', 'int')
	set @datainceput = @parXML.value('(/*/@datainceput)[1]', 'datetime')
	set @datasfarsit = @parXML.value('(/*/@datasfarsit)[1]', 'datetime')
	set @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
	
	if exists (select 1	from sysobjects where name = 'wOPPreluareDateCititorPontajSP')
	begin
		if @tippreluare=0
			delete from PontajElectronic where convert(char(10),data_ora_intrare,101) between @datainceput and @datasfarsit
				and (ISNULL(@marca,'')='' or marca=@marca)
		
		if OBJECT_ID('tempdb..#tmpPontaj') is not null drop table #tmpPontaj
		create table #tmpPontaj 
			(marca varchar(6), data_ora_intrare datetime, data_ora_iesire datetime, detalii xml)	

		insert into #tmpPontaj
		EXEC wOPPreluareDateCititorPontajSP @sesiune = @sesiune, @parXML = @parXML

		set @docPontaj=(select a.marca marca,
				(select pe.idPontajElectronic, tp.data_ora_intrare as dataoraintrare, tp.data_ora_iesire dataoraiesire, pe.detalii, 
				(case when pe.idPontajElectronic is null then 0 else 1 end) as [update], 'Preluare' as operatie
				from #tmpPontaj tp
					left outer join PontajElectronic pe on pe.marca=tp.marca and pe.data_ora_intrare=tp.data_ora_intrare
				where tp.marca=a.marca
				for xml raw,type)
			from #tmpPontaj a 
			where isnull(@marca,'')='' or a.marca=@marca
			group by a.marca
			for xml raw,root('Date'))

		exec wScriuPontajElectronic @sesiune=@sesiune, @parXML=@docPontaj

	end	

	select 'Terminat operatie!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wOPPreluareDateCititorPontaj)'

	raiserror (@mesaj, 11, 1)
end catch
