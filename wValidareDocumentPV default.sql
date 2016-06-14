--***
if exists (select * from sysobjects where name ='wValidareDocumentPV')
drop procedure wValidareDocumentPV
go
--***
create procedure wValidareDocumentPV @sesiune varchar(50), @parXML XML
as
declare @returnValue int
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
		@facturaDinBon int, @observatii varchar(max), @paramXmlString varchar(max), @UID varchar(50), @serieFactura varchar(20), @factura varchar(20),
		@tipDoc varchar(2), @codFormular varchar(50), @oraDoc varchar(6), @comandaASiS varchar(50)/*campul comanda din comenzi livrare */, 
		@comLivrare varchar(50), @cDataComenzii varchar(50), @chitanta int, @LM varchar(50), @zileScadenta int, @categoriePret int, @serieInNumar bit,
		@incasariPeFactura bit, @numarBonFact varchar(20)/*il pun varchar pt ca sa fie null cand nu e trimis, chiar daca e int*/, @gestiuneBon varchar(13),
		@listaGestiuni varchar(max), @vanzareFaraStoc bit, @codiinden int,

		/*var delegat*/@delegatNou int, @idDelegat varchar(50), @numeDelegat varchar(50), @serieCI varchar(50), @numarCI varchar(50), @eliberatCI varchar(50), 
		/*var locatie*/@locatieNoua int, @idLocatie varchar(50), @descriereLocatie varchar(100), @adresaLocatie varchar(500), @judetLocatie varchar(50), 
			@localitateLocatie varchar(500), @bancaLocatie varchar(100), @contBancarLocatie varchar(100),
		/*var locatie*/@idMasina varchar(50)

begin try
	exec luare_date_par 'GE','FARASTOC', @vanzareFaraStoc output, null, null
	if @vanzareFaraStoc=1 -- momentan se valideaza doar stocul.
		return 0

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
			@zileScadChar = @parXML.value('(//document/@zileScad)[1]','varchar(20)'),
			@DataScad = @parXML.value('(//document/@dataScad)[1]','datetime'),
			@oraDoc = @parXML.value('(//document/@ora)[1]','varchar(6)'),
			@tert = @parXML.value('(//document/@tert)[1]','varchar(50)'),
			@comLivrare = @parXML.value('(//document/@comanda)[1]','varchar(50)'),
			@cDataComenzii = @parXML.value('(//document/@datacomenzii)[1]','varchar(50)'),
			@categoriePret=ISNULL(@parXML.value('(/row/@categoriePret)[1]', 'int'), ISNULL(@parXML.value('(//document/@categoriePret)[1]', 'int'), '1')), 
			@GESTPV = @parXML.value('(//document/@GESTPV)[1]','varchar(50)')

	/*  completez date care nu sunt trimise in XML cu date implicite pe sesiune, utilizator, etc. */
	select	@chitanta = (case when @tipDoc='AC' then 1 else 0 end),
			@vanzDoc = @utilizator,
			@tert = isnull(@tert,''),
			@gestiuneBon= (case when @GESTPV<>'' then @GESTPV else dbo.wfProprietateUtilizator('GESTPV', @utilizator) end),
			@listaGestiuni= dbo.wfListaGestiuniAtasatePV(@gestiuneBon)
	
	/* tabel cu structura tabelei bt(+coloane in plus) in care se vor salva datele bonului curent */
	CREATE TABLE #bonTemp(Casa_de_marcat smallint NOT NULL,Factura_chitanta bit NOT NULL,Numar_bon int ,Numar_linie smallint NOT NULL,Data datetime NOT NULL,
		Ora char(6) NOT NULL,Tip char(2) NOT NULL,Vinzator char(10) NOT NULL,Client char(13) NOT NULL,Cod_citit_de_la_tastatura char(20) NOT NULL,CodPLU char(20) NOT NULL,
		Cod_produs char(20) NOT NULL,Categorie smallint NOT NULL,UM smallint NOT NULL,Cantitate float NOT NULL,Cota_TVA real NOT NULL,Tva float NOT NULL,Pret float NOT NULL,
		Total float NOT NULL,Retur bit NOT NULL,Inregistrare_valida bit NOT NULL,Operat bit NOT NULL,Numar_document_incasare char(20) NOT NULL,Data_documentului datetime NOT NULL,
		Loc_de_munca char(9) NOT NULL,Discount float NOT NULL, o_pretcatalog float)
		
	insert #bonTemp(Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,Client,  
		Cod_citit_de_la_tastatura,CodPLU,Cod_produs,Categorie,UM,Cantitate,Cota_TVA,Tva,Pret,  
		Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului,  
		Loc_de_munca,Discount, o_pretcatalog)
	select @CasaDoc, @chitanta as factura_chitanta, @numarDoc, 
	ROW_NUMBER() over (order by b.tip) as linie,
	@DataDoc as data, @oraDoc as ora, b.tip as tip, @vanzDoc as vinzator, @tert as client, 
	isnull(isnull(b.barcode,b.cod),'') as cod_tastatura, isnull(b.cod,'') as cod_plu, isnull(b.cod,'') as cod_produs, ISNULL(n.categorie, '0') as categorie, 
	ISNULL(b.um,1) as um, cantitate, isnull(b.cotatva,0) as cota_tva, 
	(case when @tipDoc='AP' 
		then round(round(isnull(b.pretcatalog,b.pret)/(1.00+isnull(b.cotatva,0)/100.00),3)*b.cantitate*(1-isnull(b.discount,0)/100)*isnull(b.cotatva,0)/100,2) 
		else round(b.valoare*isnull(b.cotatva,0)/(100+isnull(b.cotatva,0)),2) end) as tva,
	(case when @tipDoc='AP' then round(isnull(b.pretcatalog,b.pret)/(1.00+isnull(b.cotatva,0)/100.00),3) else isnull(b.pretcatalog,b.pret) end) as pret,
	(case when @tipDoc='AP' then round(isnull(b.pretcatalog,b.pret)/(1.00+isnull(b.cotatva,0)/100.00),3)*b.cantitate else b.valoare end) as total,
	0 as retur, 1 as inregistrare_valida, '' as operat, 
	(case when @codiinden=1 and charindex('|',b.denumire)>1 then left(b.denumire,charindex('|',b.denumire)-1) else '' end) as nr_doc_incas, 
	'01/01/1901' as data_doc, @gestiuneBon as gestiune,
	isnull(b.discount,0) as discount, o_pretcatalog
	from (select   
		xA.row.value('@tip', 'varchar(2)') as tip,   
		xA.row.value('@cod', 'varchar(20)') as cod,   
		xA.row.value('@barcode', 'varchar(50)') as barcode,   
		xA.row.value('@codUM', 'varchar(50)') as um,   
		xA.row.value('@cantitate', 'decimal(10,3)') as cantitate,   
		xA.row.value('@pret',' decimal(10,3)') as pret,  
		xA.row.value('@pretcatalog',' decimal(10,3)') as pretcatalog,  
		xA.row.value('@cotatva', 'decimal(5,2)') as cotatva,
		xA.row.value('@valoare',' decimal(10,2)') as valoare,
		xA.row.value('@discount',' decimal(10,2)') as discount,
		xA.row.value('@denumire',' varchar(120)') as denumire,
		xA.row.value('@o_pretcatalog',' decimal(10,3)') as o_pretcatalog
		from @parXML.nodes('//document/pozitii/row') as xA(row)
		) as b 
		left outer join nomencl n on b.cod=n.cod COLLATE DATABASE_DEFAULT  
	
	-- validare stoc/produs
	create table #stocuri(cod varchar(20) primary key, cantitate float, stoc float)
	-- calculez cantiate totala / produs
	insert #stocuri(cod, cantitate) 
	select b.Cod_produs, sum(b.Cantitate)
	from #bonTemp b
	where b.Tip='21'
	group by b.Cod_produs
	
	-- iau stoc maxim din stocuri, din toate gestiunile din care se face transfer
	update st 
	set stoc=isnull(st.stoc,0)+s.stoc
	from #stocuri st
	inner join stocuri s on s.Subunitate=@subunitate and s.Cod=st.cod
	inner join dbo.split(@listagestiuni,';') lg on s.Cod_gestiune=lg.Item
	where s.cod=st.cod
	
	-- verific daca sunt produse la care stocul ar fi insuficient
	if exists (select 1 from #stocuri where stoc<cantitate)
	begin
		set @ErrorMessage='Stoc insuficient pentru:'
		select @ErrorMessage=@ErrorMessage+CHAR(13)+RTRIM(Denumire)+' (max. '+convert(varchar(30),convert(decimal(12,3),#stocuri.stoc))+' '+nomencl.UM+')'
		from #stocuri 
		inner join nomencl on #stocuri.cod=nomencl.cod
		where #stocuri.stoc<cantitate
		
		raiserror(@errormessage,11,1)
	end
	
	drop table #bonTemp

		
	if @chitanta=0
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
		
end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE()+' (wValidareDocumentPV)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
	
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )
end catch
