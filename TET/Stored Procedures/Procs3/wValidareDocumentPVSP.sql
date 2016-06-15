--***
create procedure wValidareDocumentPVSP @sesiune varchar(50), @parXML XML
as
declare @returnValue int
set nocount on
/*sp
if exists(select * from sysobjects where name='wValidareDocumentPVSPSP' and type='P')      
begin
	exec @returnValue = wValidareDocumentPVSPSP @sesiune,@parXML
	return @returnValue 
end
sp*/
set transaction isolation level read uncommitted
declare /*generale*/ 
		@ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @utilizator varchar(10), @dinOffline int, @subunitate varchar(9), 
		@tert varchar(50), @CasaDoc int, @vanzDoc varchar(50),@DataDoc datetime, @DataScad datetime, @zileScadChar varchar(20)/* citesc in varchar pt. a interpreta null */, 
		@numarDoc int, @GESTPV varchar(20), @nFetch int,
		@facturaDinBon bit, @observatii varchar(8000), @paramXmlString varchar(max), @UID varchar(50), @serieFactura varchar(20), @factura varchar(20),
		@tipDoc varchar(2), @oraDoc varchar(6), @comandaASiS varchar(50)/*campul comanda din comenzi livrare */, 
		@comLivrare varchar(50), @cDataComenzii varchar(50), @eBon int, @LM varchar(50), @zileScadenta int, 
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
			@incasariPeFactura = isnull(@parXML.value('(//document/@suntIncasari)[1]','bit'),0),
			@facturaDinBon = isnull(@parXML.value('(//document/@facturaDinBon)[1]','int'),0),
			@zileScadChar = @parXML.value('(//document/@zileScad)[1]','varchar(20)'),
			@DataScad = @parXML.value('(//document/@dataScad)[1]','datetime'),
			@oraDoc = @parXML.value('(//document/@ora)[1]','varchar(6)'),
			@tert = @parXML.value('(//document/@tert)[1]','varchar(50)'),
			@comLivrare = @parXML.value('(//document/@comanda)[1]','varchar(50)'),
			@cDataComenzii = @parXML.value('(//document/@datacomenzii)[1]','varchar(50)'),
			@GESTPV = @parXML.value('(//document/@GESTPV)[1]','varchar(50)')

	/*  completez date care nu sunt trimise in XML cu date implicite pe sesiune, utilizator, etc. */
	select	@eBon = (case when @tipDoc='AC' then 1 else 0 end),
			@eFactura = (case when @tipDoc='AP' then 1 else 0 end),
			@eTransfer = (case when @tipDoc='TE' then 1 else 0 end),
			@vanzDoc = @utilizator,
			@tert = isnull(@tert,''),
			@GESTPV= (case when isnull(@GESTPV,'')<>'' then @GESTPV else dbo.wfProprietateUtilizator('GESTPV', @utilizator) end),
			@listaGestiuni= dbo.wfListaGestiuniAtasatePV(@GESTPV)
	
	/* tabel cu structura tabelei bt(+coloane in plus) in care se vor salva datele bonului curent */
	-- a nu se modifica denumirea - poate e folosit prin SP-uri
	CREATE TABLE #bonTemp(Casa_de_marcat smallint NOT NULL,Factura_chitanta bit NOT NULL,Numar_bon int NULL/*la factura vine null*/,Numar_linie smallint NOT NULL,Data datetime NOT NULL,
		Ora char(6),Tip char(2) NOT NULL,Vinzator char(10) NOT NULL,Client char(13) NOT NULL,Cod_citit_de_la_tastatura char(20) NOT NULL,CodPLU char(20) NOT NULL,
		Cod_produs char(20) NOT NULL,Categorie smallint NOT NULL,UM smallint NOT NULL,Cantitate float NOT NULL,Cota_TVA real NOT NULL,Tva float NOT NULL,Pret float NOT NULL,
		Total float NOT NULL,Retur bit NOT NULL,Inregistrare_valida bit NOT NULL,Operat bit NOT NULL,Numar_document_incasare char(20) NOT NULL,Data_documentului datetime NOT NULL,
		Loc_de_munca char(9) NOT NULL,Discount float NOT NULL, lm_real varchar(9) null, Comanda_asis varchar(20) null, [Contract] varchar(20) null,
		--coloane specifice validarii
		o_pretcatalog float, tipNomencl char(1), cont_de_stoc varchar(50))
		
	insert #bonTemp(Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,Client,  
		Cod_citit_de_la_tastatura,CodPLU,Cod_produs,Categorie,UM,Cantitate,Cota_TVA,Tva,Pret,  
		Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului,  
		Loc_de_munca,Discount, lm_real, Comanda_asis,[Contract], o_pretcatalog)
	select	
		@CasaDoc, 
		@eBon as factura_chitanta, 
		@numarDoc, 
		nrlinie as linie,
		@DataDoc as data, 
		@oraDoc as ora, 
		(case when @eTransfer=1 and b.tip='21' then '11' else b.tip end) as tip, 
		@vanzDoc as vinzator, 
		@tert as client, 
		isnull(isnull(b.barcode,b.cod),'') as cod_tastatura, 
		isnull(b.cod,'') as cod_plu, 
		isnull(b.cod,'') as cod_produs, 
		'0'/*valabilitate - am lasat implicit 0 pt. linii tip incasare. La produse se face update mai jos */ as categorie, 
		ISNULL(b.um,1) as um, 
		cantitate, 
		isnull(b.cotatva,0) as cota_tva, 
		isnull(b.tva,0) as tva,
		isnull(b.pretcatalog,b.pret) as pret,
		b.valoare as total,
		0 as retur, 1 as inregistrare_valida, '' as operat, 
		(case when b.tip='21' and @codiinden=1 and charindex('|',b.denumire)>1 then left(b.denumire,charindex('|',b.denumire)-1) else isnull(iddocumentincasare,'') end) as nr_doc_incas, 
		'01/01/1901' as data_doc, 
		(case when isnull(gestiune,'')<>'' then gestiune else @GESTPV end) as gestiune, 
		isnull(b.discount,0) as discount, 
		b.lm as lm_real, 
		b.comanda_asis as Comanda_asis, 
		b.[contract] as [contract],
		o_pretcatalog
	from (select   /* deserializarea trebuie intretinuta si in wScriuDatePV si in wValidareDocumentPV */
		xA.row.value('@nrlinie', 'int') as nrlinie,
		xA.row.value('@tip', 'varchar(2)') as tip,   
		xA.row.value('@cod', 'varchar(20)') as cod,   
		xA.row.value('@barcode', 'varchar(50)') as barcode,   
		xA.row.value('@codUM', 'varchar(50)') as um,   
		xA.row.value('@cantitate', 'decimal(10,3)') as cantitate,   
		xA.row.value('@pret','decimal(10,3)') as pret,  
		xA.row.value('@pretcatalog','decimal(10,3)') as pretcatalog,  
		xA.row.value('@cotatva', 'decimal(5,2)') as cotatva,
		xA.row.value('@valoare', 'decimal(10,2)') as valoare,
		xA.row.value('@tva', 'decimal(10,2)') as tva,
		xA.row.value('@discount', 'decimal(10,2)') as discount,
		xA.row.value('@denumire', 'varchar(120)') as denumire,
		xA.row.value('@iddocumentincasare', 'varchar(20)') as iddocumentincasare,
		xA.row.value('@gestiune', 'varchar(20)') as gestiune, -- se trimite pentru comenzi/devize
		xA.row.value('@lm', 'varchar(20)') as lm,
		xA.row.value('@comanda_asis', 'varchar(20)') as comanda_asis,
		xA.row.value('@contract', 'varchar(20)') as [contract],
		xA.row.value('@o_pretcatalog','decimal(10,3)') as o_pretcatalog
		from @parXML.nodes('//document/pozitii/row') as xA(row)
		) as b 
		
		update t
			set categorie=n.categorie, tipNomencl=n.Tip, cont_de_stoc=n.Cont
		from #bonTemp t, nomencl n
		where t.Cod_produs=n.cod
	
	-- validare cont de stoc -> daca e atribuit terti, nu se permite bon
	--IF @eBon=1
	--BEGIN
	--	set @ErrorMessage=null
	--	select @ErrorMessage=isnull(@ErrorMessage,'')+CHAR(13)+rtrim(n.Denumire)
	--		from #bonTemp b 
	--		inner join nomencl n on b.Cod_produs=n.cod
	--		inner join conturi c on b.cont_de_stoc=c.cont and c.Sold_credit in (1,2)
	--		where b.tip='21'
		
	--	if @ErrorMessage is not null
	--	begin
	--		set @ErrorMessage='Bon invalid! Urmatoarele articole pot aparea doar pe factura: '+@ErrorMessage
	--		raiserror(@ErrorMessage,11,1)
	--	end
	--END
	
	-- tabela folosita la validare stoc pt. pozitii cu cant>0, si existenta pret_de_stoc pt pozitii cu cant<0
	create table #stocuri(cod varchar(20), tipnom char(1), cantitate float, stoc float, gestiune varchar(20) constraint PK_cod_gestiune primary key(cod, gestiune))
	
	if @vanzareFaraStoc=0 -- validare stoc
	begin
		-- calculez cantiate totala / produs
		insert #stocuri(cod, tipnom, cantitate, stoc, gestiune) 
		select b.Cod_produs, max(b.tipNomencl), sum(b.Cantitate), 0, b.Loc_de_munca
		from #bonTemp b
		where b.Tip='21' and b.tipNomencl<>'S'
		and b.Cantitate > 0 /* trebuie sa aiba pe stoc marfa care o da!
			returul va genera stoc nou dar nu va fi re-vandut pe acelasi bon :) */
		group by b.Cod_produs, b.Loc_de_munca

--/*sp --> caut intai in stocul din gestiunile de rezervari daca e cazul
		declare @rezervareStocComenzi bit, @gestRezervariComenzi varchar(200)
		EXEC luare_date_par 'GE', 'REZSTOCBK', @rezervareStocComenzi OUTPUT, 0, @gestRezervariComenzi OUTPUT
		
		if @rezervareStocComenzi=1 
			and exists(select 1 from #bonTemp b
				inner join #stocuri s on s.cod=b.Cod_produs and s.gestiune=b.Loc_de_munca
				where round(s.stoc,3)<round(s.cantitate,3) and (isnull(b.[Contract],'')<>'' or isnull(b.Comanda_asis,'')<>'')) 
		begin
			update st 
			set st.stoc=isnull(st.stoc,0)+s.stoc
			from #stocuri st
				inner join 
					(select s.Cod, s.stoc 
					from (select s.Comanda,s.Contract, s.cod as cod, SUM(s.stoc) as stoc 
						from stocuri s
							inner join dbo.split(@gestRezervariComenzi,';') lg on s.Cod_gestiune=lg.Item 
						where Subunitate=@subunitate and s.Tip_gestiune not in ('F','T') and s.stoc>0
						group by s.Comanda,s.Contract,s.cod) s
					inner join
						(select b.Comanda_asis,b.Contract, b.Cod_produs, SUM(b.Cantitate) as cantitate 
						from #bonTemp b where b.Cantitate>0
						group by b.Comanda_asis,b.Contract, b.Cod_produs) b
						on b.Cod_produs=s.Cod and b.Contract=s.Contract and b.Comanda_asis=s.Comanda) s 
					on s.cod=st.cod
			where round(st.stoc,3)<round(st.cantitate,3)
		end
--sp*/
		
		-- calculez stoc din toate gestiunile din care se poate face transfer
		update st 
			set st.stoc=isnull(st.stoc,0)+s.stoc
			from #stocuri st
			inner join 
				(select stocuri.cod, SUM(stocuri.stoc) stoc 
					from stocuri 
					inner join #stocuri sf on stocuri.Cod=sf.cod
					inner join dbo.split(@listagestiuni,';') lg on Cod_gestiune=lg.Item 
					where stocuri.Subunitate=@subunitate /*sp*/and stocuri.stoc>0 /*sp*/
					group by stocuri.cod) s on s.cod=st.cod
		/* nu filtrez gestiune=@GESTPV pt. ca, desi gest. pozitie poate fi alta, fac TE automat si 
			din aceste gestiuni cand nu e pe stoc in gest. pozitie.*/
		-- where gestiune=@GESTPV 
		
		-- daca este gestiune in pozitii, adaug la stoc si stocul pe acele gestiuni
		-- TODO: de tratat si gestiuni de rezervari.
/*sp*/	if exists(select 1 from #stocuri left join dbo.split(@listagestiuni,';') lg on gestiune=lg.Item 
				where lg.Item is null and round(stoc,3)<round(cantitate,3)) /*sp*/
		begin
			update st 
				set st.stoc=isnull(st.stoc,0)+s.stoc
				from #stocuri st
				inner join 
					(select s.cod as cod, SUM(s.stoc) as stoc 
						from stocuri s
						inner join #stocuri stocTmp on Cod_gestiune=stocTmp.gestiune and s.cod=stocTmp.cod
/*sp*/					left join dbo.split(@listagestiuni,';') lg on stocTmp.gestiune=lg.Item /*sp*/
						where Subunitate=@subunitate /*sp*/ and s.Tip_gestiune not in ('F','T') and s.stoc>0 and lg.Item is null /*sp*/
						group by s.cod) s on s.cod=st.cod
		end
		
		-- verific daca sunt produse la care stocul ar fi insuficient
		if exists (select 1 from #stocuri where tipnom<>'S' and round(stoc,3)<round(cantitate,3))
		begin
			set @ErrorMessage='Stoc insuficient pentru:'
			select @ErrorMessage=@ErrorMessage+CHAR(13)+RTRIM(Denumire)+' (max. '+convert(varchar(30),convert(decimal(12,3),#stocuri.stoc))+' '+nomencl.UM+')'
			from #stocuri 
			inner join nomencl on #stocuri.cod=nomencl.cod
			where round(#stocuri.stoc,3)<round(#stocuri.cantitate,3)
			
			raiserror(@errormessage,11,1)
		end
	end--if @vanzareFaraStoc=0
	
	if @facturaDinBon=1 and 1=0 -- nu validez nimic la facturi din bonuri, dar las selectul pt. cand va trebui
	begin 
		/* pentru facturi din bonuri  */
		declare @bonuriPeFactura table (dataBon datetime, numarBon int, casaDeMarcat int )
		insert into @bonuriPeFactura(casaDeMarcat, dataBon, numarBon)
		select   
			xA.row.value('@casamarcat', 'int') as casaDeMarcat,   
			xA.row.value('@data', 'datetime') as data,
			xA.row.value('@nrbon', 'int') as nrbon
		from @parXML.nodes('/date/document/bonuriPeFactura/row') as xA(row)
	end
/*sp
	-- la pozitii storno, verific existenta unui cod de intrare in stoc, pentru cand vor trebui scrise in pozdoc
	-- identificarea pretului de stoc e tratat si in wDescarcBon
	if exists (select * from #bonTemp b where b.Cantitate<0.001)
	begin
		declare @listaGestiuniPozitie varchar(200)
		if @tipDoc='AC' -- la bonuri trebuie facuta intrarea in gestiunea cu amanuntul
			set @listaGestiuniPozitie = ';'+@GESTPV+';'
		else
		begin -- la AP/TE e ok sa iau pretul de stoc din orice gestiune atasata la GESTPV
			set @listaGestiuniPozitie=';'+replace(rtrim(@listaGestiuni), @GESTPV+';', '')+';'+@GESTPV+';'
		end
		
		-- sterg valori vechi si inserez toate codurile cu cant<0
		-- ignor gestiunea din pozitii - toate se vor storna in gestiunea GESTPV sau cele asociate.
		truncate table #stocuri 
		insert into #stocuri(gestiune, tipnom, cod)
			select min(b.Loc_de_munca), max(b.tipNomencl), b.Cod_produs
			from #bonTemp b
			where b.Cantitate<0.001
			group by b.Cod_produs
		
		-- verific daca sunt linii in tabela stocuri 
		-- practic daca e stoc=null, nu a fost linie si nu este pret_de_stoc
		update st 
			set st.stoc=isnull(st.stoc,0)+s.stoc
			from #stocuri st
			inner join 
				(select stocuri.cod, SUM(stocuri.stoc) stoc 
					from stocuri 
					inner join #stocuri sf on stocuri.Cod=sf.cod
					inner join dbo.split(@listaGestiuniPozitie,';') lg on Cod_gestiune=lg.Item 
					where Subunitate=@subunitate
					group by stocuri.cod) s on s.cod=st.cod

		if exists ( select * from #stocuri st where st.tipnom<>'S' and st.stoc is null )
		begin
			set @ErrorMessage='Urmatoarele produse nu pot fi stornate pt. ca nu au fost vandute din aceasta gestiune:'
			select @ErrorMessage=@ErrorMessage+CHAR(13)+RTRIM(Denumire)+' ('+RTRIM(nomencl.cod)+')'
			from #stocuri 
			inner join nomencl on #stocuri.cod=nomencl.cod
			where #stocuri.stoc is null
			
			raiserror(@errormessage,11,1)
		end
	end
sp*/
	/*
		validari specifice facturilor fiscale
	*/
	if @eFactura=1 and @facturaDinBon=0
	begin 
		/*
			daca sunt incasari pe factura, validez sumele introduse
			in functie de o setare, daca sunt operate incasari, 
			facturile trebuie trimise si la casa de marcat, si astfel nu permitem valori negative la incasari.
		*/
		if @incasariPeFactura=1 and (select Val_numerica from par where Tip_parametru='PV' and Parametru='INCPEFACT')=2 
				and exists (select * from #bonTemp b where substring(b.tip,1,1)='3' and b.total<0)
					raiserror('Operarea de incasari cu valoare negativa nu este permisa.',11,1)
		
		-- validare sold tert 
		declare @totalFactura float, @totalIncasari float, @soldmaxim float, @sold float, @zileScadDepasite bit
		select	@totalFactura = isnull(@totalFactura,0) + (case when b.tip='21' then b.Total else 0 end),
				@totalIncasari = isnull(@totalIncasari,0) + (case when left(b.tip,1)='3' then b.Total else 0 end)
		from #bonTemp b  
		
		-- daca e achitat tot, nu validez factura
		if @totalFactura-@totalIncasari > 0.001
			and isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='BLOCTERT'),0)=1
		begin
			IF OBJECT_ID('tempdb.dbo.#validSold') IS NOT NULL
			DROP TABLE #validSold	
				
			select @tert tert, @totalFactura-@totalIncasari valoare, 0 sold, 0 sold_max
			into #validSold

			exec validSoldTert		
			--set @xml=(select @tert tert for xml raw)
			--exec wIaSoldTert @sesiune=@sesiune, @parXML=@xml output
			
			---- procedura returneaza null daca nu trebuie validat soldul
			--if @xml is not null
			--begin 
			--	select	@sold=@xml.value('(/row/@sold)[1]','float'),
			--			@soldmaxim=@xml.value('(/row/@soldmaxim)[1]','float'),
			--			@zileScadDepasite= @xml.value('(/row/@zilescadentadepasite)[1]','bit')
				
			--	if @zileScadDepasite=1
			--		set @ErrorMessage = isnull(@ErrorMessage+CHAR(13),'')+'Tertul are facturi cu scadenta depasita.'
				
			--	if @xml.value('(/row/@soldmaxim)[1]','float') is not null and @sold+@totalFactura-@totalIncasari>@soldmaxim
			--		set @ErrorMessage = isnull(@ErrorMessage+CHAR(13),'')+'Generarea facturii ar cauza depasirea soldului maxim pentru acest tert.'
			--			+CHAR(13)+ 'Soldul maxim permis este '+ CONVERT(varchar(30), convert(decimal(12,2), @soldmaxim)) + ' RON.'
			--			+CHAR(13)+ 'Soldul curent este '+ CONVERT(varchar(30), convert(decimal(12,2), @sold)) + ' RON.'
			--			+CHAR(13)+ 'Valoarea facturii curente '+ CONVERT(varchar(30), convert(decimal(12,2), @totalFactura-@totalIncasari)) + ' RON.'
				
			--	if len(@errormessage)>0
			--		raiserror(@ErrorMessage,11,1)
			--end
		end
	end
	
	-- validez existenta gestiunii pentru transfer
	if @eTransfer=1
	begin 
		if not exists (select * from gestiuni where substring(Denumire_gestiune,31,13)=@tert)
			raiserror('Gestiune invalida!',11,1)
	end
	
	-- alte validari specifice
	if exists(select * from sysobjects where name='wValidareDocumentPVSPSP1' and type='P')      
		exec wValidareDocumentPVSP1 @sesiune=@sesiune,@parXML=@parXML 
end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE()+' (wValidareDocumentPVSP)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
end catch

begin try
	IF OBJECT_ID('tempdb..#bonTemp') IS NOT NULL
		drop table #bonTemp
end try 
begin catch 
end catch

if LEN(@ErrorMessage)>0
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )