--***  
create procedure wScriuDatePVSP @sesiune varchar(50), @parXML xml OUTPUT  
as  
set nocount on  
set transaction isolation level read uncommitted  
declare /*generale*/   
  @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @utilizator varchar(10), @dinOffline int, @subunitate varchar(9),   
  @tert varchar(50), @CasaDoc int, @vanzDoc varchar(50),@DataDoc datetime, @DataScad datetime, @zileScadChar varchar(20)/* citesc in varchar pt. a interpreta null */,   
  @numarDoc int, @GESTPV varchar(20), @nFetch int,  
  @facturaDinBon int, @observatii varchar(max), @paramXmlString varchar(max), @UID varchar(50), @serieFactura varchar(20), @factura varchar(20),  
  @tipDoc varchar(2), @codFormular varchar(50), @oraDoc varchar(6), @comandaASiS varchar(50)/*campul comanda din comenzi livrare */,   
  @comLivrare varchar(50), @cDataComenzii varchar(50), @chitanta int, @LM varchar(50), @zileScadenta int, @categoriePret int, @serieInNumar bit,  
  @incasariPeFactura bit, @numarBonFact varchar(20)/*il pun varchar pt ca sa fie null cand nu e trimis, chiar daca e int*/,  
  
  /*var delegat*/@delegatNou int, @idDelegat varchar(50), @numeDelegat varchar(50), @serieCI varchar(50), @numarCI varchar(50), @eliberatCI varchar(50),   
  /*var locatie*/@locatieNoua int, @idLocatie varchar(50), @descriereLocatie varchar(100), @adresaLocatie varchar(500), @judetLocatie varchar(50),   
   @localitateLocatie varchar(500), @bancaLocatie varchar(100), @contBancarLocatie varchar(100),  
  /*var locatie*/@idMasina varchar(50)  
  
begin try  
 exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
   
 exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output  
 exec luare_date_par 'PV', 'SERIEINNR', @serieInNumar output, 0, ''  
   
 /* apelez proc. specifica pt prelucrarea @parXML */  
 --if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuDatePVSP')  
 -- exec wScriuDatePVSP @sesiune, @parXML output  
   
 set @dinOffline = ISNULL(@parXML.value('(/date/document/@offline)[1]', 'int'), '0')   
   
 /* setarea e true daca e si codul de intrare in denumirea scanata */  
 declare @codiinden int  
 set @codiinden=isnull((select top 1 val_logica from par where tip_parametru='PV' and parametru='CODIINDEN'),0)  
   
 /* citesc date antet document, locatie si delegat */  
 select @UID = @parXML.value('(/date/document/@UID)[1]','varchar(50)'),  
   @CasaDoc = @parXML.value('(/date/document/@casamarcat)[1]','int'),  
   @numarDoc = @parXML.value('(/date/document/@numarDoc)[1]','int'),  
   @numarBonFact = @parXML.value('(/date/document/@numarbon)[1]','varchar(20)'),/*la facturi cu incasari, trimit separat nr. de bon tiparit ca incasare factura*/  
   @tipDoc = @parXML.value('(/date/document/@tipdoc)[1]','varchar(2)'),  
   @serieFactura = @parXML.value('(/date/document/@seriefactura)[1]','varchar(20)'),  
   @factura = @parXML.value('(/date/document/@factura)[1]','varchar(20)'),  
   @DataDoc = @parXML.value('(/date/document/@data)[1]','datetime'),  
   @zileScadChar = @parXML.value('(/date/document/@zileScad)[1]','varchar(20)'),  
   @DataScad = @parXML.value('(/date/document/@dataScad)[1]','datetime'),  
   @oraDoc = @parXML.value('(/date/document/@ora)[1]','varchar(6)'),  
   @tert = @parXML.value('(/date/document/@tert)[1]','varchar(50)'),  
   @comLivrare = @parXML.value('(/date/document/@comanda)[1]','varchar(50)'),  
   @cDataComenzii = @parXML.value('(/date/document/@datacomenzii)[1]','varchar(50)'),  
   @categoriePret=ISNULL(@parXML.value('(/row/@categoriePret)[1]', 'int'), ISNULL(@parXML.value('(/date/document/@categoriePret)[1]', 'int'), '1')),   
   @vanzDoc = @parXML.value('(/date/document/@vanzator)[1]','varchar(50)'),  
   @GESTPV = @parXML.value('(/date/document/@GESTPV)[1]','varchar(50)'),  
   @LM = isnull(@parXML.value('(/date/document/@LM)[1]','varchar(50)'),@parXML.value('(/date/document/@lm)[1]','varchar(50)')),  
   @observatii = @parXML.value('(/date/document/@observatii)[1]','varchar(max)'),  
   @codFormular = @parXML.value('(/date/document/@codFormular)[1]','varchar(50)'),  
   @incasariPeFactura = isnull(@parXML.value('(/date/document/@incasariPeFactura)[1]','bit'),0),  
   @comandaASiS = @parXML.value('(/date/document/@comandaASIS)[1]','varchar(50)'),  
   @delegatNou = isnull(@parXML.value('(/date[1]/document[1]/delegat[1]/@nou)','varchar(50)'),''),  
   @idDelegat = @parXML.value('(/date[1]/document[1]/delegat[1]/@idDelegat)','varchar(50)'),  
   @numeDelegat = @parXML.value('(/date[1]/document[1]/delegat[1]/@nume)','varchar(50)'),  
   @serieCI = @parXML.value('(/date[1]/document[1]/delegat[1]/@serieCI)','varchar(50)'),  
   @numarCI = @parXML.value('(/date[1]/document[1]/delegat[1]/@numarCI)','varchar(50)'),  
   @eliberatCI = @parXML.value('(/date[1]/document[1]/delegat[1]/@eliberatCI)','varchar(50)'),  
   @locatieNoua = isnull(@parXML.value('(/date[1]/document[1]/locatie[1]/@nou)','varchar(50)'),''),  
   @idLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@idLocatie)','varchar(50)'),  
   @descriereLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@descriere)','varchar(100)'),  
   @adresaLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@adresa)','varchar(500)'),  
   @judetLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@judet)','varchar(50)'),  
   @localitateLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@localitate)','varchar(500)'),  
   @bancaLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@banca)','varchar(50)'),  
   @contBancarLocatie = @parXML.value('(/date[1]/document[1]/locatie[1]/@cont)','varchar(50)'),  
   @idMasina = @parXML.value('(/date[1]/document[1]/masina[1]/@idMasina)','varchar(50)')  
     
   
 /*  completez date care nu sunt trimise in XML cu date implicite pe sesiune, utilizator, etc.   
  utilizatorul vine completat in XML daca e din offline sau prin proc. specifica. */  
 select @chitanta = (case when @tipDoc='AC' then 1 else 0 end),  
   @vanzDoc = isnull(@vanzDoc, @utilizator),  
   @GESTPV = ISNULL(@GESTPV, dbo.wfProprietateUtilizator('GESTPV',@utilizator)),  
   @tert = isnull(@tert,'')  
 --if @LM='' /* LM = '' daca nu este trimis*/  
 --begin  
 set @LM = isnull((select rtrim(max(Loc_de_munca)) from gestcor where Gestiune=@GESTPV),  
  (select MIN(valoare) from proprietati where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>''))  
 if @LM is null  
  set @parXML.modify('insert attribute LM {sql:variable("@LM")} into (/date/document)[1]')  
 else  
  set @parXML.modify('replace value of (/date/document/@LM)[1] with sql:variable("@LM")')  
 --end  
 --if @chitanta=1 and @factura is null  
 -- set @parXML.modify('insert attribute factura {""} into (/date/document)[1]')  
  
end try  
begin catch   
 SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
    
 RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )  
  
end catch