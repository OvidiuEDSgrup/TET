CREATE PROCEDURE wOPFacturareContracte_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPFacturareContracte_pSP')
	begin
		exec wOPFacturareContracte_pSP @sesiune=@sesiune, @parXML=@parXML
		return
	end
	DECLARE @tert VARCHAR(20), @lm VARCHAR(20), @gestiune VARCHAR(20), @grupa VARCHAR(20), @mesaj VARCHAR(400), 
		@dataJos DATETIME, @dataSus DATETIME, @detaliiContract XML, @curs float,
		@valuta VARCHAR(20), @punct_livrare VARCHAR(20), @tipContract VARCHAR(2), @mijlocInterval datetime, @xml xml,
		@utilizator varchar(50), @idContractFiltrat int,@dataAzi datetime

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SET @tipContract = isnull(@parXML.value('(/*/*/@tip)[1]', 'varchar(2)'),'') -- filtrare dupa tip contract
	SET @idContractFiltrat = isnull(@parXML.value('(/*/*/@idContract)[1]', 'int'),0) -- filtrare un contract
	SET @dataJos = isnull(@parXML.value('(/*/*/@datajos)[1]', 'datetime'),'1901-01-01') -- data inferioara pt. filtrare
	SET @dataSus = isnull(@parXML.value('(/*/*/@datasus)[1]', 'datetime'),'2999-01-01') -- data superioara pt. filtrare
	SET @tert = isnull(@parXML.value('(/*/*/@tert)[1]', 'varchar(20)'),'') -- filtru tert
	SET @punct_livrare = isnull(@parXML.value('(/*/*/@punct_livrare)[1]', 'varchar(20)'),'') -- filtru punct livrare in cadrul tertului
	SET @lm = ISNULL(@parXML.value('(/*/*/@lm)[1]', 'varchar(20)'),'') 
	SET @gestiune = ISNULL(@parXML.value('(/*/*/@gestiune)[1]', 'varchar(20)'),'')
	SET @valuta = ISNULL(@parXML.value('(/*/*/@valuta)[1]', 'varchar(20)'),'') -- filtru valuta
	
	set @mijlocInterval = dateadd(day, datediff(day, @dataJos, @dataSus)/2, @dataJos)
	
	-- de completat cu tipurile care trebuie
	if @tipContract not in ('CS', 'CB','CL','CF')
		raiserror('Tipul contracte nu a fost ales!', 11, 1)
	
	set @dataAzi = convert(datetime, convert(char(10),getdate(),101),101)
	
	
	-- tabela cu contractele facturate
	declare @contracte table(
		idContract int primary key, 
		nrFactura varchar(20), -- numar factura aferent contractului
		idJurnal int ,-- id-ul din tabela de jurnale aferent operatiei curente
		valuta varchar(3),
		numar_contract varchar(20),
		tert varchar(13)
	)
	
	-- filtrare contracte
	insert into @contracte(idContract,valuta,numar_contract, tert)
	select idContract,valuta,c.numar as numar_contract,c.tert
	from contracte c 
	where valabilitate >= @dataAzi -- doar contractele valide
		and (@tipContract='' or tip = @tipContract)
		and (@idContractFiltrat=0 or idContract = @idContractFiltrat)
		and (@tert='' or tert = @tert)
		and (@punct_livrare='' or c.punct_livrare = @punct_livrare)
		and (@lm='' or loc_de_munca = @lm)
		and (@gestiune='' or gestiune = @gestiune)
		and (@valuta='' and isnull(valuta,'')='' or valuta = @valuta)
	
	-- tabela cu pozitiile contractelor facturate
	declare @pozitii table(idPozContract int, idContract int, cod varchar(20), cantitate decimal(12,3), pret decimal(15,5), discount decimal(5,2), 
		cod_specific varchar(50),valuta varchar(3), numar_contract varchar(20),tert varchar(13))
	
	-- iau pozitii -> se iau separat pt. ca sa nu faca joinu-uri multe.
	insert into @pozitii(idPozContract, idContract, cod, cantitate, pret, discount, cod_specific, valuta, numar_contract, tert)
	select 
		idPozContract,
		p.idContract,
		p.cod,
		p.cantitate,
		p.pret,
		p.discount,
		p.cod_specific,
		p.valuta,
		p.numar_contract,
		p.tert
	from 
		(select p.*,c.valuta,c.numar_contract,c.tert from PozContracte p  /* fac acest subselect pt. ca sa ma asigur ca nu face optimizatorul SQL prostii */
			inner join @contracte c on p.idContract = c.idContract) p
	where 
		-- pozitiile cu termene in perioada aleasa
		(isnull(p.periodicitate, 0)>0 or p.termen between @dataJos and @dataSus) 
		-- pozitii tip abonament facturat periodic
		and (isnull(p.periodicitate, 0)=0 or /* daca restul impartirii la periodicitate e acelasi pt. luna curenta si luna inceputului facturarii, se factureaza. */
						month(p.detalii.value('/row[1]/@data_start', 'datetime')) % p.periodicitate = month(@mijlocInterval) % p.periodicitate)
	
	-- las in @contracte doar contractele care au pozitii
	delete c
	 from @contracte c
		where not exists (select * from @pozitii p where p.idContract=c.idcontract )
	
	if not exists (select * from @contracte)
		raiserror('Nu exista pozitii de facturat in conditiile curente de filtrare!',11,1)
	
	-- punem intr-o tabela pozitiile de pe care s-a mai facturat in perioada selectata
	declare @documente table(idPozContract int,idPozdoc int,nrdoc varchar(20), datadoc datetime)
	insert into @documente
	select distinct p.idPozContract,pd.idPozDoc, rtrim(c.numar), c.Data
	from @pozitii p
		inner join contracte c on c.idContract=p.idContract
		inner join LegaturiContracte l on l.idPozContract=p.idPozContract
		inner join pozdoc pd on l.idPozDoc=pd.idPozDoc
	where pd.Subunitate='1' 
		and pd.tip='AP' 
		and pd.Data between @dataJos and @dataSus 
	
	if exists (select * from @documente)
	begin
		select @mesaj = isnull(@mesaj+', ', 'Urmatoarele contracte au documente generate in perioada aleasa: ') + nrdoc + ' - ' + convert(char(10), datadoc, 103)
			from @documente
		
		select @mesaj+'.' as textmesaj,'Atentie' titluMesaj for xml raw, root('Mesaje')	
		--set @mesaj=@mesaj +'.'
		--raiserror(@mesaj,11,1)
		
		--stergem din @pozitii pozitiile care au mai fost facturate in perioada selectata
		delete p
		from @pozitii p
			inner join @documente d on d.idPozContract=p.idPozContract
			
		if not exists(select 1 from @pozitii)
			raiserror('Nu exista pozitii de facturat in conditiile curente de filtrare!',11,1)	
	end
	
	--luam ultimul curs al lunii precedente din tabela de cursuri pentru valuta introdusa
	select top 1 @curs=curs 
	from curs
	where valuta=@valuta
		and MONTH(data)=MONTH(dateadd(m,-1,dbo.BOM(@dataAzi)))
		and YEAR(data)=YEAR(dateadd(m,-1,dbo.BOM(@dataAzi)))
	order by data desc
	
	
	--date pentru form
	select convert(varchar(10),@dataJos,101) as datajos ,convert(varchar(10),@dataSus,101)  datasus, convert(decimal(17,5),@curs) as curs, @valuta as valuta 
	for xml raw, root('Date')	
	
	--date pentru grid
	SELECT (   
		SELECT
			p.idContract,
			p.idPozContract,
			case when row_number() over (partition by p.idContract order by n.denumire)=1 then p.numar_contract else '' end as numar_contract,
			row_number() over (partition by p.idContract order by n.denumire) as nr_pozitie,
			p.cod,
			RTRIM(n.Denumire) as dencod,
			p.cantitate,
			p.pret,
			p.valuta,
			p.discount,
			p.cod_specific,
			p.tert,
			case when row_number() over (partition by p.idContract order by n.denumire)=1 then RTRIM(t.Denumire) else '' end as dentert
		FROM  @pozitii p
			inner join nomencl n on n.Cod=p.cod
			inner join terti t on t.Tert=p.tert
		WHERE p.cantitate<>0
		order by t.Denumire,p.idContract,row_number() over (partition by p.idContract order by n.denumire)
		FOR XML RAW, TYPE  
		)  
	FOR XML PATH('DateGrid'), ROOT('Mesaje')
	
	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPFacturareContracte_p)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH

