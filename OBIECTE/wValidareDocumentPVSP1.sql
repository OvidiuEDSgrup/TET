--***
if exists (select * from sysobjects where name ='wValidareDocumentPVSP1')
drop procedure wValidareDocumentPVSP1
go
/****** Object:  StoredProcedure [dbo].[wValidareDocumentPVSP]    Script Date: 06/13/2012 13:37:06 ******/
create procedure [dbo].[wValidareDocumentPVSP1] @sesiune varchar(50), @parXML XML
as
declare @returnValue int
set nocount on

set transaction isolation level read uncommitted
declare /*generale*/ 
		@ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @utilizator varchar(10), @dinOffline int, @subunitate varchar(9), 
		@tert varchar(50), @CasaDoc int, @vanzDoc varchar(50),@DataDoc datetime, @DataScad datetime, @zileScadChar varchar(20)/* citesc in varchar pt. a interpreta null */, 
		@numarDoc int, @GESTPV varchar(20), @nFetch int,
		@facturaDinBon bit, @observatii varchar(8000), @paramXmlString varchar(max), @UID varchar(50), @serieFactura varchar(20), @factura varchar(20),
		@tipDoc varchar(2), @oraDoc varchar(6), @comandaASiS varchar(50)/*campul comanda din comenzi livrare */, 
		@comLivrare varchar(50), @cDataComenzii varchar(50), @eBon int, @LM varchar(50), @zileScadenta int, @categoriePret int, 
		@incasariPeFactura bit, @numarBonFact varchar(20)/*il pun varchar pt ca sa fie null cand nu e trimis, chiar daca e int*/, 
		@listaGestiuni varchar(max), @vanzareFaraStoc bit, @codiinden int, @eFactura bit, @eTransfer bit, @xml xml
		
begin try

	exec luare_date_par 'GE','FARASTOC', @vanzareFaraStoc output, null, null
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	exec luare_date_par 'PV', 'CODIINDEN', @codiinden output, 0, '' /* setarea e true daca e si codul de intrare in denumirea scanata */
	
	/* citesc date antet document, locatie si delegat */
	/*citesc cu // pt. ca la inceput se trimitea doar /document la validare(fara <date>) */
	select	@UID = @parXML.value('(//document/@UID)[1]','varchar(50)'),
			@CasaDoc = @parXML.value('(//document/@casamarcat)[1]','int'),
			@numarDoc = @parXML.value('(//document/@numarDoc)[1]','int'),
			@numarBonFact = @parXML.value('(//document/@numarbon)[1]','varchar(20)'),/*la facturi cu incasari, trimit separat nr. de bon tiparit ca incasare factura*/
			@tipDoc = @parXML.value('(//document/@tipdoc)[1]','varchar(2)'),
			@serieFactura = @parXML.value('(//document/@seriefactura)[1]','varchar(20)'),
			@factura = @parXML.value('(//document/@factura)[1]','varchar(20)'),
			@DataDoc = @parXML.value('(//document/@data)[1]','datetime'),
			@facturaDinBon = isnull(@parXML.value('(/date/document/@facturaDinBon)[1]','int'),0),
			@zileScadChar = @parXML.value('(//document/@zileScad)[1]','varchar(20)'),
			@DataScad = @parXML.value('(//document/@dataScad)[1]','datetime'),
			@oraDoc = @parXML.value('(//document/@ora)[1]','varchar(6)'),
			@tert = @parXML.value('(//document/@tert)[1]','varchar(50)'),
			@comLivrare = @parXML.value('(//document/@comanda)[1]','varchar(50)'),
			@cDataComenzii = @parXML.value('(//document/@datacomenzii)[1]','varchar(50)'),
			@categoriePret=ISNULL(@parXML.value('(/row/@categoriePret)[1]', 'int'), ISNULL(@parXML.value('(//document/@categoriePret)[1]', 'int'), '1')), 
			@GESTPV = @parXML.value('(//document/@GESTPV)[1]','varchar(50)')

	/*  completez date care nu sunt trimise in XML cu date implicite pe sesiune, utilizator, etc. */
	select	@eBon = (case when @tipDoc='AC' then 1 else 0 end),
			@eFactura = (case when @tipDoc='AP' then 1 else 0 end),
			@eTransfer = (case when @tipDoc='TE' then 1 else 0 end),
			@vanzDoc = @utilizator,
			@tert = isnull(@tert,''),
			@GESTPV= (case when isnull(@GESTPV,'')<>'' then @GESTPV else dbo.wfProprietateUtilizator('GESTPV', @utilizator) end),
			@listaGestiuni= dbo.wfListaGestiuniAtasatePV(@GESTPV)

	if OBJECT_ID('tempdb..#bonTemp') is not null
		drop table #bonTemp
	
	create table #bonTemp(fakecolumn bit)
	
	-- procedura face structura corecta a tabeleli si scrie date in ea...
	exec creazaBonTemp @sesiune=@sesiune, @parXML=@parXML
	
	exec populareBonTemp @sesiune=@sesiune, @parXML=@parXML
/*	
	update t
	set categorie=n.categorie, tipNomencl=n.Tip, cont_de_stoc=n.Cont
		,pretamlista=coalesce(t.pretcomlivr,pr.Pret_cu_amanuntul,n.Pret_cu_amanuntul,0)
		,discinitial=isnull(t.disccomlivr,100*(1-t.pret/isnull(pr.Pret_cu_amanuntul,n.Pret_cu_amanuntul)))
		,discmax=(select top 1 CASE ISNUMERIC(valoare) when 1 then CONVERT(float,replace(Valoare,',','')) else null end 
				from proprietati pr 
				where pr.Valoare<>'' and pr.Cod<>'' and pr.tip='GRUPA' and pr.cod_proprietate='DISCMAX' 
						and n.Grupa like RTRIM(pr.Cod)+'%' order by pr.cod desc, pr.Valoare desc)
	from #bonTemp t inner join nomencl n on t.Cod_produs=n.cod
		left join (select p.UM,p.Cod_produs, max(p.Pret_cu_amanuntul) Pret_cu_amanuntul 
					from preturi p group by p.UM,p.Cod_produs) pr on pr.Cod_produs=n.Cod 
			and pr.UM=isnull((select top 1 valoare from proprietati p where p.Tip='GESTIUNE' and p.Cod_proprietate='CATEGPRET' 
						and p.Cod=t.gestpredte and p.Valoare<>''),1)
*/	
	-- verific sa nu fie pozitii cu acelasi cod si acelasi pret pentru ca e posibil sa li se dea acelasi cod de intrare 
	-- si atunci, daca vor vrea sa anuleze bonul, va da eroare pt ca unicitatea indexului pe docsters este dupa cod,cod_intrare
/*
	if exists (select 1 from #bonTemp t where t.Tip='21' group by t.Cod_produs,t.Pret having COUNT(distinct t.Numar_linie)>1)
		begin
			set @ErrorMessage=null
			select @ErrorMessage=ISNULL(@ErrorMessage,'')+CHAR(13)+RTRIM(t.Cod_produs)+'-'+RTRIM(max(n.Denumire))
			from #bonTemp t 
				inner join nomencl n on n.Cod=t.Cod_produs
			group by t.Cod_produs,t.Pret having COUNT(distinct t.Numar_linie)>1
			
			if isnull(@ErrorMessage,'')<>''
			begin
				set @ErrorMessage='Bon invalid! Urmatoarele articole avand acelasi pret trebuie unificate intr-o singura pozitie, insumand cantitatile: '
					+@ErrorMessage
				raiserror(@ErrorMessage,11,1)
				end
				
		end
*/		

	--IF OBJECT_ID('tempdb..#stocurisp1') IS NOT NULL
	--	drop table #stocurisp1
		
	---- tabela folosita la validare stoc pt. pozitii cu cant>0, si existenta pret_de_stoc pt pozitii cu cant<0
	--create table #stocurisp1(cod varchar(20), tipnom char(1), pret float, cantitate float, stoc float, gestiune varchar(20) constraint PK_cod_gestiunesp1 primary key(cod, gestiune))
	
	---- la pozitii storno, verific existenta unui cod de intrare in stoc, pentru cand vor trebui scrise in pozdoc
	---- identificarea pretului de stoc e tratat si in wDescarcBon
	----/*
	--declare @listaGestiuniPozitie varchar(200)
	--if exists (select 1 from #bonTemp b where b.Cantitate<0.001)
	--begin
	--	if @tipDoc='AC' -- la bonuri trebuie facuta intrarea in gestiunea cu amanuntul
	--		set @listaGestiuniPozitie = ';'+@GESTPV+';'
	--	else
	--	begin -- la AP/TE e ok sa iau pretul de stoc din orice gestiune atasata la GESTPV
	--		set @listaGestiuniPozitie=';'+replace(rtrim(@listaGestiuni), @GESTPV+';', '')+';'+@GESTPV+';'
	--	end
		
	--	-- sterg valori vechi si inserez toate codurile cu cant<0
	--	-- ignor gestiunea din pozitii - toate se vor storna in gestiunea GESTPV sau cele asociate.
	--	truncate table #stocurisp1 
	--	insert into #stocurisp1(gestiune, tipnom, cod, pret)
	--	select min(b.Loc_de_munca), max(b.tipNomencl), b.Cod_produs
	--		, round(dbo.rot_pret(round(convert(decimal(15,5),b.pret*(1-b.Discount/100)),5),0),2)
	--	from #bonTemp b
	--	where b.Cantitate<0.001
	--	group by b.Cod_produs, b.Pret, b.Discount
		
	--	-- verific daca sunt linii in tabela stocuri 
	--	-- practic daca e stoc=null, nu a fost linie si nu este pret_de_stoc
	--	update st 
	--	set st.stoc=isnull(st.stoc,0)+s.stoc
	--	from #stocurisp1 st
	--	inner join 
	--		(select stocuri.Tip_gestiune, stocuri.cod, stocuri.Pret_cu_amanuntul, SUM(stocuri.stoc) stoc 
	--			from stocuri 
	--			inner join #stocurisp1 sf on stocuri.Cod=sf.cod
	--			inner join dbo.split(@listaGestiuniPozitie,';') lg on Cod_gestiune=lg.Item 
	--			where Subunitate=@subunitate
	--			group by stocuri.Tip_gestiune,stocuri.cod, stocuri.Pret_cu_amanuntul) s 
	--		on s.cod=st.cod and abs(s.Pret_cu_amanuntul-st.pret)<0.0009
		
	--	declare @stocurisp1 xml=(select * from #stocurisp1 for xml raw)

	--	if exists ( select * from #stocurisp1 st where st.tipnom<>'S' and st.stoc is null )
	--	begin
	--		set @ErrorMessage='Urmatoarele produse nu pot fi stornate pt. ca nu se regasesc in stocurile din aceasta gestiune:'
	--		select @ErrorMessage=@ErrorMessage+CHAR(13)+RTRIM(Denumire)+' ('+RTRIM(nomencl.cod)+')'
	--		from #stocurisp1
	--		inner join nomencl on #stocurisp1.cod=nomencl.cod
	--		where #stocurisp1.stoc is null
			
	--		raiserror(@errormessage,11,1)
	--	end
	--end
	
	if exists (select 1 from #bonTemp b inner join nomencl n on n.Cod=b.Cod_produs and n.Tip not in ('R','S') where b.Cantitate<0.00001)
	begin
		--if OBJECT_ID('tempdb..#gesttransfer') is null
		--begin
		--	create table #gesttransfer(gestiune varchar(20),gestiune_transfer varchar(20),nrordine int)
		--	exec creeazaGestiuniTransfer
		--end
		
		set @ErrorMessage=null
		select @ErrorMessage='Nu pot fi returnate articole fara a specifica documentul initial! Va rog sa folositi operatia de stornare de pe bonul/factura initiala.'
/*
		select @ErrorMessage=isnull(@ErrorMessage,'Urmatoarele produse nu pot fi stornate pt. ca nu au fost vandute printr-un document din aceasta gestiune:')
			+CHAR(13)+RTRIM(n.Denumire)+' ('+RTRIM(n.cod)+')'
		from (select p.Loc_de_munca as cod_gestiune,gt.gestiune_transfer,p.Cod_produs,p.client,p.Data,gt.nrordine,sum(p.cantitate) as cantitate
			from #bonTemp p 
			left outer join #gesttransfer gt on gt.gestiune=p.Loc_de_munca 
			group by p.Loc_de_munca,gt.gestiune_transfer,p.Cod_produs,p.client,p.Data,gt.nrordine
			) pd 
		inner join nomencl n on n.Cod=pd.Cod_produs and n.Tip not in ('R','S')
		outer apply (select top (1) * from pozdoc t where t.Subunitate=@subunitate and t.Cod=pd.Cod_produs and t.Tert=pd.client --and t.Pret_de_stoc<t.Pret_vanzare
				and t.gestiune=isnull(pd.gestiune_transfer,pd.cod_Gestiune) and t.Tip in ('AP','AC') and t.Cantitate>0 and t.Data<=pd.Data order by t.Data desc) s 
		where pd.cantitate<0 and s.Cod is null
--*/		
		if @ErrorMessage is not null
			raiserror(@errormessage,11,1)
	end
	
	if @eBon=1 and exists (select 1 from #bonTemp b inner join nomencl n on n.Cod=b.Cod_produs and n.Tip not in ('R','S') where b.discount<0.00001)
	begin		
		set @ErrorMessage=null
		select @ErrorMessage='Nu pot fi emise bonuri cu discount negativ! Va rugam sa folositi metoda de lucru corecta pentru majorarea unui pret.'
	
		if @ErrorMessage is not null
			raiserror(@errormessage,11,1)
	end

	
	--if exists (select 1 from #bonTemp b where b.discmax is not null and ISNULL(b.Discount,0)+ISNULL(b.discinitial,0)>b.discmax)
	--begin
	--	set @ErrorMessage='Discountul introdus depaseste maximul pe grupa la articolele urmatoare: '
	--	select @ErrorMessage=@ErrorMessage+CHAR(13)+RTRIM(b.denumire)+' ('+RTRIM(b.Cod_produs)+')'
	--		+', DISCMAX: '+ rtrim(CONVERT(decimal(10,2),b.discmax))
	--	from #bonTemp b 
	--	where ISNULL(b.Discount,0)+ISNULL(b.discinitial,0)>ISNULL(b.discmax,100)
	--	raiserror(@ErrorMessage,11,1)
	--end
	
end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE()+' (wValidareDocumentPVSP1)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
end catch

begin try
	IF OBJECT_ID('tempdb..#bonTemp') IS NOT NULL
		drop table #bonTemp
		
	IF OBJECT_ID('tempdb..#stocurisp1') IS NOT NULL
		drop table #stocurisp1
end try 
begin catch 
end catch

if LEN(@ErrorMessage)>0
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )

GO