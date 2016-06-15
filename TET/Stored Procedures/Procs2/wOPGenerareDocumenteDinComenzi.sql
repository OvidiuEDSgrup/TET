
create procedure wOPGenerareDocumenteDinComenzi @sesiune varchar(50), @parXML XML
as
begin try
	declare @mesaj varchar(500), @tert varchar(20), @comanda varchar(20), @grupa_terti varchar(20), @datajos datetime, @datasus datetime,@docXML xml,
	 @utilizator varchar(100),@lm varchar(20), @nrcrt int,@total int,@comanda_transport varchar(20),@docPlajaXML xml,@tipPlaja varchar(2),
	 @observatii varchar(60), @dataDoc datetime,@gestiune varchar(20),

	/* Parametrii de expeditie */ 
	@numedelegat varchar(30),@mijloctp varchar(30),@nrmijtransp varchar(20),@seriabuletin varchar(10),
	@numarbuletin varchar(10),@eliberat varchar(30),

	/** Pt scriere pozdoc **/
	@tipDoc varchar(2), @numarDoc varchar(20)
	
	/** Date si filtre din macheta de operatie **/
	set @tert=isnull(@parXML.value('(/*/@tert)[1]','varchar(20)'),'')
	set @comanda=isnull(@parXML.value('(/*/@comanda)[1]','varchar(20)'),'')
	set @grupa_terti=isnull(@parXML.value('(/*/@grupa_terti)[1]','varchar(20)'),'')
	set @lm=isnull(@parXML.value('(/*/@lm)[1]','varchar(20)'),'')
	set @gestiune=isnull(@parXML.value('(/*/@gestiune)[1]','varchar(20)'),'')
	set @comanda_transport=isnull(@parXML.value('(/*/@comanda_transport)[1]','varchar(20)'),'')
	set @datajos=isnull(@parXML.value('(/*/@datajos)[1]','datetime'),'01/01/1910')
	set @datasus=isnull(@parXML.value('(/*/@datasus)[1]','datetime'),'01/01/2110')
	set @tipDoc=@parXML.value('(/*/@tip_documente)[1]','varchar(2)')

	/* Date pentru expeditie **/
	select
	@numedelegat=upper(ISNULL(@parXML.value('(/*/@numedelegat)[1]', 'varchar(30)'), '')),
	@mijloctp=ISNULL(@parXML.value('(/*/@mijloctp)[1]', 'varchar(30)'), ''),		
	@nrmijtransp=upper(ISNULL(@parXML.value('(/*/@nrmijltransp)[1]', 'varchar(20)'), '')),		
	@seriabuletin=upper(ISNULL(@parXML.value('(/*/@seriabuletin)[1]', 'varchar(10)'), '')),		
	@numarbuletin=upper(ISNULL(@parXML.value('(/*/@numarbuletin)[1]', 'varchar(10)'), '')),		
	@eliberat=upper(ISNULL(@parXML.value('(/*/@eliberat)[1]', 'varchar(30)'), ''))

	
	if (@numedelegat='' or @mijloctp='' or @nrmijtransp ='' or @seriabuletin='' or @numarbuletin='' or @eliberat='')  and @tipDoc='AP'
		raiserror('Compleati datele legate pentru expeditie! Se generaza factura.',11,1)	

	if OBJECT_ID('tempdb..#CON') is not null
		drop table #CON
	if OBJECT_ID('tempdb..#POZCON') is not null
		drop table #POZCON

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	/** Se filtraeza in tabela temporara Comenzile de luat in considerare **/
	select c.*
	into #CON
	from con c 
	JOIN terti t on t.Tert=c.Tert where c.Subunitate='1' and c.tip='BK' and (@comanda='' OR c.Contract=@comanda)
	and c.data between @datajos and @datasus and (@grupa_terti='' OR t.Grupa=@grupa_terti ) and (@tert='' or c.Tert=@tert)
	and (@lm='' or c.Loc_de_munca like @lm+'%')
	and stare<>'0'
	and (@gestiune='' OR c.gestiune = @gestiune)
	and (@comanda_transport='' or c.Mod_penalizare=@comanda_transport)

	/** Pe baza comenzilor (antete) de mai sus se filtreaza si pozitiile **/
	select pc.*
	into #POZCON
	from PozCon pc
	JOIN #CON c on pc.Subunitate='1' and pc.contract=c.Contract and pc.Data=c.Data and pc.tert=c.Tert and pc.tip='BK'


	/** Se sterg pozitiile fara cantitati, sau cu cantitate aiurea, iar apoi se verifica si se sterg antetele carora nu le-au mai ramas pozitii**/
	delete #POZCON where cant_aprobata<=0.0 
	delete  c 
	from #CON c
	where not exists (select 1 from #POZCON pc where pc.Subunitate='1' and pc.contract=c.Contract and pc.Data=c.Data and pc.tert=c.Tert and pc.tip='BK' )
	
	if OBJECT_ID('tempdb..#CONNR') is not null
		drop table #CONNR

	/** Se numeroteaza contractele **/
	select row_number() over (order by NEWID()) nrcrt, c.*
	into #CONNR
	from #CON c
			
	/** "Cursor" pentru apel wScriuPozDoc in dreptul fiecari comenzi **/
	Select @total= count(*) from #CONNR
	set @nrcrt=1

	if @tipDoc = 'AF'
		select @tipPlaja='AP'
	else
		select @tipPlaja=@tipDoc
	if @tipDoc='AP'
		set @dataDoc=GETDATE()

	while @nrcrt<=@total
	begin
		/** Numar din plaja pt fiecare apel wScriuPozDoc **/
		set @docPlajaXML = '<row/>'
		set @docPlajaXML.modify ('insert attribute tip {sql:variable("@tipPlaja")} into (/row)[1]')
		set @docPlajaXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		exec wIauNrDocFiscale @parXML=@docPlajaXML, @Numar=@numarDoc output

		/** DAca este factura scriem si detaliile de expeditie **/
		if @tipDoc='AP'
		begin
			if not exists (select 1 from anexafac where Subunitate='1' and Numar_factura=@numarDoc)
			insert anexafac
			(Subunitate,Numar_factura,Numele_delegatului,Seria_buletin,Numar_buletin,Eliberat,Mijloc_de_transport,
				Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii)
			values ('1', @numarDoc, @numedelegat, @seriabuletin, @numarbuletin, @eliberat, @mijloctp, 
				@nrmijtransp, @datadoc, '', @observatii) 
		end
				
		/** Se formeaza documetul de trimis la procedura wScriuPozDoc, cu tot cu pozitii **/
		set @docXML=
		(
			select
				'1' as '@subunitate', (case when @tipDoc = ('AF') then 'AP' else @tipDoc end) as '@tip', rtrim(c.Tert) as '@tert',
				rtrim(@numarDoc) as '@numar', convert(varchar(20),getDATE(),101) as '@data', 
				rtrim(c.gestiune) as '@gestiune', (case @tipDoc when 'TE' then rtrim(c.cod_dobanda) else rtrim(c.Contract) end ) as '@contract',
				 rtrim(c.loc_de_munca) as '@lm',c.Scadenta as '@zilescadenta', rtrim(c.Punct_livrare) as '@punctlivrare',
				 (case @tipDoc when 'TE' then rtrim(c.cod_dobanda) end ) as '@gestprim'	,
				rtrim(@numedelegat) as '@numedelegat', rtrim(@mijloctp) as '@mijloctp', rtrim(@nrmijtransp) as '@nrmijloctp',
				rtrim(@seriabuletin) as '@seriabuletin',rtrim(@numarbuletin) as '@numarbuletin', rtrim(@eliberat) as '@eliberat',
				rtrim(c.explicatii) as '@observatii',(case when @tipDoc in ('AF','TE') then '' else @numarDoc end ) as '@factura',
				'1' as '@fara_luare_date',
				(
					select 
						convert(varchar(20),p.pret) as '@pvaluta', rtrim(c.valuta) as '@valuta',convert(varchar(20),c.curs) as '@curs',
						CONVERT(decimal(5,2),p.Discount) as '@discount',rtrim(p.cod) as '@cod', 
						convert(decimal(15,2),p.cant_aprobata ) as '@cantitate',rtrim(c.Contract) as '@contract', rtrim(c.loc_de_munca) as '@lm'
					from #POZCON p
					where p.data=c.Data
					and p.contract=c.Contract
					and c.tert=p.Tert
					for xml PATH, TYPE
				) 
			from #CONNR c 
			where c.nrcrt=@nrcrt
			for XML PATH, type
		)

		exec wScriuPozDoc @sesiune=@sesiune, @parXML=@docXML
		select @nrcrt=@nrcrt+1
	end

end try

begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wOPGenerareDocumenteDinComenzi)'
	raiserror(@mesaj, 11,1)
end catch
