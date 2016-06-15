create procedure stergereProvizioane @sesiune varchar(50), @parXML xml
as
begin try
	declare	
		@data_lunii datetime, @tert varchar(20)
	/* Permite si filtru pe un singur TERT	*/
	select 
		@data_lunii = @parXML.value('(/*/@data_lunii)[1]','datetime'),
		@tert = NULLIF(@parXML.value('(/*/@tert)[1]','varchar(20)'),'')

	if @data_lunii IS NULL
		return

	/* Stergem documentele din @data_lunii (caz ca se ruleaza inchiderea de mai multe ori, samd) si provizioanele*/
	-- Documentele de constituire provizioane		
	delete P
	from PozADoc p
	INNER JOIN Provizioane pv on p.tip='CB' and p.data>=@data_lunii and p.idPozadoc=pv.idPozADoc and pv.idPozADoc is not null
		and (@tert IS NULL OR pv.tert=@tert)
	
	-- Notele de constituire si lichidare provizioane
	delete n
	from PozNCon n
	INNER JOIN Provizioane pv on n.tip='NC' and n.Data>=@data_lunii and n.idPozncon=pv.idPozNCon and pv.idPozNCon is not null
		and (@tert IS NULL OR pv.tert=@tert)

	-- Notele de dif. de curs valutar la fact. provizionate
	delete nc
	from PozNCon nc where nc.tip='NC' and nc.data=@data_lunii and nc.numar='DFP'+convert(varchar(10), @data_lunii,103) and (@tert IS NULL or nc.tert=@tert)

	delete nc
	from NCon nc where nc.tip='NC' and nc.data=@data_lunii and nc.numar='DFP'+convert(varchar(10), @data_lunii,103)

	-- Provizioanele
	delete Provizioane where datalunii>=@data_lunii and (@tert IS NULL OR tert=@tert)

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
