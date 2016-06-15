--***
create procedure wIaConfigMachete_FormMobile (@sesiune varchar(50), @parXML xml)
as

declare @mesaj varchar(500),
		@identificator varchar(100),
		@nume varchar(100),
		@tipobiect varchar(100),
		@datafield varchar(100),
		@procsql varchar(100),
		@listaetichete varchar(100),
		@vizibil varchar(100),
		@modificabil varchar(50)

begin try
	
	select @identificator = @parXML.value('(/*/@identificator)[1]','varchar(100)'),
			@nume = @parXML.value('(/*/@nume)[1]','varchar(100)'),
			@tipobiect = @parXML.value('(/*/@tipobiect)[1]','varchar(100)'),
			@datafield = @parXML.value('(/*/@datafield)[1]','varchar(100)'),
			@procsql = @parXML.value('(/*/@procsql)[1]','varchar(100)'),
			@listaetichete = @parXML.value('(/*/@listaetichete)[1]','varchar(100)'),
			@vizibil = @parXML.value('(/*/@vizibil)[1]','varchar(100)'),
			@modificabil = @parXML.value('(/*/@modificabil)[1]','varchar(100)')
	
	select	@nume=replace(@nume,' ','%'),
			@tipobiect=replace(@tipobiect,' ','%'),
			@identificator=replace(@identificator,' ','%'),
			@datafield=replace(@datafield,' ','%'),
			@procsql=replace(@procsql,' ','%'),
			@listaetichete=replace(@listaetichete,' ','%')
	
	select top 100
		--Identificator meniu,
		Identificator identificator,
		convert(decimal(15,0),Ordine) 
		--Ordine 
		ordine,
		Nume nume,
			TipObiect tipobiect,
			DataField datafield,
			LabelField labelfield,
			ProcSQL procsql,
		ListaValori listavalori,
		ListaEtichete listaetichete,
		Initializare initializare,
		Prompt prompt,
			case when wf.Vizibil=1 then 'Da' else 'Nu' end vizibil_,
			wf.Vizibil vizibil,
			case when wf.Modificabil=1 then 'Da' else 'Nu' end modificabil_,
			Modificabil modificabil
	from webconfigformmobile wf
	--where	(exists (select 1 from webConfigmeniu m where meniuparinte=@meniu and wf.identificator=m.meniu) or wf.identificator=@meniu)
	where (@identificator is null or wf.identificator like @identificator)
		and (@nume is null or wf.nume like @nume)
		and (@tipobiect is null or wf.tipobiect like @tipobiect)
		and (@datafield is null or wf.datafield like @datafield)
		and (@procsql is null or wf.procsql like @procsql)
		and (@listaetichete is null or wf.listaetichete like @listaetichete)
		and (@vizibil is null or wf.vizibil=@vizibil)
		and (@modificabil is null or wf.modificabil like @modificabil)
	order by identificator, ordine
	for xml raw
end try

begin catch
	set @mesaj = error_message() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 11, 1)
end catch
