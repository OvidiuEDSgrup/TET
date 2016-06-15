Create procedure  wScriuFurnizoriArticol @sesiune varchar(30), @parXML XML
as 
begin try
	declare 
		@rootXml varchar(50), @iDoc int, @tip_sursa varchar(20)
	
	-- La operarea din macheta
	select
		@tip_sursa = isnull(@parXML.value('(//@tip_sursa)[1]','varchar(20)'),'P')

	/* In gridul din detaliere se arata si preturile din contracte furnizori care nu pot fi actualizare aici (tip_sursa=C la alea)*/
	IF @tip_sursa<>'P'
		return

	/* Tratam date multiple-> exemplu la scrierea din pozdoc */
	if @parXML.exist('(/Date)')=1 
		set @rootXml='/Date/row'
	else
		set @rootXml='/row'

	declare 
		@furnizoricod table (tert varchar(20), cod varchar(20),pret float, data datetime, zile_livrare int, cant_minima float, cod_furnizor varchar(20), prioritate int, o_prioritate int, [update] bit )

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	insert into @furnizoricod(tert, cod, pret, data, zile_livrare, cant_minima, cod_furnizor, prioritate, o_prioritate, [update] )
	select 
		tert, cod, ISNULL(pret,0), data, zile_livrare, cant_minima, cod_furnizor, ISNULL(NULLIF(prioritate,0),999), o_prioritate, ISNULL([update],0)
	from OPENXML(@iDoc, @rootXml)
	WITH 
	(
		tert varchar(20) '@tert', 
		cod  varchar(20) '@cod',
		pret float '@pstoc',
		data datetime '@datapret',
		zile_livrare int '@nrzilelivr',
		cant_minima float '@cantmin',
		cod_furnizor varchar(20) '@codf',
		prioritate varchar(20) '@prioritate',
		o_prioritate varchar(20) '@o_prioritate',
		[update] varchar(20) '@update'

	)
	exec sp_xml_removedocument @iDoc

	/* 
		Pentru prioritate "recalculata"
	*/
	declare
		@prioritate int, @o_prioritate  int

	select top 1
		@prioritate =  prioritate,
		@o_prioritate =  o_prioritate
	from @furnizoricod
		
	select 		
		pp.tert, pp.Cod_resursa cod, row_number() over (order by ISNULL(pp.prioritate,0), pp.pret)+(case when row_number() over (order by ISNULL(pp.prioritate,0),pp.pret)<ISNULL(fc.prioritate,0) or fc.[update]=1 then 0 else 1 end) prioritate
	into #ptPrioritate
	from PPreturi pp
	JOIN @furnizoricod fc on pp.cod_resursa=fc.cod

	update p
		set prioritate=f.prioritate+
		(case when fc.o_prioritate is null then 0
			when p.prioritate>fc.o_prioritate and p.prioritate<=fc.prioritate then -1
			when p.prioritate>=fc.prioritate and p.prioritate<fc.o_prioritate then 1
			else 0 
			end)
	from ppreturi p 
	JOIN #ptPrioritate f on p.Cod_resursa=f.cod and p.tert=f.Tert
	JOIN @furnizoricod fc on fc.cod=p.Cod_resursa


	/* Actualizam datele acolo unde ele sunt prezente*/
	update pp set 
		pret=fc.pret, 
		data_pretului=fc.data, 
		nr_zile_livrare=COALESCE(fc.zile_livrare, pp.nr_zile_livrare,0),
		cant_minima=COALESCE(fc.cant_minima, pp.cant_minima,0),
		codfurn= COALESCE(fc.cod_furnizor, pp.codfurn,''),
		prioritate=(case when pp.prioritate=ISNULL(fc.prioritate,0) then pp.prioritate else ISNULL(fc.prioritate,0) end)
	from ppreturi pp
	join @furnizoricod fc on pp.tip_resursa='C' and pp.tert=fc.tert and pp.cod_resursa=fc.cod and fc.data=pp.data_pretului

	/* Restul le inseram*/
	insert into ppreturi (tip_resursa, cod_resursa, tert, um_secundara, coeficient_de_conversie, pret, data_pretului, codfurn, nr_zile_livrare, cant_minima, prioritate)
	select 
		'C', fc.cod, fc.tert, '', 0, ISNULL(max(fc.pret),0), fc.data, ISNULL(max(fc.cod_furnizor),''), ISNULL(max(fc.zile_livrare),0), ISNULL(max(fc.cant_minima),0), max(fc.prioritate)
	from @furnizoricod fc
	LEFT JOIN ppreturi pp on fc.cod=pp.cod_resursa and fc.tert=pp.tert and fc.data=pp.data_pretului
	where pp.tert is null
	group by fc.cod,fc.tert,fc.data

end try
begin catch
	declare @mesaj varchar(500)
	set @mesaj = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror (@mesaj, 15, 1)
end catch
