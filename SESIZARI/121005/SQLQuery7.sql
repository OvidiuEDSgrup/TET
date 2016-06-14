--***  
create procedure wScriuDatePV @sesiune varchar(50), @parXML xml  
as  
set nocount on  
set transaction isolation level read uncommitted  
declare /*generale*/   
  @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @utilizator varchar(10), @dinOffline int, @subunitate varchar(9),   
  @tert varchar(50), @CasaDoc int, @vanzDoc varchar(50),@DataDoc datetime, @DataScad datetime, @zileScadChar varchar(20)/* citesc in varchar pt. a interpreta null */,   
  @numarDoc int, @GESTPV varchar(20), @nFetch int,  
  @facturaDinBon int, @observatii varchar(max), @paramXmlString varchar(max), @UID varchar(50), @serieFactura varchar(20), @factura varchar(20),  
  @tipDoc varchar(2), @codFormular varchar(50), @oraDoc varchar(6), @comandaASiS varchar(50)/*campul comanda din comenzi livrare */,   
  @comLivrare varchar(50), @cDataComenzii varchar(50), @eBon int, @LM varchar(50), @zileScadenta int, @categoriePret int, @serieInNumar bit,  
  @incasariPeFactura bit, @numarBonFact varchar(20)/*il pun varchar pt ca sa fie null cand nu e trimis, chiar daca e int*/,  
  @inXML varchar(10),@datadebug datetime, @debug bit, @idAntetBon int, @eFactura bit, @eTransfer bit, @gestiuneTransfer varchar(30),  
  
  /*var delegat*/@delegatNou int, @idDelegat varchar(50), @numeDelegat varchar(50), @serieCI varchar(50), @numarCI varchar(50), @eliberatCI varchar(50),   
  /*var locatie*/@locatieNoua int, @idLocatie varchar(50), @descriereLocatie varchar(100), @adresaLocatie varchar(500), @judetLocatie varchar(50),   
   @localitateLocatie varchar(500), @bancaLocatie varchar(100), @contBancarLocatie varchar(100),  
  /*var locatie*/@idMasina varchar(50)  
begin try  
   
 set @datadebug=GETDATE()  
 exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
 exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output  
 exec luare_date_par 'PV', 'SERIEINNR', @serieInNumar output, 0, ''  
   
 /* apelez proc. specifica pt prelucrarea @parXML */  
 if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuDatePVSP')  
  exec wScriuDatePVSP @sesiune=@sesiune, @parXML=@parXML output  
   
 set @dinOffline = ISNULL(@parXML.value('(/date/document/@offline)[1]', 'int'), '0')   
   
 /* setarea e true daca e si codul de intrare in denumirea scanata */  
 declare @codiinden int  
 set @codiinden=isnull((select top 1 val_logica from par where tip_parametru='PV' and parametru='CODIINDEN'),0)  
   
 /* citesc date antet document, locatie si delegat */  
 select @debug = @parXML.value('(/date/@debug)[1]','varchar(50)'),  
   @UID = @parXML.value('(/date/document/@UID)[1]','varchar(50)'),  
   @CasaDoc = @parXML.value('(/date/document/@casamarcat)[1]','int'),  
   @numarDoc = @parXML.value('(/date/document/@numarDoc)[1]','int'),  
   @numarBonFact = upper(@parXML.value('(/date/document/@numarbon)[1]','varchar(20)')),/*la facturi cu incasari, trimit separat nr. de bon tiparit ca incasare factura*/  
   @facturaDinBon = isnull(@parXML.value('(/date/document/@facturaDinBon)[1]','int'),0),  
   @tipDoc = @parXML.value('(/date/document/@tipdoc)[1]','varchar(2)'),  
   @serieFactura = upper(@parXML.value('(/date/document/@seriefactura)[1]','varchar(20)')),  
   @factura = upper(@parXML.value('(/date/document/@factura)[1]','varchar(20)')),  
   @DataDoc = @parXML.value('(/date/document/@data)[1]','datetime'),  
   @zileScadChar = @parXML.value('(/date/document/@zileScad)[1]','varchar(20)'),  
   @DataScad = @parXML.value('(/date/document/@dataScad)[1]','datetime'),  
   @oraDoc = @parXML.value('(/date/document/@ora)[1]','varchar(6)'),  
   @tert = upper(@parXML.value('(/date/document/@tert)[1]','varchar(50)')),  
   @comLivrare = upper(@parXML.value('(/date/document/@comanda)[1]','varchar(50)')),  
   @cDataComenzii = @parXML.value('(/date/document/@datacomenzii)[1]','varchar(50)'),  
   @categoriePret=ISNULL(@parXML.value('(/row/@categoriePret)[1]', 'int'), ISNULL(@parXML.value('(/date/document/@categoriePret)[1]', 'int'), '1')),   
   @vanzDoc = upper(@parXML.value('(/date/document/@vanzator)[1]','varchar(50)')),  
   @GESTPV = upper(@parXML.value('(/date/document/@GESTPV)[1]','varchar(50)')),  
   @LM = upper(isnull(@parXML.value('(/date/document/@LM)[1]','varchar(50)'),@parXML.value('(/date/document/@lm)[1]','varchar(50)'))),  
   @observatii = upper(@parXML.value('(/date/document/@observatii)[1]','varchar(max)')),  
   @codFormular = upper(@parXML.value('(/date/document/@codFormular)[1]','varchar(50)')),  
   @inXML = @parXML.value('(/date/document/@inXML)[1]','varchar(50)'),  
   @incasariPeFactura = isnull(@parXML.value('(/date/document/@incasariPeFactura)[1]','bit'),0),  
   @comandaASiS = upper(@parXML.value('(/date/document/@comandaASIS)[1]','varchar(50)')),  
   @delegatNou = upper(isnull(@parXML.value('(/date[1]/document[1]/delegat[1]/@nou)','varchar(50)'),'')),  
   @idDelegat = upper(@parXML.value('(/date[1]/document[1]/delegat[1]/@idDelegat)','varchar(50)')),  
   @numeDelegat = upper(@parXML.value('(/date[1]/document[1]/delegat[1]/@nume)','varchar(20)')),-- limitat la 20 caractere pt. ca atat permite infotert in nume_delegat  
   @serieCI = upper(@parXML.value('(/date[1]/document[1]/delegat[1]/@serieCI)','varchar(50)')),  
   @numarCI = upper(@parXML.value('(/date[1]/document[1]/delegat[1]/@numarCI)','varchar(50)')),  
   @eliberatCI = upper(@parXML.value('(/date[1]/document[1]/delegat[1]/@eliberatCI)','varchar(50)')),  
   @locatieNoua = upper(isnull(@parXML.value('(/date[1]/document[1]/locatie[1]/@nou)','varchar(50)'),'')),  
   @idLocatie = upper(@parXML.value('(/date[1]/document[1]/locatie[1]/@idLocatie)','varchar(50)')),  
   @descriereLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@descriere)','varchar(100)'),  
   @adresaLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@adresa)','varchar(500)'),  
   @judetLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@judet)','varchar(50)'),  
   @localitateLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@localitate)','varchar(500)'),  
   @bancaLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@banca)','varchar(50)'),  
   @contBancarLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@cont)','varchar(50)'),  
   @idMasina = upper(@parXML.value('(/date[1]/document[1]/masina[1]/@idMasina)','varchar(50)'))  
     
 if @debug=1   
  select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaDecodeParXml'  
 /*  completez date care nu sunt trimise in XML cu date implicite pe sesiune, utilizator, etc.   
  utilizatorul vine completat in XML daca e din offline sau prin proc. specifica. */  
 select @eBon = (case when @tipDoc='AC' then 1 else 0 end),  
   @eFactura = (case when @tipDoc='AP' then 1 else 0 end),  
   @eTransfer = (case when @tipDoc='TE' then 1 else 0 end),  
   @vanzDoc = isnull(@vanzDoc, @utilizator),  
   @GESTPV = ISNULL(@GESTPV, dbo.wfProprietateUtilizator('GESTPV',@utilizator)),  
   @tert = isnull(@tert,'')  
   
 if isnull(@GESTPV,'')=''   
 begin  
  set @ErrorMessage='Utilizatorul '+@vanzDoc+' nu are gestiune atasata.'  
  raiserror(@ErrorMessage,11,1)  
 end  
   
 /* daca nu e trimis LM in XML(din proc. specifica), il iau din proprietati pe utilizator.   
  Daca e o comanda pe bonul respectiv, iau lm de pe comanda de livrare  
  Daca nu e nici acolo, iau LM asociat gestiunii. */  
 if @LM is null  
 begin  
  set @LM = rtrim(dbo.wfProprietateUtilizator('LOCMUNCA',@utilizator))  
  if isnull(@comLivrare,'')!=''  
   select top 1 @LM=loc_de_munca /*, @comandaASiS= de facut*/ from con where subunitate='1' and tip='BK' and Contract=@comLivrare /*-- nu merge and (@cDataComenzii is null or Data=convert(datetime,@cDataComenzii,103))*/  
   order by data desc  
    
  if @LM='' /* LM = '' daca nu este proprietatea */  
   set @LM = (select rtrim(max(Loc_de_munca)) from gestcor where Gestiune=@GESTPV)  
 end  
 if @debug=1   
  select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaValidariMici'  
   
 /* daca exista documentul, nu il mai inserez (se ajunge aici daca trimit doc. spre scriere si cade netu').   
 fac link pe casa si data pt cazul putin probabil in care s-ar genera acelasi UID de 2 ori. */  
 if exists( select 1 from antetBonuri where UID=@UID and Casa_de_marcat=@CasaDoc and Data_bon=@DataDoc)  
 begin  
  if @debug=1   
   select 'nu fac nimic, exista UID deja' gata    
     
   select @numarDoc=a.Numar_bon, @idAntetBon=a.idAntetBon   
    from antetBonuri a   
    where UID=@UID and Casa_de_marcat=@CasaDoc and Data_bon=@DataDoc  
     
   -- trimit acelasi raspuns ca si cum s-ar fi scris ok data trecuta.  
   select 'OK' as rezultatScriereBt, @numarDoc as numarDoc, @idAntetBon as idAntetBon for xml raw,root('Mesaje')  
  return 0  
 end  
 if @debug=1   
  select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaValidareUid'  
   
 if @eTransfer=1  
 begin  
  -- citesc gestiunea atasata tertului  
  select @gestiuneTransfer=RTRIM(Cod_gestiune)  
   from gestiuni   
   where substring(Denumire_gestiune,31,13)=@tert  
  if @gestiuneTransfer is not null  
  begin  
   if @parXML.value('(/date/document/@gestiuneTransfer)[1]','varchar(50)') is null  
    set @parXML.modify ('insert attribute gestprim {sql:variable("@gestiuneTransfer")} into (/date/document)[1]')  
   else  
    set @parXML.modify('replace value of (/date/document/@gestprim)[1] with sql:variable("@gestiuneTransfer")')  
  end  
 end  
   
 if @eBon = 0 -- procesare scadenta si date expeditie  
 begin   
  if @eFactura=1  
  begin  
  /* daca nu se completeaza din proc. specifica, iau scadenta din infotert, altfel 15 zile */  
   select @zileScadenta = (case when @zileScadChar is not null then CONVERT(int,@zileScadChar) else   
      isnull((select MIN(discount) from infotert where Subunitate='1' and Identificator='' and tert=@tert),0) end),  
     @DataScad= ISNULL(@DataScad, DATEADD(day, (case when @zileScadenta>0 then @zileScadenta else 15 end), @DataDoc))  
  end  
  if @debug=1 select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaCitireZileScad.'  
   
  /* salvare locatie si delegat nou sau citire delega/locatie daca exista)*/  
  if @delegatNou='1'  
  begin  
   /* la delegati noi scriu delegatul si apoi iau idDelegat scris pt scrierea in antetBon */  
   set @paramXmlString = '<row  tert=' + QUOTENAME(@tert,'""') + ' nume=' + QUOTENAME(@numeDelegat,'""') + ' seriebuletin=' + QUOTENAME(@serieCI,'""') +   
     ' numarbuletin=' + QUOTENAME(@numarCI,'""') + ' eliberatbuletin=' + QUOTENAME(@eliberatCI,'""') + ' />'  
    --print 'Scriu delegat nou : '+ @paramXmlString  
    exec wScriuPersoaneContact '', @paramXmlString  
    set @idDelegat= ( select MAX(Identificator) from infotert i where Subunitate='C'+@subunitate and tert=@tert and RTRIM(i.Descriere)=@numeDelegat)  
  end  
  else  
   /* daca exista delegatul, iau datele din infotert */  
   select @numeDelegat = rtrim(i.Descriere),  
     @serieCI = left(i.buletin,2),  
     @numarCI = SUBSTRING(i.buletin,4,10),  
     @eliberatCI = RTRIM(i.eliberat)  
     from infotert i where Subunitate='C'+@subunitate and tert=@tert and Identificator=@idDelegat  
  if @debug=1 select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaDelegat'  
    
  /* la locatii, ca si la delegati */    
  if (@locatieNoua='1')  
  begin  
   set @paramXmlString = '<row  tert=' + QUOTENAME(@tert,'""') + ' denpunctlivrare=' + QUOTENAME(@descriereLocatie,'""') + ' email=' + QUOTENAME(@adresaLocatie,'""') +   
     ' telefonfax=' + QUOTENAME(@judetLocatie,'""') + ' persoanacontact=' + QUOTENAME(@localitateLocatie,'""')  
     + ' banca=' + QUOTENAME(@bancaLocatie,'""') + ' continbanca=' + QUOTENAME(@contBancarLocatie,'""') + ' />'  
    --print 'Scriu locatie noua : '+ @paramXmlString  
    exec wScriuPuncteLivrare '', @paramXmlString  
   set @idLocatie= ( select MAX(Identificator) from infotert i where Subunitate=@subunitate and tert=@tert and RTRIM(i.Descriere)=@descriereLocatie)  
  end  
  else  
   select @descriereLocatie = rtrim(Descriere),  
     @adresaLocatie = rtrim(e_mail),  
     @judetLocatie = rtrim(Telefon_fax2),  
     @localitateLocatie = RTRIM(Pers_contact),  
     @bancaLocatie = rtrim(Banca2),  
     @contBancarLocatie = RTRIM(Cont_in_banca2)  
   from infotert i where Subunitate=@subunitate and tert=@tert and Identificator=@idLocatie  
  if @debug=1 select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaLocatie'  
    
  -- salvez masina in masiniexp  
  if not exists (select 1 from masinexp where Numarul_mijlocului = @idMasina and Furnizor=@tert) and isnull(@idMasina,'')<>''  
  begin  
   insert into masinexp(Numarul_mijlocului, Descriere, Furnizor, Delegat)  
   values (@idMasina, @idMasina, @tert, '')  
  end  
  if @debug=1 select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaMasina'  
    
  -- salvez ultimii delegati, locatii si masini, pt sugererare primii in lista   
  declare @proprietate varchar(20), @valoare varchar(20)  
  select @proprietate='UltMasina', @valoare=isnull(@idMasina,'')  
  if not exists (select 1 from proprietati where tip='TERT' and cod=@tert and cod_proprietate=@proprietate)  
   insert into proprietati(Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)  
   values ('TERT', @tert, @proprietate, @valoare, '')  
  else  
   update proprietati set Valoare=@valoare  
   where tip='TERT' and cod=@tert and cod_proprietate=@proprietate  
    
  select @proprietate='UltDelegat', @valoare=@idDelegat  
  if not exists (select 1 from proprietati where tip='TERT' and cod=@tert and cod_proprietate=@proprietate)  
   insert into proprietati(Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)  
   values ('TERT', @tert, @proprietate, @valoare, '')  
  else  
   update proprietati set Valoare=@valoare  
   where tip='TERT' and cod=@tert and cod_proprietate=@proprietate  
    
  select @proprietate='UltLocatie', @valoare=@idLocatie  
  if not exists (select 1 from proprietati where tip='TERT' and cod=@tert and cod_proprietate=@proprietate)  
   insert into proprietati(Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)  
   values ('TERT', @tert, @proprietate, @valoare, '')  
  else  
   update proprietati set Valoare=@valoare  
   where tip='TERT' and cod=@tert and cod_proprietate=@proprietate  
  if @debug=1   
   select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaSalvProprietati'  
 end  
   
 if OBJECT_ID('tempdb..#bonTemp') is not null  
  drop table #bonTemp  
   
 /* pregatesc tabela temporara cu datele care se insereaza in bt. tabelul are structura tabelei bt  
  in care se vor salva datele bonului curent */  
 CREATE TABLE #bonTemp(Casa_de_marcat smallint NOT NULL,Factura_chitanta bit, Numar_bon int,Numar_linie smallint NOT NULL,Data datetime NOT NULL,  
  Ora char(6) NOT NULL,Tip char(2) NOT NULL,Vinzator char(10) NOT NULL,Client char(13) NOT NULL,Cod_citit_de_la_tastatura char(20) NOT NULL,CodPLU char(20) NOT NULL,  
  Cod_produs char(20) NOT NULL,Categorie smallint NULL,UM smallint NOT NULL,Cantitate float NOT NULL,Cota_TVA real NOT NULL,Tva float NOT NULL,Pret float NOT NULL,  
  Total float NOT NULL,Retur bit NOT NULL,Inregistrare_valida bit NOT NULL,Operat bit NOT NULL,Numar_document_incasare char(20) NOT NULL,Data_documentului datetime NOT NULL,  
  Loc_de_munca char(9) NOT NULL,Discount float NOT NULL, lm_real varchar(9) null, Comanda_asis varchar(20) null, [Contract] varchar(20) null  
  constraint PK_numar_linie primary key(numar_linie))  
   
 insert #bonTemp(Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,Client,    
  Cod_citit_de_la_tastatura,CodPLU,Cod_produs,Categorie,UM,Cantitate,Cota_TVA,Tva,Pret,    
  Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului,    
  Loc_de_munca,Discount, lm_real, Comanda_asis,[Contract])  
 select @CasaDoc, @eBon as factura_chitanta, @numarDoc,   
 isnull(nrlinie,ROW_NUMBER() over (order by b.tip)) as linie,  
 @DataDoc as data, @oraDoc as ora,   
 (case when @eTransfer=1 and b.tip='21' then '11' else b.tip end) as tip,   
 @vanzDoc as vinzator, @tert as client,   
 isnull(isnull(b.barcode,b.cod),'') as cod_tastatura, isnull(b.cod,'') as cod_plu, isnull(b.cod,'') as cod_produs,   
 '0'/*valabilitate - am lasat implicit 0 pt. linii tip incasare. La produse se face update mai jos */ as categorie,   
 ISNULL(b.um,1) as um, cantitate, isnull(b.cotatva,0) as cota_tva,   
 (case when @tipDoc='AP'  
  then round(round(isnull(b.pretcatalog,b.pret)/(1.00+isnull(b.cotatva,0)/100.00),3)*b.cantitate*(1-isnull(b.discount,0)/100)*isnull(b.cotatva,0)/100.00,2)   
  else round(b.valoare*isnull(b.cotatva,0)/(100+isnull(b.cotatva,0)),2) end) as tva,  
 (case when @tipDoc='AP' then round(isnull(b.pretcatalog,b.pret)/(1.00+isnull(b.cotatva,0)/100.00),3) else isnull(b.pretcatalog,b.pret) end) as pret,  
 (case when @tipDoc='AP' then round(isnull(b.pretcatalog,b.pret)/(1.00+isnull(b.cotatva,0)/100.00),3)*b.cantitate else b.valoare end) as total,  
 0 as retur, 1 as inregistrare_valida, '' as operat,   
 (case when b.tip='21' and @codiinden=1 and charindex('|',b.denumire)>1 then left(b.denumire,charindex('|',b.denumire)-1) else isnull(iddocumentincasare,'') end) as nr_doc_incas,   
 '01/01/1901' as data_doc, (case when isnull(gestiune,'')<>'' then gestiune else @GESTPV end) as gestiune, isnull(b.discount,0) as discount,   
 b.lm as lm_real, b.comanda_asis as Comanda_asis, b.[contract] as [contract]  
 from (select     
  xA.row.value('@nrlinie', 'int') as nrlinie,  
  xA.row.value('@tip', 'varchar(2)') as tip,  
  xA.row.value('@cod', 'varchar(20)') as cod,  
  xA.row.value('@barcode', 'varchar(50)') as barcode,  
  xA.row.value('@codUM', 'varchar(50)') as um,  
  xA.row.value('@cantitate', 'decimal(10,3)') as cantitate,  
  xA.row.value('@pret','decimal(10,3)') as pret,  
  xA.row.value('@pretcatalog','decimal(10,3)') as pretcatalog,  
  xA.row.value('@cotatva', 'decimal(5,2)') as cotatva,  
  xA.row.value('@valoare',' decimal(10,2)') as valoare,  
  xA.row.value('@discount',' decimal(10,2)') as discount,  
  xA.row.value('@denumire',' varchar(120)') as denumire,    
  xA.row.value('@iddocumentincasare',' varchar(20)') as iddocumentincasare,  
  xA.row.value('@gestiune',' varchar(20)') as gestiune, -- se trimite pentru comenzi/devize  
  xA.row.value('@lm',' varchar(20)') as lm,  
  xA.row.value('@comanda_asis',' varchar(20)') as comanda_asis,  
  xA.row.value('@contract',' varchar(20)') as [contract]  
  from @parXML.nodes('date/document/pozitii/row') as xA(row)  
  ) as b   
    
  update t  
   set categorie=n.categorie  
  from #bonTemp t, nomencl n  
  where t.Cod_produs=n.cod  
  
 if @debug=1   
  select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaDecodePozitii'  
   
 /* scriere date in bt si AntetBonuri */  
 begin try  
  --begin tran scriuBT  
  /*  
   generare numar factura pt. facturi (mod online)  
   ( in mod offline, se da numar direct din PV )  
  */  
  if @eBon=0 and @numarDoc is null  
  begin   
   set transaction isolation level read committed  
     
   declare @fXML xml, @NrDocPrimit varchar(20)  
   set @fXML = ( select 'PV' as codMeniu, @utilizator as utilizator,  
    (case when @eFactura=1 then 'AP' when @eTransfer=1 then 'TE' else '' end) as tip for xml raw )  
   exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output  
      
   -- extrag serie din numar document - in coloana numar_bon nu intra decat int.  
   set @serieFactura=ISNULL(@serieFactura,'')  
   while dbo.isDigit(@NrDocPrimit)=0 and len(@NrDocPrimit)>1  
   begin  
    set @serieFactura=@serieFactura+SUBSTRING(@NrDocPrimit,1,1)  
    set @NrDocPrimit=SUBSTRING(@NrDocPrimit,2, len(@NrDocPrimit)-1)  
   end  
     
   if len(@NrDocPrimit)=1 and dbo.isDigit(@NrDocPrimit)=0  
    set @NrDocPrimit = null  
     
   if @NrDocPrimit is null  
    raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)  
     
   set @numarDoc=convert(int,@NrDocPrimit)  
     
   if ISNULL(@numarDoc, 0) = 0  
   begin  
    set @ErrorMessage='Nu s-a putut genera numar de document! Luati legatura cu furnizorul aplicatiei!'  
    raiserror(@errorMessage ,11,1)  
   end  
   else  
   begin  
    update #bonTemp set Numar_bon = @numarDoc  
    set @parXML.modify ('insert attribute numarDoc {sql:variable("@numarDoc")} into (/date/document)[1]')  
    set @parXML.modify ('insert attribute seriefactura {sql:variable("@serieFactura")} into (/date/document)[1]')  
   end  
   set transaction isolation level read uncommitted  
  end  
  if @debug=1   
   select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaLuatNrDoc'  
   
  /* formez factura - numarul de document care e dus in pozdoc.  
   factura = <serie> + <numar document>. Generat automat sau format in procedura specifica.  
   Se vor trimite din procedura specifica, atributele numarDoc(int), seriefactura(varchar) si factura(varchar).   
   Dimensiunea maxima e varchar(8). Nu se permite mai mare. */  
  if @serieFactura is null   
   set @serieFactura=''  
  -- includ seria in numarul doc. generat doar daca se foloseste setarea  
  if ISNULL(@serieInNumar,0)<>1  
   set @serieFactura=''     
  if @factura is null and @eBon=0  
   set @factura = @serieFactura+convert(varchar,@numarDoc)  
  
  if len(@factura)>8  
  begin  
   set @ErrorMessage='Lungimea maxima a numarului de factura este de 8 caractere. Factura curenta('+@factura+') are '+convert(varchar,LEN(@factura))+' caractere.'  
   raiserror(@ErrorMessage,11,1)  
  end  
    
  -- verific existenta in baza de date. Se face aici doar in acest punct am numar document in cazul facturilor.  
  if exists (select 1 from antetBonuri a where a.Casa_de_marcat=@CasaDoc and a.Data_bon=@DataDoc and a.Vinzator=@vanzDoc and a.Numar_bon=@numarDoc)  
   or exists (select 1 from bt b where b.Casa_de_marcat=@CasaDoc and b.Data=@DataDoc and b.Vinzator=@vanzDoc and b.Numar_bon=@numarDoc)  
   or exists (select 1 from bp b where b.Casa_de_marcat=@CasaDoc and b.Data=@DataDoc and b.Vinzator=@vanzDoc and b.Numar_bon=@numarDoc)  
  begin  
   set @ErrorMessage='Numarul de '+(case when @eBon=1 then 'bon' when @eFactura=1 then 'factura' else 'transfer' end)+'('+convert(varchar(50),@numarDoc)+') exista deja in baza de date.'  
   raiserror(@ErrorMessage,11,1)  
  end  
  if @debug=1   
   select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaValidUniqueIndex'   
    
  declare @insertedAntetBonuri table(idNou int)  
    
  /* insert in antetBonuri */  
  INSERT INTO antetBonuri(Casa_de_marcat, Chitanta, Numar_bon, Data_bon, Vinzator, Factura,   
   Data_facturii, Data_scadentei,   
   Tert, Gestiune, Loc_de_munca, Persoana_de_contact, Punct_de_livrare, Categorie_de_pret, [Contract], Comanda, Observatii, Explicatii, [UID], bon)  
   OUTPUT inserted.IdAntetBon into @insertedAntetBonuri(idNou)   
  select @CasaDoc, @eBon,@numarDoc, @DataDoc, @vanzDoc, @factura,   
   (case when @eFactura=1 then @DataDoc when @eTransfer=1 then @DataDoc else null end) as dataDoc, (case when @eFactura=1 then @DataScad else null end) as dataScad,   
   @tert, @GESTPV, @LM, @idDelegat, @idLocatie, @categoriePret as categPret, @comLivrare, @comandaASiS, @observatii, null, @UID, @parXML  
    
  --SELECT SCOPE_IDENTITY() -> nu merge pe versiuni SQL server <= 2008 din probleme de paralelism... http://blog.sqlauthority.com/2009/03/24/sql-server-2008-scope_identity-bug-with-multi-processor-parallel-plan-and-solution/  
  select @idAntetBon=idNou from @insertedAntetBonuri  
  if @debug=1 select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaInsertAntetbonuri'   
    
  begin try  
   /* inserare pozitii in bt */  
   insert bt(Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,Client,    
    Cod_citit_de_la_tastatura,CodPLU,Cod_produs,Categorie,UM,Cantitate,Cota_TVA,Tva,Pret,    
    Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului,    
    Loc_de_munca,Discount, lm_real, Comanda_asis,[Contract], idAntetBon)  
   select Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,upper(Client),    
    upper(Cod_citit_de_la_tastatura),upper(CodPLU),upper(Cod_produs),Categorie,UM,Cantitate,Cota_TVA,Tva,Pret,    
    Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului,    
    Loc_de_munca,Discount, lm_real, Comanda_asis,[Contract], @idAntetBon  
   from #bonTemp  
   if @debug=1 select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaInsertbt'   
    
  end try  
  begin catch -- la orice eroare de scriere in bt, sterg si linia din antetbonuri, pt. ca la urmatoarea scriere, se verifica linia din antetbonuri dupa UID.  
   delete from antetBonuri where idAntetBon=@idAntetBon  
   SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
   RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)  
  end catch  
    
    
  if (@numarBonFact is not null) /** la factura cu incasari, fac un insert si pt. nr de bon - pt. a avea o referinta. */  
  begin  
   INSERT INTO antetBonuri(Casa_de_marcat, Chitanta, Numar_bon, Data_bon, Vinzator, Factura, Data_facturii, Data_scadentei, Explicatii, [UID])  
   select @CasaDoc, 1,@numarBonFact, @DataDoc, @vanzDoc, @factura, @DataDoc, @DataScad , 'bon cu rol de incasare pentru factura '+@factura,   
    replace(@UID,'-','_')/*inlocuiesc '-' cu '_' pt. indexul unic */  
   if @debug=1 select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaInsertBonIncasare'  
  end  
  --commit tran scriuBT  
    
  select 'OK' as rezultatScriereBt, @numarDoc as numarDoc, @factura factura, @idAntetBon as idAntetBon for xml raw,root('Mesaje')  
 end try  
 begin catch   
  /* daca au fost erori de scriere anulez tranzactia, si dau mai departe eroarea */  
  --ROLLBACK TRAN scriuBT  
  SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  if @eBon=0  
  begin  
   /* la facturi, daca nu s-a putut salva in bt, se anuleaza */  
   set @ErrorMessage='Eroare la salvarea documentului pe server. Documentul a fost anulat.'+CHAR(10)+'Eroarea serverului:'+CHAR(10)+@ErrorMessage  
   select 'Anulat' as rezultatScriereBt, isnull(@numarDoc,-1) as numarDoc for xml raw,root('Mesaje')  
  end  
  else  
  begin  
   set @ErrorMessage='Eroare la salvarea bonului '+convert(varchar,@numarDoc)+' din '+CONVERT(varchar,@DataDoc,103)+' pe server. '+  
   'Se va reincerca salvarea pe server la urmatoarea intrare in aplicatie.'+CHAR(10)+'Eroarea serverului:'+CHAR(10)+@ErrorMessage  
  end  
  RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )  
  
 end catch  
  
 if OBJECT_ID('tempdb..#bonTemp') is not null  
  drop table #bonTemp  
   
 /* la facturi se mai proceseaza informatii si se tipareste factura... */  
 if @eBon=0  
 begin   
  if @facturaDinBon=1  
  begin  
   /* pentru facturi din bonuri - update pe antetBonuri si bp.Client cu bonurile */  
   declare @bonuriPeFactura table (dataBon datetime, numarBon int, casaDeMarcat int )  
   insert into @bonuriPeFactura(casaDeMarcat, dataBon, numarBon)  
   select     
    xA.row.value('@casamarcat', 'int') as casaDeMarcat,     
    xA.row.value('@data', 'datetime') as data,  
    xA.row.value('@nrbon', 'int') as nrbon  
   from @parXML.nodes('/date/document/bonuriPeFactura/row') as xA(row)  
   if @debug=1   
    select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaDecodeBonPeFact'  
     
   update bp  
   set Client = @tert  
   from @bonuriPeFactura x  
   where Casa_de_marcat = x.casaDeMarcat and Numar_bon = x.numarBon and Data = x.dataBon  
   if @debug=1   
    select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaUpdateBpClient'    
  
   update antetBonuri  
   set Tert=@tert, Factura=@factura, Data_facturii=@DataDoc, Data_scadentei=@DataScad  
   from @bonuriPeFactura x  
   where Casa_de_marcat = x.casaDeMarcat and Numar_bon = x.numarBon and Data_bon = x.dataBon  
   if @debug=1 select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaUpdateAntetBonuri'   
  end  
    
  /* scriu in anexafac date delegat */  
  declare @lungimeObservatii int  
  set @lungimeObservatii = (SELECT min(clmns.max_length) FROM sys.tables AS tbl   
     INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id where tbl.name='anexafac' and clmns.name= 'Observatii' )  
  if @debug=1   
   select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaVerLungObs'  
    
  if @eFactura=1  
  begin  
   delete from anexafac where subunitate=@subunitate and Numar_factura = @factura  
   insert into anexafac (Subunitate,Numar_factura,Numele_delegatului,Seria_buletin,Numar_buletin,                      
    Eliberat,Mijloc_de_transport,Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii)                      
   select @subunitate, @factura, @numeDelegat, @serieCI, @numarCI, @eliberatCI, 'AUTO', @idMasina, @DataDoc, @oraDoc, substring(@observatii,1,@lungimeObservatii)  
  end  
  else if @eTransfer=1  
  begin  
   delete from anexadoc where subunitate=@subunitate and Numar=@factura  
   insert anexadoc (Subunitate, Tip, Numar, Data, Numele_delegatului, Seria_buletin, Numar_buletin, Eliberat,   
    Mijloc_de_transport, Numarul_mijlocului, Data_expedierii, Ora_expedierii, Observatii, Punct_livrare, Tip_anexa)  
   values  
   (@subunitate, @tipDoc, @factura, @DataDoc, @numeDelegat, @serieCI, @numarCI, @eliberatCI, 'AUTO', @idMasina, @DataDoc, @oraDoc, @observatii, @idLocatie, '')  
  end  
  if @debug=1 select DATEDIFF(millisecond, @datadebug, getdate()) 'dupaInsertAnexafac'  
    
 end  
end try  
begin catch   
 SELECT @ErrorMessage = ERROR_MESSAGE()+' (wScriuDatePV)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
    
 RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )  
  
end catch  
  
if @debug=1   
 select DATEDIFF(millisecond, @datadebug, getdate()) 'gata'  