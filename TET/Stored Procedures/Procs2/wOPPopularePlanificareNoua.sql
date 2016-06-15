
CREATE PROCEDURE wOPPopularePlanificareNoua @sesiune VARCHAR(50), @parXML XML
AS
begin try
	declare 
		@comanda varchar(20), @datajos datetime, @datasus datetime, @datastart datetime, @datastop datetime, @orastart varchar(10), @orastop varchar(10), @operatia varchar(20), @numar varchar(20), @data datetime, @id_resursa int,
		@idAntet int

	select
		@comanda=@parXML.value('(/*/@comanda)[1]','varchar(20)'),
		@orastart=@parXML.value('(/*/@orastart)[1]','varchar(10)'),
		@orastop=@parXML.value('(/*/@orastop)[1]','varchar(10)'),
		@numar=@parXML.value('(/*/@numar)[1]','varchar(20)'),
		@operatia=@parXML.value('(/*/@operatia)[1]','varchar(20)'),
		@datajos=@parXML.value('(/*/@datajos)[1]','datetime'),
		@datasus=@parXML.value('(/*/@datasus)[1]','datetime'),
		@data=@parXML.value('(/*/@data)[1]','datetime'),
		@datastart=@parXML.value('(/*/@datastart)[1]','datetime'),
		@datastop=@parXML.value('(/*/@datastop)[1]','datetime'),
		@id_resursa=@parXML.value('(/*/@resursa)[1]','int')


	
	IF ISNULL(@id_resursa,0) = 0
		raiserror ('Completati resursa!',15,1)

	IF @operatia IS NULL
		raiserror ('Completati operatia pt. planificat!',15,1)


	IF OBJECT_ID('tempdb..#comenzi_filtr') IS NOT NULL
		drop table #comenzi_filtr

	select
		pCom.cod comanda 
	into #comenzi_filtr
	from pozLansari pcom
	JOIN pozLansari pant on pCom.parinteTop=pant.id or pcom.id=pant.id
	JOIN comenzi c on c.Comanda=pcom.cod 
	where (pant.cod=@comanda or ISNULL(@comanda,'')='' ) and pant.tip='L' and pcom.tip='L' and c.Data_lansarii between @datajos and @datasus
	
	create table #inserat (idAntet int)
	insert into AntetPlanificare(idResursa, data, numar, dataora_start,dataora_stop)
	OUTPUT inserted.idAntet into #inserat(idAntet)
	select @id_resursa, @data, @numar,DATEADD(day, DATEDIFF(day, 0, @datastart), @orastart), DATEADD(day, DATEDIFF(day, 0, @datastop), @orastop)
		
	select top 1 @idAntet=idAntet from #inserat

	insert into planificare(idAntet,idOp, resursa,cantitate, stare, dataStart, dataStop, oraStart, oraStop)
	select
		@idAntet, poz.id,@id_resursa, poz.cantitate, 'P',@datastart, @datastop, replace(@orastart,':',''), replace(@orastop,':','')
	from pozLansari ant
	JOIN #comenzi_filtr cf on ant.cod=cf.comanda
	JOIN pozLansari poz on poz.parinteTop=ant.id
	where poz.tip='O' and poz.cod=@operatia

	
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
