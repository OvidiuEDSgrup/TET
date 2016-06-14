--***  
create procedure [dbo].[wScriuPozdoc] @sesiune varchar(50), @parXML xml   
as  
  
declare @tip char(2), @numar char(8), @data datetime, @gestiune char(9), @gestiune_primitoare char(13),   
 @tert char(13), @factura char(20), @data_facturii datetime, @data_scadentei datetime, @lm char(9),  @lmprim char(9),   
 @numar_pozitie int, @cod char(20), @codcodi char(20), @cantitate float, @pret_valuta float, @cod_intrare char(13), @codiPrim varchar(13),  
 @pret_amanunt float, @cota_TVA float, @suma_tva float, @tva_valuta float, @tipTVA int, @comanda char(20), @cont_stoc char(13), @pret_stoc float,   
 @valuta char(3), @curs float, @locatie char(30), @contract char(20), @lot char(13), @data_expirarii datetime, @data_expirarii_stoc datetime,   
 @explicatii char(30), @jurnal char(3), @cont_factura char(13), @discount float, @punct_livrare char(5),   
 @barcod char(30), @cont_corespondent char(13), @DVI char(25), @categ_pret int, @cont_intermediar char(13), @cont_venituri char(13), @TVAnx float,   
 @nume_delegat char(30), @serie_buletin char(10), @numar_buletin char(10), @eliberat_buletin char(30), @mijloc_transport char(30), @nr_mijloc_transport char(20), @data_expedierii datetime, @ora_expedierii char(6), @observatii char(200), @punct_livrare_exp
editie char(5),   
 @IesFaraStoc int, @tipGrp char(2), @numarGrp char(8), @dataGrp datetime, @sir_numere_pozitii varchar(max), @sub char(9), @docXMLIaPozdoc xml,   
 @userASiS varchar(20), @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20), @jurnalProprietate varchar(3),   
 @stare int, @tip_gestiune_filtru_stoc char(1), @tip_nom char(1), @codi_stoc char(13), @stoc float, @cant_desc float, @nr_poz_out int,   
 @eroare xml, @mesaj varchar(254), @Bugetari int, @TabelaPreturi int, @indbug varchar(20), @comanda_bugetari varchar(40), @accizecump float, @ptupdate int,   
 @NrAvizeUnitar int ,@prop1 varchar(20),@prop2 varchar(20),@serie varchar(20),@subtip varchar(2),@termenscadenta int,@Serii int,  
 @zilescadenta int,@facturanesosita bit,@aviznefacturat bit,@CTCLAVRT bit,@ContAvizNefacturat varchar(20),@suprataxe float,@o_suma_TVA float,   
 @rec_factura_existenta char(8), @data_rec_fact_exist datetime, @fetch_crspozdoc int, @TEACCODI int,@text_alfa2 varchar(30),-->campul alfa 2 din text_pozdoc  
 @o_pret_amanunt float,@o_pret_valuta float,@adaos decimal(12,2),@numarpozitii int  
   
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output  
exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''  
exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0, ''  
exec luare_date_par 'GE','PRETURI', @TabelaPreturi output, 0, ''  
exec luare_date_par 'GE', 'SERII', @Serii output, 0, '' -- lucreaza cu serii  
exec luare_date_par 'UC', 'TEACCODI', @TEACCODI output, 0, '' -- TE cu acelasi cod intrare la primitor   
exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output  
  
begin try   
 ---->>>>>>start cod specific prestari pe receptii<<<<<--------------  
set @subtip=ISNULL(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), '')  
if @subtip='RP' and exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPrestariReceptii')--in cazul in care suntem pe subtip specific prestarilor toata treaba se face in procedura wScriuPrestariReceptii  
 exec wScriuPrestariReceptii @sesiune,@parxml --procedura care face repartizarea prestarilor  
   
else  
begin   
 ---->>>>>>stop cod specific prestari pe receptii<<<<<--------------  
 --BEGIN TRAN  
 if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocSP')  
  exec wScriuPozdocSP @sesiune, @parXML output  
   
 -- aceasta apelare se va modifica - se vor folsi proceduri de validare, care vor da direct raiserror.   
 set @eroare = dbo.wfValidarePozdoc(@parXML)  
 if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0  
  begin  
  set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')  
  raiserror(@mesaj, 11, 1)  
  end  
   
 EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT  
   
 select @gestProprietate='', @clientProprietate='', @lmProprietate='', @jurnalProprietate=''  
 select @gestProprietate=(case when cod_proprietate='GESTIUNE' then valoare else @gestProprietate end),   
  @clientProprietate=(case when cod_proprietate='CLIENT' then valoare else @clientProprietate end),   
  @lmProprietate=(case when cod_proprietate='LOCMUNCA' then valoare else @lmProprietate end),   
  @jurnalProprietate=(case when Cod_proprietate='JURNAL' then Valoare else @jurnalProprietate end)  
 from proprietati   
 where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTIUNE', 'CLIENT', 'LOCMUNCA', 'JURNAL') and valoare<>''  
   
 if ISNULL(@stare,'')=''  
  set @stare=3  
    
 exec luare_date_par 'GE', 'FARASTOC', @IesFaraStoc output, 0, ''  
  
 declare @iDoc int  
 EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML  
   
 declare crspozdoc cursor for  
 select tip, upper(numar), data,   
 upper((case when isnull(gestiune_pozitii, '')<>'' then gestiune_pozitii when isnull(gestiune_antet, '')<>'' then gestiune_antet else @gestProprietate end)) as gestiune,   
 (case when isnull(gestiune_primitoare_pozitii, '')<>'' then gestiune_primitoare_pozitii else isnull(gestiune_primitoare_antet, '') end) as gestiune_primitoare,   
 upper((case when isnull(tert, '')<>'' then tert when tip in ('AP', 'AS') then @clientProprietate else '' end)) as tert,   
 upper(isnull(factura_pozitii, isnull(factura_antet, ''))) as factura,   
 isnull(datafact, isnull(data, '01/01/1901')) as datafact, isnull(datascad, isnull(datafact, isnull(data, '01/01/1901'))) as datascad,   
 (case when isnull(lm_pozitii, '')<>'' then lm_pozitii when isnull(lm_antet, '')<>'' then lm_antet else @lmProprietate end) as lm,   
 isnull(lmprim_antet, '') as lmprim,   
 isnull(numar_pozitie, 0) as numar_pozitie, upper(isnull(cod, '')) as cod,  
 upper(isnull(codcodi,isnull(cod,''))) as codcodi,  
 isnull(cantitate, 0) as cantitate, pret_valuta, isnull(tip_TVA,0) as tipTVA,   
   
 zilescadenta as zilescadenta,--zilele de scadenta, data_scadenta se va calcula din zilele de scadenta  
 isnull(facturanesosita,0),--bifa de factura nesosita  
 isnull(aviznefacturat,0),--bifa de aviz nefacturat  
   
 upper(isnull(cod_intrare, '')) as cod_intrare, isnull(pret_amanunt, 0) as pret_amanunt, cota_TVA, suma_TVA, TVA_valuta,   
 upper(case when isnull(comanda_pozitii, '')<>'' then comanda_pozitii else isnull(comanda_antet, '') end) as comanda,   
 (case when isnull(indbug_pozitii, '')<>'' then indbug_pozitii else isnull(indbug_antet, '') end) as indbug,   
 isnull(cont_de_stoc, '') as cont_stoc, isnull(pret_de_stoc, 0) as pret_stoc,   
   
 ---datele, curs si valuta, completate in pozitii sunt mai tari decat cele din antet  
 ---(totusi este recomandata configurarea de introducere curs si valuta din antet)  
 upper(isnull(isnull(valuta,valuta_antet),'')) as valuta,  
 convert(decimal(12,4),isnull(isnull(curs,curs_antet),0)) as curs,   
  
 upper(isnull(locatie, '')) as locatie,  
 upper((case when isnull(contract_pozitii, '')<>'' then contract_pozitii else isnull(contract_antet, '') end)) as [contract],   
 upper(isnull(lot, '')) as lot, isnull(data_expirarii, '01/01/1901'),   
 (case when isnull(explicatii_pozitii, '')<>'' then explicatii_pozitii else isnull(explicatii_antet, '') end) as explicatii,   
 (case when isnull(isnull(jurnal, jurnalantet),'')<>'' then isnull(jurnal, jurnalantet) else @jurnalProprietate end) as jurnal,  
 (case when isnull(cont_factura_pozitii, '')<>'' then cont_factura_pozitii else /*isnull(*/cont_factura_antet/*, '')*/ end) as cont_factura,   
 discount,   
 (case when isnull(punct_livrare_pozitii, '')<>'' then punct_livrare_pozitii else isnull(punct_livrare_antet, '') end) as punct_livrare,   
 isnull(barcod, '') as barcod,   
 (case when isnull(cont_corespondent_pozitii, '')<>'' then cont_corespondent_pozitii when tip in ('AI', 'AE', 'AF') then /*isnull(*/cont_corespondent_antet/*, '')*/ else '' end) as cont_corespondent,   
 isnull(dvi, '') as dvi, isnull(categ_pozitii, isnull(categ_antet, 0)) as categ_pret,   
 /*isnull(*/cont_intermediar/*, '')*/ as cont_intermediar,   
 isnull((case when isnull(cont_venituri_pozitii, '')<>'' then cont_venituri_pozitii else /*isnull(*/cont_venituri_antet/*, '')*/ end),'') as cont_venituri,   
 isnull(tva_neexigibil_pozitii, tva_neexigibil_antet) as tva_neexigibil,   
 isnull(accizecump, 0) as accizecump,   
 upper(isnull(nume_delegat, '')) as nume_delegat, upper(isnull(serie_buletin, '')) as serie_buletin,   
 isnull(numar_buletin, '') as numar_buletin, upper(isnull(eliberat_buletin, '')) as eliberat_buletin,   
 upper(isnull(mijloc_transport, '')) as mijloc_transport, upper(isnull(nr_mijloc_transport, '')) as nr_mijloc_transport,   
 isnull(data_expedierii, data) as data_expedierii, isnull(ora_expedierii, '000000') as ora_expedierii,   
 isnull(observatii, '') as observatii, isnull(punct_livrare_expeditie, '') as punct_livrare_expeditie,   
 isnull(ptupdate,0) as ptupdate ,  
 stare as stare,  
 numarpozitii as numarpozitii,--numar de pozitii din doc, este utilizat in validare unicitate document->sa ramana fara isnull(...)  
   
 --campuri din tabela textpozdoc  
 rtrim(ltrim(text_alfa2)) as text_alfa2,  
   
 --proprietati pt serii  
 isnull(prop1,'') as prop1,  
 isnull(prop2,'') as prop2,  
 isnull(serie,'') as serie,  
 isnull(subtip,'') as subtip,  
 o_suma_TVA,o_pret_valuta,o_pret_amanunt,adaos  
   
 from OPENXML(@iDoc, '/row/row')  
 WITH   
 (  
  tip char(2) '../@tip',   
  numar char(8) '../@numar',  
  data datetime '../@data',  
  gestiune_antet char(9) '../@gestiune',  
  gestiune_primitoare_antet char(13) '../@gestprim',   
  tert char(13) '../@tert',  
  factura_antet char(20) '../@factura',  
  datafact datetime '../@datafacturii',  
  datascad datetime '../@datascadentei',  
  lm_antet char(9) '../@lm',  
  lmprim_antet char(9) '../@lmprim',  
  comanda_antet char(20) '../@comanda',   
  indbug_antet char(20) '../@indbug',   
  cont_factura_antet char(13) '../@contfactura',   
  cont_corespondent_antet char(13) '../@contcorespondent',   
  cont_venituri_antet char(13) '../@contvenituri',   
  explicatii_antet char(30) '../@explicatii',   
  punct_livrare_antet char(5) '../@punctlivrare',  
  categ_antet char(5) '../@categpret',  
  tva_neexigibil_antet float '../@tvaneexigibil',  
  contract_antet char(20) '../@contract',   
  nume_delegat char(30) '../@numedelegat',   
  serie_buletin char(10) '../@seriabuletin',   
  numar_buletin char(10) '../@numarbuletin',   
  eliberat_buletin char(30) '../@eliberat',   
  mijloc_transport char(30) '../@mijloctp',   
  nr_mijloc_transport char(20) '../@nrmijloctp',   
  data_expedierii datetime '../@dataexpedierii',   
  ora_expedierii char(6) '../@oraexpedierii',   
  observatii char(200) '../@observatii',   
  punct_livrare_expeditie char(5) '../@punctlivrareexped',   
  tip_TVA int '../@tiptva',  
  zilescadenta int '../@zilescadenta',--zilele de scadenta->data_scadentei se va calcula din zilele de scadenta  
  facturanesosita bit '../@facturanesosita',--bifa pentru facturi nesosite, dc este pusa atunci contul facturii va fi 408(furnizori-facturi nesosite)  
  aviznefacturat bit '../@aviznefacturat',--bifa pentru avize nefacturate, dc este pusa atunci contul facturii va fi luat din parametrii(cont beneficiari avize nefacturate)  
  jurnalantet char(3) '../@jurnal',   
  ---cursul si valuta din antet  
  valuta_antet varchar(3) '../@valuta' ,   
  curs_antet varchar(14) '../@curs',  
  numarpozitii int '../@numarpozitii',--numar de pozitii din doc, este utilizat in validare unicitate document  
    
  stare smallint '../@stare',  
    
  ---pozitii-----  
  numar_pozitie int '@numarpozitie',  
  cod char(20) '@cod',  
  codcodi char(20) '@codcodi',  
  factura_pozitii char(20) '@factura',  
  cantitate decimal(17, 5) '@cantitate',  
  pret_valuta decimal(14, 5) '@pvaluta',   
  pret_amanunt decimal(14, 5) '@pamanunt',   
  cod_intrare char(13) '@codintrare',    
  cota_TVA decimal(5, 2) '@cotatva',   
  suma_TVA decimal(15, 2) '@sumatva',   
  TVA_valuta decimal(15, 2) '@tvavaluta',   
  gestiune_pozitii char(9) '@gestiune',   
  gestiune_primitoare_pozitii char(13) '@gestprim',   
  lm_pozitii char(9) '@lm',   
  comanda_pozitii char(20) '@comanda',   
  indbug_pozitii char(20) '@indbug',   
  cont_de_stoc char(13) '@contstoc',   
  pret_de_stoc float '@pstoc',   
  valuta char(3) '@valuta',   
  curs float '@curs',   
  locatie char(30) '@locatie',   
  contract_pozitii char(20) '@contract',   
  lot char(13) '@lot',   
  data_expirarii datetime '@dataexpirarii',   
  explicatii_pozitii char(30) '@explicatii',   
  jurnal char(3) '@jurnal',   
  cont_factura_pozitii char(13) '@contfactura',   
  discount float '@discount',   
  punct_livrare_pozitii char(5) '@punctlivrare',   
  barcod char(30) '@barcod',   
  cont_corespondent_pozitii char(13) '@contcorespondent',   
  DVI char(25) '@dvi',  
  categ_pozitii int '@categpret',   
  cont_intermediar char(13) '@contintermediar',   
  cont_venituri_pozitii char(13) '@contvenituri',  
  tva_neexigibil_pozitii float '@tvaneexigibil',  
  accizecump float '@accizecump',   
  ptupdate int '@update' ,  
  adaos decimal(12,2) '@adaos',  
    
  --campuri din tabela textpozdoc  
  text_alfa2 varchar(30) '@text_alfa2',  
    
  ---proprietati pt serii  
  prop1 char(20) '@prop1',  
  prop2 char(20) '@prop2',  
  serie char(20) '@serie',  
  subtip char(20) '@subtip',   
    
  o_suma_TVA decimal(15, 2) '@o_sumatva' ,  
  o_pret_amanunt decimal(14, 5) '@o_pamanunt',  
  o_pret_valuta decimal(14, 5) '@o_pvaluta'  
 )  
  
 open crspozdoc  
 fetch next from crspozdoc into @tip, @numar, @data, @gestiune, @gestiune_primitoare, @tert,   
  @factura, @data_facturii, @data_scadentei, @lm,@lmprim, @numar_pozitie, @cod, @codcodi, @cantitate, @pret_valuta, @tiptva,  
  @zilescadenta,@facturanesosita,@aviznefacturat,  
  @cod_intrare, @pret_amanunt, @cota_tva, @suma_TVA, @TVA_valuta, @comanda, @indbug, @cont_stoc, @pret_stoc,   
  @valuta, @curs, @locatie, @contract, @lot, @data_expirarii, @explicatii, @jurnal, @cont_factura, @discount,   
  @punct_livrare, @barcod, @cont_corespondent, @DVI, @categ_pret, @cont_intermediar, @cont_venituri, @TVAnx,   
  @accizecump, @nume_delegat, @serie_buletin, @numar_buletin, @eliberat_buletin, @mijloc_transport,   
  @nr_mijloc_transport, @data_expedierii, @ora_expedierii, @observatii, @punct_livrare_expeditie, @ptupdate ,@stare,@numarpozitii,  
  @text_alfa2,@prop1,@prop2,@serie,@subtip,@o_suma_TVA,@o_pret_valuta,@o_pret_amanunt,@adaos  
 set @fetch_crspozdoc=@@fetch_status  
 while @fetch_crspozdoc= 0  
 begin  
     
  if year(@data_facturii)<1921  
   set @data_facturii=@data --convert(char(10),GETDATE(),101)  
  if YEAR(@data_scadentei)<1921  
   set @data_scadentei=@data_facturii  
  if @lm=''  
   set @lm=isnull((select max(loc_de_munca) from gestcor where gestiune=@gestiune), '')  
  if @lm=''  
      set @lm =isnull((select max(loc_munca) from infotert where subunitate = @sub and identificator <> '' and tert = @tert), '')  
    
  set @comanda_bugetari=convert(char(20),@comanda)+isnull(@indbug,'')  
  if @tip = 'RN' set @tip = 'RM' -- tratam tipul RN(receptiile care au pe poz cantitate<0) la fel ca tip RM  
    
  --daca pe macheta exista campul zilescadenta atunci datascadentei se calculeaza din zilele scadenta, altfel sa ia campul data scadentei  
  if @zilescadenta is not null   
   set @data_scadentei=DATEADD(day,@zilescadenta,@data)  
    
  if CHARINDEX('|',@codcodi,1)>0 and @codcodi<>@cod  
  begin  
  set @cod=isnull((select substring(@codcodi,1,CHARINDEX('|',@codcodi,1)-1)),@cod)  
  set @cod_intrare=isnull((select substring(@codcodi,CHARINDEX('|',@codcodi,1)+1,LEN(@codcodi))),@cod_intrare)  
  end  
    
  if isnull(@numar, '')=''  
  begin  
   declare @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20)  
   set @tipPentruNr=@tip   
   if @NrAvizeUnitar=1 and @tip='AS'   
    set @tipPentruNr='AP'   
   set @fXML = '<row/>'  
   set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')  
   set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')  
   set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')  
   set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')  
   set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')  
     
   exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output  
     
   if @NrDocPrimit is null  
    raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)  
     
   set @numar=@NrDocPrimit  
  end  
    
  --validare unicitate numar document  
  if @numarpozitii is null and isnull(@numar,'')<>'' and @subtip<>''   
   and exists(select 1 from doc where Subunitate=@sub and tip=@tip and data=@data and numar=@numar)  
   raiserror('Numarul acesta de document exista in baza de date! Daca totusi doriti pastrarea acestui numar, adaugati un . la sfarsitul lui.',11,1)  
    
  --Aici va trebuie regandit un pic conceptul de calcul automat al TVA-ului  
  if @cota_tva is null and  /* (Andrei ...asa a trebuit la arges,am vb cu d-ul Ghita)isnull(@cota_tva,0)=0 and*/ @tip in ('AP', 'AS', 'AC')  
   set @cota_tva=(select max(cota_TVA) from nomencl where cod=@cod)  
    
  if @cota_tva is null and @tip in ('RM','RC','RS') --ar trebui pusa in general indiferent de tip  
   set @cota_tva=(select max(cota_TVA) from nomencl where cod=@cod)  
    
  if @cota_TVA is null  
   set @cota_TVA=0  
  -- gata calcul automat al TVA-ului    
    
    
  if @tip in ('AP', 'AS', 'AC') and (@pret_valuta is null or @pret_valuta=0) -- or @discount is null)  
  begin  
   --set @categ_pret=(case when isnull(@categ_pret,0)=0 then 1 else @categ_pret end)  
   declare @dXML xml, @doc_in_valuta int  
   set @dXML = '<row/>'  
   set @dXML.modify ('insert attribute cod {sql:variable("@cod")} into (/row)[1]')  
   --set @dXML.modify ('insert attribute data {sql:variable("@data")} into (/row)[1]')  
   declare @dstr char(10)  
   set @dstr=convert(char(10),@data,101)     
   set @dXML.modify ('insert attribute data {sql:variable("@dstr")} into (/row)[1]')  
   set @dXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]')  
   set @dXML.modify ('insert attribute comandalivrare {sql:variable("@contract")} into (/row)[1]')  
   set @dXML.modify ('insert attribute categpret {sql:variable("@categ_pret")} into (/row)[1]')  
   set @doc_in_valuta=(case when @valuta<>'' then 1 else 0 end)  
   set @dXML.modify ('insert attribute documentinvaluta {sql:variable("@doc_in_valuta")} into (/row)[1]')  
   if @pret_valuta=0 set @pret_valuta=null  
   exec wIaPretDiscount @dXML, @pret_valuta output, @discount output  
  end  
    
  select @pret_valuta=isnull(@pret_valuta, 0), @discount=isnull(@discount, 0)  
    
  if @tip='DF'  
  begin  
   if isnull(@lm,'')=''set @lm=isnull((select max(Loc_de_munca) from personal where Marca=@gestiune_primitoare),'')  
   if @comanda_bugetari is null or @comanda_bugetari='' set @comanda_bugetari=isnull((select max(Centru_de_cost_exceptie) from infopers where Marca=@gestiune_primitoare),'')  
  end  
  
  if @tip='AF' or @tip='PF'  
  begin  
   if isnull(@lm,'')='' set @lm=isnull((select max(Loc_de_munca) from personal where Marca=@gestiune),'')  
  end  
    
  if @tip in ('RM', 'RS', 'AI', 'TE') and abs(@pret_amanunt)<0.00001  
  begin  
   if isnull(@categ_pret,0)=0  
    set @categ_pret=isnull((select top 1 valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestiune), 0)  
   set @pret_amanunt=isnull((select top 1 pret_cu_amanuntul from preturi where cod_produs=@cod and um=@categ_pret order by data_inferioara desc), 0)  
  end  
    
  if @tip='RM' and @adaos is not null and @adaos>0  
  begin  
   set @pret_amanunt=round(round(@pret_valuta*(100+@adaos)/100,2)*(100+@cota_tva)/100,2)  
   if @parXML.value('(/row/row/@pamanunt)[1]', 'decimal(12,2)') is not null                    
    set @parXML.modify('replace value of (/row/row/@pamanunt)[1] with sql:variable("@pret_amanunt")')                
  
  end  
  
  ---->>>>>>>>>>>>>>>Cod specific lucrului pe serii<<<<<<<<<<<<<<<<<<<----  
  if @subtip='SE' --daca subtipul este 'SE' suntem pe pozitie de serie, si atunci citim date din linie  
   begin     
   set @cod=ISNULL(@parXML.value('(/row/linie/@cod)[1]', 'varchar(20)'), '')  
   set @cod_intrare=isnull(ISNULL(@parXML.value('(/row/linie/@codintrare)[1]', 'varchar(13)'), @parXML.value('(/row/linie/@codintrareS)[1]', 'varchar(13)')),'')  
   set @numar_pozitie=ISNULL(@parXML.value('(/row/linie/@numarpozitie)[1]', 'int'), '')     
   set @pret_valuta=ISNULL(@parXML.value('(/row/linie/@pvalutaS)[1]','float'),0)  
   set @pret_stoc=ISNULL(@parXML.value('(/row/linie/@pstocS)[1]','float'),0)  
   end  
  
  if isnull(@serie,'')='' and (select MAX(um_2) from nomencl where cod=@cod)='Y'---formare serie pe baza celor 2 proprietati---   
   set @serie=(case when @prop1<>'' and @prop2<>'' then rtrim(ltrim(@prop1))+','+RTRIM(ltrim(@prop2))when  @prop1<>'' and @prop2='' then @prop1 else''end)  
    
   ---pt coduri care au acelasi pret de stoc, aceasi gestiune se pastreaza codul de intrare chiar dc au serii diferite (pentru intrari)   
  if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0 and @tip in ('PP','RM')   
     and ISNULL(@cod_intrare,'')=''     
   begin  
       set @cod_intrare=isnull((select max(cod_intrare) from pozdoc where subunitate=@sub and tip=@tip and numar=@Numar and data=@Data   
                                              and gestiune=@Gestiune and cod=@Cod and pret_de_stoc=@pret_stoc  
                                                 and pret_valuta=@pret_valuta  
                                                                ),'')  
       set @numar_pozitie=isnull((select MAX(numar_pozitie) from pozdoc where subunitate=@sub and tip=@tip and numar=@Numar and data=@Data  
                                                 and Cod_intrare=@cod_intrare ),'')    
   end                                                             
  --->>>>>>>>>>>>>>>>>>Sfarsit cod specific lucrului pe serii<<<<<<<<<<<<<<-----------   
    
    
  if @tip='RS' and @DVI=''   
   set @DVI=(select MAX(Denumire) from terti where Subunitate=@sub and tert=@tert)  
  --Accize cumparare = in cazul receptiilor cantitatea de pe factura  
  if @tip in ('RM', 'RC') and @accizecump=0  
   set @accizecump=@cantitate    
    
 /* SET @myDoc.modify('             
insert (              
           attribute SetupHours {".5" },             
           attribute SomeOtherAtt {".2"}             
        )             
into (/Root/Location[@LocationID=10])[1] ');   */  
       
  ----->>>>> start cod formare parametru xml pentru procedurile de scriere documente<<<<-----  
  declare @parXmlScriereIntrari xml,@data_facturiiS char(10),@data_scadenteiS char(10),@data_expirariiS char(10),@dataS char(10)  
  set @dataS=CONVERT(char(10),@data,101)  
  set @data_facturiiS=CONVERT(char(10),@data_facturii,101)  
  set @data_scadenteiS=CONVERT(char(10),@data_scadentei,101)  
  set @data_expirariiS=CONVERT(char(10),isnull(@data_expirarii,@data_expirarii_stoc),101)  
  declare @sumatv decimal(15,4)  
  set @sumatv=convert(decimal(15,4),@suma_tva)  
    
  if isnull(@numar,'')=''   
   raiserror('wScriuPozdoc: Pe acest tip de document nu au fost definite plaje de numere!! ',11,1)  
    
  set @parXmlScriereIntrari = '<row/>'  
  set @parXmlScriereIntrari.modify ('insert   
     (  
     attribute tip {sql:variable("@tip")},  
     attribute subtip {sql:variable("@subtip")},  
     attribute numar {sql:variable("@numar")},  
     attribute data {sql:variable("@dataS")},  
     attribute tert {sql:variable("@tert")},  
     attribute factura {sql:variable("@factura")},  
     attribute data_facturii {sql:variable("@data_facturiiS")},  
     attribute data_scadentei {sql:variable("@data_scadenteiS")},  
     attribute cont_factura {sql:variable("@cont_factura")},  
     attribute gestiune {sql:variable("@gestiune")},  
     attribute gestiune_primitoare {sql:variable("@gestiune_primitoare")},  
     attribute cod {sql:variable("@cod")},  
     attribute cod_intrare {sql:variable("@cod_intrare")},  
     attribute cont_stoc {sql:variable("@cont_stoc")},  
     attribute locatie {sql:variable("@locatie")},  
     attribute cantitate {sql:variable("@cantitate")},  
     attribute valuta {sql:variable("@valuta")},  
     attribute curs {sql:variable("@curs")},  
     attribute pret_valuta {sql:variable("@pret_valuta")},  
     attribute discount {sql:variable("@discount")},  
     attribute pret_amanunt {sql:variable("@pret_amanunt")},  
     attribute pret_stoc {sql:variable("@pret_stoc")},  
     attribute lm {sql:variable("@lm")},  
     attribute comanda_bugetari {sql:variable("@comanda_bugetari")},  
     attribute jurnal {sql:variable("@jurnal")} ,  
     attribute contract {sql:variable("@contract")},  
     attribute DVI {sql:variable("@DVI")},  
     attribute stare {sql:variable("@stare")},  
     attribute barcod {sql:variable("@barcod")},  
     attribute tipTVA {sql:variable("@tipTVA")},  
     attribute data_expirarii {sql:variable("@data_expirariiS")},  
     attribute utilizator {sql:variable("@userASiS")},  
     attribute serie {sql:variable("@serie")},  
     attribute cota_TVA {sql:variable("@cota_TVA")},  
     attribute suma_tva {sql:variable("@suma_tva")},  
     attribute numar_pozitie {sql:variable("@numar_pozitie")},  
     attribute accizecump {sql:variable("@accizecump")},  
     attribute lot {sql:variable("@lot")},  
     attribute cont_corespondent {sql:variable("@cont_corespondent")},  
     attribute cont_venituri {sql:variable("@cont_venituri")},  
     attribute cont_intermediar {sql:variable("@cont_intermediar")},  
     attribute suprataxe {sql:variable("@suprataxe")},  
     attribute update {sql:variable("@ptupdate")},  
     attribute text_alfa2 {sql:variable("@text_alfa2")},  
     attribute explicatii {sql:variable("@explicatii")}  
     )       
     into (/row)[1]')    
 --->>>>stop cod formare parametru xml pentru procedurile de scriere documente<<<<-----  
    
  if @tip in ('RM', 'RS', 'RC')  
      begin  
    if not exists (select 1 from doc where Subunitate=@sub and tip=@tip and cod_tert=@tert and factura=@factura and numar=@numar)   
    begin  
     set @rec_factura_existenta=(select max(numar) from doc where Subunitate=@sub and tip=@tip and cod_tert=@tert and factura=@factura and numar<>@numar)   
     set @data_rec_fact_exist=(select max(data) from doc where Subunitate=@sub and tip=@tip and cod_tert=@tert and factura=@factura and numar=@rec_factura_existenta)   
    end  
    if @facturanesosita=1  
     begin  
      set @cont_factura='408'--daca este pusa bifa de factura nesosita, contul facturii va fi 408 intotdeauna  
      set @parXmlScriereIntrari.modify('replace value of (/row/@cont_factura)[1] with sql:variable("@cont_factura")')  
     end  
    exec wScriuReceptie @parXmlScriereIntrari=@parXmlScriereIntrari  
   end  
    
  if @tip='AI'  
   begin  
    if  isnull(@curs,0)<>0 and ISNULL(@valuta,'')<>'' and ISNULL(@pret_valuta,0)<>0  
     begin  
      set @pret_stoc=@pret_valuta*@curs --se calculeaza pretul de stoc in functie de valuta,curs si pretul valuta  
      set @parXmlScriereIntrari.modify('replace value of (/row/@pret_stoc)[1] with sql:variable("@pret_stoc")')   
     end  
    exec wScriuAI @parXmlScriereIntrari=@parXmlScriereIntrari  
   end  
    
  if @tip='PP'  
   begin   
    if  isnull(@curs,0)<>0 and ISNULL(@valuta,'')<>'' and ISNULL(@pret_valuta,0)<>0  
     begin  
      set @pret_stoc=@pret_valuta*@curs --se calculeaza pretul de stoc in functie de valuta,curs si pretul valuta  
      set @parXmlScriereIntrari.modify('replace value of (/row/@pret_stoc)[1] with sql:variable("@pret_stoc")')   
     end  
    exec wScriuPP @parXmlScriereIntrari=@parXmlScriereIntrari     
   end   
     
  if @tip='AF'  
   begin  
    exec wScriuAF @parXmlScriereIntrari=@parXmlScriereIntrari  
   end  
     
  if @tip in ('CM', 'AP', 'AS', 'AC', 'AE', 'TE', 'DF', 'PF', 'CI')  
  begin  
    
   set @tip_gestiune_filtru_stoc = (case when @tip in ('PF', 'CI') then 'F' else '' end)  
   set @tip_nom=isnull((select tip from nomencl where cod=@cod), '')  
   /*  
   declare  @nStocTotal float  
   select @nStocTotal=SUM(stoc) from stocuri where subunitate=@sub and cod_gestiune=@gestiune and cod=@cod  
   if @IesFaraStoc=0 and  @cantitate>@nStocTotal  
    raiserror('Eroare operare. Operarea acestei pozitii ar genera stoc negativ!',11,1)  
   */  
   declare @CuTranzactii int  
   exec luare_date_par 'GE','TRANZACT', @CuTranzactii output, 0, ''--se citeste parametrul care spune daca se lucreaza cu tanzactii sau nu  
   set @CuTranzactii=ISNULL(@CuTranzactii,0)  
   if @CuTranzactii=1--daca se lucreaza cu tranzactii incepem o tranzactie pentru spargerea pe coduri de intrare  
    Begin transaction SpargereCoduriIntrare  
     
   while abs(@cantitate)>=0.00001  
   begin     
       select @nr_poz_out=@numar_pozitie, @codi_stoc=@cod_intrare, @stoc=@cantitate  
       if @numar_pozitie=0 and @codi_stoc='' and @cantitate>=0.00001 and @tip_nom not in ('R', 'S', 'F')  
    begin  
     exec iauPozitieStoc @Cod=@cod, @TipGestiune=null, @Gestiune=null, @Data=null,   
      @CodIntrare=@codi_stoc output, @PretStoc=null, @Stoc=@stoc output, @ContStoc=null, @DataExpirarii=@data_expirarii_stoc output,   
      @TVAneex=null, @PretAm=null, @Locatie=@locatie output, @Serie=null,   
      @FltTipGest=@tip_gestiune_filtru_stoc, @FltGestiuni=@gestiune, @FltExcepGestiuni=null, @FltData=@data,   
      @FltCont=null, @FltExcepCont=null,   
      @FltDataExpirarii=@data_expirarii, -- daca se trimite ca parametru sa se filtreze dupa el   
      @FltLocatie=@locatie,   
      @FltLM=null, @FltComanda=null, @FltCntr=null, @FltFurn=null, @FltLot=null,   
      @FltSerie=@serie, @OrdCont=null, @OrdGestLista=null  
         set @codi_stoc=isnull(@codi_stoc, '')  
    end  
    set @cant_desc=(case when abs(@cantitate)-abs(@stoc)>=0.00001 then @stoc else @cantitate end)  
    set @cantitate=@cantitate-@cant_desc  
    if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocSP1')  
     exec wScriuPozdocSP1 @tip, @codi_stoc, @gestiune, @cod, @cont_corespondent  output  
       
    if @tip in ('AP', 'AS', 'AC')  
     begin  
      if @factura='' set @factura=null /* va fi completata automat cu nr. documentului in scriuAviz */  
      -- daca suma TVA operata este semnificativ diferita de cea anterior calculata se forteaza recalcularea:   
      -- (@tvavaluta este folosit in macheta de Avize pentru a putea fi modificata Suma TVA)  
      if @ptupdate=1 --and isnull(@tva_valuta,0)=0 and abs(isnull(@suma_tva,0)-isnull(@o_suma_TVA,0))>0.05   
       set @suma_tva=null   
      if @tip<>'AP'  
      begin  
       set @pret_amanunt=(case when @tip in ('AS','AC') and ISNULL(@pret_amanunt,0)>0 then @pret_amanunt else null end)  
       set @pret_valuta=(case when @tip in ('AS','AC') and ISNULL(@pret_valuta,0)>0 then @pret_valuta else isnull(@pret_amanunt,0)/(1.00+@cota_TVA/100) end)  
      end  
      select @categ_pret=sold_ca_beneficiar  
      from terti  
      where @TabelaPreturi=1 and isnull(@categ_pret,0)=0 and @Tert<>'' and subunitate=@sub and tert=@Tert  
      -- sa puna categoria de pret=1 daca era zero (oricum, asa e tratata):  
      set @categ_pret=(case when isnull(@categ_pret,0)=0 then 1 else @categ_pret end)  
      if @data_scadentei is null    
        begin    
         set @termenscadenta=isnull((select discount from infotert where subunitate=@sub and tert=@tert and Identificator=''),0)    
         set @data_scadentei=DATEADD(d,@termenscadenta,@data_facturii)    
        end   
          
      if @aviznefacturat=1 and @tip in ('AP','AS')--daca este pusa bifa pentru aviz nefacturat atunci contul de factura va fi luat din parametrii(cont beneficiar avin nefacturat)  
       set @cont_factura= @ContAvizNefacturat    
     end  
      
    -------------start pt cod formare parametru xml pentru procedurile de scriere iesiri---------  
    declare @parXmlScriereIesiri xml  
    set @dataS=CONVERT(char(10),@data,101)  
    set @data_facturiiS=CONVERT(char(10),@data_facturii,101)  
    set @data_scadenteiS=CONVERT(char(10),@data_scadentei,101)  
    set @data_expirariiS=CONVERT(char(10),isnull(@data_expirarii_stoc,@data_expirarii),101)   
    
    set @parXmlScriereIesiri = '<row/>'  
    set @parXmlScriereIesiri.modify ('insert   
      (  
      attribute tip {sql:variable("@tip")},  
      attribute subtip {sql:variable("@subtip")},  
      attribute numar {sql:variable("@numar")},  
      attribute data {sql:variable("@dataS")},  
      attribute tert {sql:variable("@tert")},  
      attribute punct_livrare {sql:variable("@punct_livrare")},       
      attribute factura {sql:variable("@factura")},  
      attribute data_facturii {sql:variable("@data_facturiiS")},  
      attribute data_scadentei {sql:variable("@data_scadenteiS")},  
      attribute cont_factura {sql:variable("@cont_factura")},  
      attribute gestiune {sql:variable("@gestiune")},  
      attribute cod {sql:variable("@cod")},  
      attribute cod_intrare {sql:variable("@codi_stoc")},  
      attribute codiPrim {sql:variable("@codiPrim")},  
      attribute locatie {sql:variable("@locatie")},  
      attribute cantitate {sql:variable("@cant_desc")},  
      attribute valuta {sql:variable("@valuta")},  
      attribute curs {sql:variable("@curs")},  
      attribute pret_valuta {sql:variable("@pret_valuta")},  
      attribute discount {sql:variable("@discount")},  
      attribute pret_amanunt {sql:variable("@pret_amanunt")},  
      attribute lm {sql:variable("@lm")},  
      attribute comanda_bugetari {sql:variable("@comanda_bugetari")},  
      attribute jurnal {sql:variable("@jurnal")} ,  
      attribute contract {sql:variable("@contract")},  
      attribute stare {sql:variable("@stare")},  
      attribute barcod {sql:variable("@barcod")},  
      attribute tipTVA {sql:variable("@tipTVA")},  
      attribute data_expirarii {sql:variable("@data_expirariiS")},  
      attribute utilizator {sql:variable("@userASiS")},  
      attribute serie {sql:variable("@serie")},  
      attribute cota_TVA {sql:variable("@cota_TVA")},  
      attribute suma_tva {sql:variable("@suma_tva")},  
      attribute numar_pozitie {sql:variable("@nr_poz_out")},  
      attribute cont_corespondent {sql:variable("@cont_corespondent")},  
      attribute cont_stoc {sql:variable("@cont_stoc")},  
      attribute cont_venituri {sql:variable("@cont_venituri")},  
      attribute cont_intermediar {sql:variable("@cont_intermediar")},  
      attribute suprataxe {sql:variable("@suprataxe")},  
      attribute update {sql:variable("@ptupdate")},  
      attribute explicatii {sql:variable("@explicatii")},  
      attribute gestiune_primitoare {sql:variable("@gestiune_primitoare")},  
      attribute TVAnx {sql:variable("@TVAnx")},  
      attribute text_alfa2 {sql:variable("@text_alfa2")},  
      attribute categ_pret {sql:variable("@categ_pret")}  
      )       
      into (/row)[1]')  
     ------------stop pt cod formare parametru xml pentru procedurile de scriere iesiri---------  
       
     if @tip in ('AP', 'AS', 'AC')  
     begin  
      exec wScriuAviz @parXmlScriereIesiri=@parXmlScriereIesiri  
     end  
        
     if @tip='CM'  
      exec wScriuCM @parXmlScriereIesiri=@parXmlScriereIesiri  
       
     if @tip='AE'  
      exec wScriuAE @parXmlScriereIesiri=@parXmlScriereIesiri  
       
     if @tip='TE'  
      exec wScriuTE @parXmlScriereIesiri=@parXmlScriereIesiri  
         
     if @tip='DF'  
      exec wScriuDF @parXmlScriereIesiri=@parXmlScriereIesiri  
       
     if @tip='PF'  
     begin  
      if @Bugetari=1 and isnull(@contract,'')<>'' --daca este unitate bugetara->la predare dubla contarea trebuie sa se faca astfel: 482... - contFolosinta  
      begin  
       set @cont_corespondent=rtrim(isnull((select Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='AN482'),'482'))  
       set @cont_stoc=dbo.formezContStocFol(@Cod)  
       set @parXmlScriereIesiri.modify('replace value of (/row/@cont_corespondent)[1] with sql:variable("@cont_corespondent")')  
       set @parXmlScriereIesiri.modify('replace value of (/row/@cont_stoc)[1] with sql:variable("@cont_stoc")')        
      end  
        
      exec wScriuPF @parXmlScriereIesiri=@parXmlScriereIesiri  
              
      if isnull(@contract,'')<>''--daca se completeaza marca destinatara-> predare dubla(se genereaza si perechea)  
      begin  
       if @Bugetari=1--daca este unitate bugetara contarea pt pereche: cont folosinta-482...  
       begin  
        set @cont_stoc=rtrim(isnull((select Val_alfanumerica from par where Tip_parametru='GE' and  Parametru='AN482'),'482'))  
        set @cont_corespondent=dbo.formezContStocFol(@Cod)  
        set @parXmlScriereIesiri.modify('replace value of (/row/@cont_corespondent)[1] with sql:variable("@cont_corespondent")')  
        set @parXmlScriereIesiri.modify('replace value of (/row/@cont_stoc)[1] with sql:variable("@cont_stoc")')  
       end        
         
       if isnull(@lmprim,'')=''   
        set @lmprim=isnull((select max(Loc_de_munca) from personal where Marca=@contract),'')  
       declare @numarPFpereche varchar(20)  
       set @numarPFpereche='PF'+@numar  
         
       set @parXmlScriereIesiri.modify('replace value of (/row/@numar)[1] with sql:variable("@numarPFpereche")')  
       set @parXmlScriereIesiri.modify('replace value of (/row/@gestiune)[1] with sql:variable("@gestiune_primitoare")')    
       set @parXmlScriereIesiri.modify('replace value of (/row/@gestiune_primitoare)[1] with sql:variable("@contract")')  
       set @parXmlScriereIesiri.modify('replace value of (/row/@lm)[1] with sql:variable("@lmprim")')  
         
       exec wScriuPF @parXmlScriereIesiri=@parXmlScriereIesiri  
      end  
     end  
       
     if @tip='CI'  
      exec wScriuCI @parXmlScriereIesiri=@parXmlScriereIesiri  
      
   end  
   if @CuTranzactii=1--daca se lucreaza cu tranzactii inchidem tranzactia pentru spargerea pe coduri de intrare  
    commit transaction SpargereCoduriIntrare  
     
  end  
  if @numarGrp is null  
   select @tipGrp=@tip, @numarGrp=@numar, @dataGrp=@data, @sir_numere_pozitii=''  
  if not exists (select 1 from anexadoc where subunitate=@sub and tip=@tip and numar=@numar and data=@data and tip_anexa='')  
   insert anexadoc  
   (Subunitate, Tip, Numar, Data, Numele_delegatului, Seria_buletin, Numar_buletin, Eliberat, Mijloc_de_transport, Numarul_mijlocului, Data_expedierii, Ora_expedierii, Observatii, Punct_livrare, Tip_anexa)  
   values  
   (@sub, @tip, @numar, @data, @nume_delegat, @serie_buletin, @numar_buletin, @eliberat_buletin, @mijloc_transport, @nr_mijloc_transport, @data_expedierii, @ora_expedierii, @observatii, @punct_livrare_expeditie, '')  
  
  fetch next from crspozdoc into @tip, @numar, @data, @gestiune, @gestiune_primitoare, @tert,   
   @factura, @data_facturii, @data_scadentei, @lm,@lmprim, @numar_pozitie, @cod, @codcodi, @cantitate, @pret_valuta, @tiptva,  
   @zilescadenta,@facturanesosita,@aviznefacturat,   
   @cod_intrare, @pret_amanunt, @cota_tva, @suma_TVA, @TVA_valuta, @comanda, @indbug, @cont_stoc, @pret_stoc,   
   @valuta, @curs, @locatie, @contract, @lot, @data_expirarii, @explicatii, @jurnal, @cont_factura, @discount,   
   @punct_livrare, @barcod, @cont_corespondent, @DVI, @categ_pret, @cont_intermediar, @cont_venituri, @TVAnx,   
   @accizecump, @nume_delegat, @serie_buletin, @numar_buletin, @eliberat_buletin, @mijloc_transport,   
   @nr_mijloc_transport, @data_expedierii, @ora_expedierii, @observatii, @punct_livrare_expeditie, @ptupdate,@stare,@numarpozitii,  
   @text_alfa2,@prop1,@prop2,@serie,@subtip,@o_suma_TVA,@o_pret_valuta,@o_pret_amanunt,@adaos  
  set @fetch_crspozdoc=@@fetch_status   
 end  
 -------------------Start Modificari bugetari-------------------------    
 if @Bugetari='1'   
 begin  
   
    declare @comBug char(40), @cont_corBug char(13), @contBug char(13), @cont_venBug char(13), @numar_pozBug int, @lmBug char(9)              
    --cursor pentru parcurgerea pozdoc   
    declare pozitii_fara_indicator cursor                        
    for select distinct p.cont_corespondent,p.cont_de_stoc,p.cont_venituri, p.comanda,p.loc_de_munca, p.numar_pozitie  
    from pozdoc p   
    where p.subunitate=@sub and p.tip=@tip and p.numar=@numar and p.data=@data and substring(rtrim(p.comanda),21,20)=''                
     
    open pozitii_fara_indicator                        
    fetch next from pozitii_fara_indicator   
      into @cont_corBug, @contBug, @cont_venBug, @comBug, @lmBug, @numar_pozBug   
  declare @fetch_pozitii_fara_indicator int  
  set @fetch_pozitii_fara_indicator=@@fetch_status  
    while  @fetch_pozitii_fara_indicator= 0  --and substring(rtrim(@comBug),21,20)=''          
  begin   
   if @tip in ('AP','AS')  
    exec wFormezIndicatorBugetar @Cont=@cont_venBug,@Lm=@lmBug,@Indbug=@indbug output    
   if @tip in ('CM','DF','CI')  
    exec wFormezIndicatorBugetar @Cont=@cont_corBug,@Lm=@lmBug,@Indbug=@indbug output    
   if @tip in ('RM','RS') and left(@contBug,1)='6'   
    exec wFormezIndicatorBugetar @Cont=@contBug,@Lm=@lmBug,@Indbug=@indbug output    
   set @comanda_bugetari=left(@comBug,20)+@indbug    
     
   --setare context info pentru completare indicator bugetar pe documente definitive  
   declare @binar varbinary(128)  
   set @binar=cast('specificebugetari' as varbinary(128))  
   set CONTEXT_INFO @binar         
     
   update pozdoc set comanda=@comanda_bugetari   
    where subunitate=@sub and tip=@tip and data=@data and numar=@numar and numar_pozitie=@numar_pozBug   
           
         set CONTEXT_INFO 0x00  
         fetch next from pozitii_fara_indicator    
      into @cont_corBug,@contBug,@cont_venBug, @comBug,@lmBug, @numar_pozBug   
    set @fetch_pozitii_fara_indicator=@@fetch_status  
    end   
    close pozitii_fara_indicator                       
    deallocate pozitii_fara_indicator              
 end   
 --------------------Stop Modificari Bugetari---------------------------  
   
 if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozdocSP2')      
  exec wScriuPozdocSP2 '', @sub, @tipGrp, @numarGrp, @dataGrp,@parXML    
  
 set @docXMLIaPozdoc = '<row subunitate="' + rtrim(@sub) + '" tip="' + rtrim(@tipGrp) + '" numar="' + rtrim(@numarGrp) + '" data="' + convert(char(10), @dataGrp, 101) +'"/>'  
 exec wIaPozdoc @sesiune=@sesiune, @parXML=@docXMLIaPozdoc   
 if @rec_factura_existenta is not null  
  select 'Acest numar de factura exista pe receptia '+RTRIM(@rec_factura_existenta)+' din '+CONVERT(char(10),@data_rec_fact_exist,103)+'!' as textMesaj for xml raw, root('Mesaje')  
  
 --COMMIT TRAN  
end  
end try  
begin catch  
 --ROLLBACK TRAN  
 if @CuTranzactii=1--daca se lucreaza cu tranzactii si exista deschisa tranzactia de spargere coduri dam rollback  
  and EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'SpargereCoduriIntrare')              
  ROLLBACK TRAN SpargereCoduriIntrare  
 set @mesaj =ERROR_MESSAGE()+' (wScriuPozdoc)'  
end catch  
  
begin try   
declare @cursorStatus int  
set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='crspozdoc' and session_id=@@SPID )  
if @cursorStatus=1   
 close crspozdoc   
if @cursorStatus is not null   
 deallocate crspozdoc   
end try   
begin catch end catch  
  
begin try   
 exec sp_xml_removedocument @iDoc   
end try   
begin catch end catch  
  
if len(@mesaj)>0  
begin  
 raiserror(@mesaj, 11, 1)  
end