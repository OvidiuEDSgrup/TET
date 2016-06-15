--***
create procedure wValidareDocumentPV @sesiune varchar(50), @parXML XML
as
declare @returnValue int
set nocount on
if exists(select * from sysobjects where name='wValidareDocumentPVSP' and type='P')      
begin
	exec @returnValue = wValidareDocumentPVSP @sesiune,@parXML
	return @returnValue 
end

set transaction isolation level read uncommitted
declare /*generale*/ 
		@ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @utilizator varchar(10), @dinOffline int, @subunitate varchar(9), 
		@tert varchar(50), @CasaDoc int, @vanzDoc varchar(50),@DataDoc datetime, @DataScad datetime, @zileScadChar varchar(20)/* citesc in varchar pt. a interpreta null */, 
		@numarDoc int, @GESTPV varchar(20), @nFetch int,
		@facturaDinBon bit, @observatii varchar(8000), @paramXmlString varchar(max), @UID varchar(50), @serieFactura varchar(20), @factura varchar(20),
		@tipDoc varchar(2), @oraDoc varchar(6), @comandaASiS varchar(50)/*campul comanda din comenzi livrare */, 
		@comLivrare varchar(50), @cDataComenzii varchar(50), @eBon int, @LM varchar(50), @zileScadenta int, 
		@incasariPeFactura bit, @numarBonFact varchar(20)/*il pun varchar pt ca sa fie null cand nu e trimis, chiar daca e int*/, 
		@listaGestiuni varchar(max), @vanzareFaraStoc_OLD bit, @vanzareFaraStoc bit, @codiinden int, @eFactura bit, @eTransfer bit, @xml xml
		
begin try

	exec luare_date_par 'GE','FARASTOC', @vanzareFaraStoc_OLD output, null, null
	exec luare_date_par 'GE','FARAVSTN', @vanzareFaraStoc output, null, null
	
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
	
	if OBJECT_ID('tempdb..#bonTemp') is not null
		drop table #bonTemp
	
	create table #bonTemp(fakecolumn bit)
	
	-- procedura face structura corecta a tabeleli si scrie date in ea...
	exec creazaBonTemp @sesiune=@sesiune, @parXML=@parXML
	
	exec populareBonTemp @sesiune=@sesiune, @parXML=@parXML
	
	update t
		set categorie=n.categorie, tipNomencl=n.Tip, cont_de_stoc=n.Cont
	from #bonTemp t, nomencl n
	where t.Cod_produs=n.cod
	
	-- validare cont de stoc -> daca e atribuit terti, nu se permite bon
	IF @eBon=1
	BEGIN
		set @ErrorMessage=null
		select @ErrorMessage=isnull(@ErrorMessage,'')+CHAR(13)+rtrim(n.Denumire)
			from #bonTemp b 
			inner join nomencl n on b.Cod_produs=n.cod
			inner join conturi c on b.cont_de_stoc=c.cont and c.Sold_credit in (1,2)
			where b.tip='21'
		
		if @ErrorMessage is not null
		begin
			set @ErrorMessage='Bon invalid! Urmatoarele articole pot aparea doar pe factura: '+@ErrorMessage
			raiserror(@ErrorMessage,11,1)
		end
	END
	
	-- tabela folosita la validare stoc pt. pozitii cu cant>0, si existenta pret_de_stoc pt pozitii cu cant<0
	create table #stocuri(cod varchar(20), tipnom char(1), cantitate float, stoc float, gestiune varchar(20) constraint PK_cod_gestiune primary key(cod, gestiune))
	
	if @vanzareFaraStoc_OLD=0 -- validare stoc dupa setarea veche din ASiSplus (=1 inseamna ca nu validez stocul)
		and @vanzareFaraStoc=0 -- validare stoc de ASiSria/PVria (=1 inseamna ca nu validez stocul)
	begin
		-- calculez cantiate totala / produs
		insert #stocuri(cod, tipnom, cantitate, stoc, gestiune) 
		select b.Cod_produs, max(b.tipNomencl), sum(b.Cantitate), 0, b.Loc_de_munca
		from #bonTemp b
		where b.Tip='21' and b.tipNomencl<>'S'
		and b.Cantitate > 0 /* trebuie sa aiba pe stoc marfa care o da!
			returul va genera stoc nou dar nu va fi re-vandut pe acelasi bon :) */
			and b.detalii.value('(/row/@idpozdocrezervare)[1]','int') IS NULL
		group by b.Cod_produs, b.Loc_de_munca
		
		-- calculez stoc din toate gestiunile din care se poate face transfer
		update st 
			set st.stoc=isnull(st.stoc,0)+s.stoc
			from #stocuri st
			inner join 
				(select stocuri.cod, SUM(stocuri.stoc) stoc 
					from stocuri 
					inner join #stocuri sf on stocuri.Cod=sf.cod
					inner join dbo.split(@listagestiuni,';') lg on Cod_gestiune=lg.Item 
					where stocuri.Subunitate=@subunitate and stocuri.stoc>0
					group by stocuri.cod) s on s.cod=st.cod
		/* nu filtrez gestiune=@GESTPV pt. ca, desi gest. pozitie poate fi alta, fac TE automat si 
			din aceste gestiuni cand nu e pe stoc in gest. pozitie.*/
		-- where gestiune=@GESTPV 
		
		-- daca este gestiune in pozitii, adaug la stoc si stocul pe acele gestiuni
		if exists(select 1 from #stocuri where gestiune<>@GESTPV and stoc<cantitate)
		begin
			update st 
				set st.stoc=isnull(st.stoc,0)+s.stoc
				from #stocuri st
				inner join 
					(select s.cod as cod, SUM(s.stoc) as stoc 
						from stocuri s
						inner join #stocuri stocTmp on Cod_gestiune=stocTmp.gestiune and s.cod=stocTmp.cod
						where Subunitate=@subunitate
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
		
		-- aici erau validate pozitiile storno (sa fie o intrare in gestiunile atasate GESTPV)
		-- intre timp s-a tratat generarea unei pozitii de stoc - nu mai validam pozitiile storno.
	end
	
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
		begin
			set @xml=(select @tert tert for xml raw)
			exec wIaSoldTert @sesiune=@sesiune, @parXML=@xml output
			
			-- procedura returneaza null daca nu trebuie validat soldul
			if @xml is not null
			begin 
				select	@sold=@xml.value('(/row/@sold)[1]','float'),
						@soldmaxim=@xml.value('(/row/@soldmaxim)[1]','float'),
						@zileScadDepasite= @xml.value('(/row/@zilescadentadepasite)[1]','bit')
				
				if @zileScadDepasite=1
					set @ErrorMessage = isnull(@ErrorMessage+CHAR(13),'')+'Tertul are facturi cu scadenta depasita.'
				
				if @xml.value('(/row/@soldmaxim)[1]','float') is not null and @sold+@totalFactura-@totalIncasari>@soldmaxim
					set @ErrorMessage = isnull(@ErrorMessage+CHAR(13),'')+'Generarea facturii ar cauza depasirea soldului maxim pentru acest tert.'
						+CHAR(13)+ 'Soldul maxim permis este '+ CONVERT(varchar(30), convert(decimal(12,2), @soldmaxim)) + ' RON.'
						+CHAR(13)+ 'Soldul curent este '+ CONVERT(varchar(30), convert(decimal(12,2), @sold)) + ' RON.'
						+CHAR(13)+ 'Valoarea facturii curente '+ CONVERT(varchar(30), convert(decimal(12,2), @totalFactura-@totalIncasari)) + ' RON.'
				
				if len(@errormessage)>0
					raiserror(@ErrorMessage,11,1)
			end
		end
	end
	
	-- validez existenta gestiunii pentru transfer
	if @eTransfer=1
	begin 
		if not exists (select * from gestiuni where substring(Denumire_gestiune,31,13)=@tert)
			raiserror('Gestiune invalida!',11,1)
	end
	
	exec wVerificaFacturaSimplificata @sesiune=@sesiune, @parXML=@parXML
	
	-- alte validari specifice
	if exists(select * from sysobjects where name='wIaComandaRestaurantInPv' and type='P')      
		exec wIaComandaRestaurantInPv @sesiune=@sesiune,@parXML=@parXML 

	-- alte validari specifice
	if exists(select * from sysobjects where name='wValidareDocumentPVSP1' and type='P')      
		exec wValidareDocumentPVSP1 @sesiune=@sesiune,@parXML=@parXML 
end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE()+' (wValidareDocumentPV)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
end catch

begin try
	IF OBJECT_ID('tempdb..#bonTemp') IS NOT NULL
		drop table #bonTemp
end try 
begin catch 
end catch

if LEN(@ErrorMessage)>0
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )
