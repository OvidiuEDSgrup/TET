--***  
create procedure wScriuPozCon @sesiune varchar(50), @parXML xml   
as   
declare @tip char(2), @contract char(20), @data datetime, @gestiune char(9), @gestiune_primitoare char(13),   
 @tert char(13), @factura char(20), @termen datetime, @termene datetime, @o_termene datetime, @data1 datetime, @lm char(9), @modplata char(8), @o_modplata char(8),  
 @info1_antet char(13), @info2_antet float, @info3_antet float, @info4_antet float, @info5_antet float, @info6_antet char(20),   
 @numar_pozitie int, @cod char(20), @o_cod char(20), @cantitate float, @cant_aprobata float, @Tcantitate float, @cantitate_UM1 float, @cantitate_UM2 float, @cantitate_UM3 float,   
 @cod_intrare char(13), @cota_TVA float, @pret float, @Tpret float, @valuta char(3), @curs float, @explicatii char(50), @discount float, @punct_livrare char(5),   
 @categ_pret int, @lot char(200), @data_expirarii datetime, @obiect varchar(20),   
 @info1_pozitii float, @info2_pozitii char(13), @info3_pozitii float, @info4_pozitii char(200), @info5_pozitii char(13),   
 @info6_pozitii datetime, @info7_pozitii datetime, @info8_pozitii float, @info9_pozitii float, @info10_pozitii float, @info11_pozitii float,   
 @info12_pozitii varchar(200), @info13_pozitii varchar(200), @info14_pozitii varchar(200), @info15_pozitii varchar(200), @info16_pozitii varchar(200), @info17_pozitii varchar(200),   
 @tipGrp char(2), @numarGrp char(20), @tertGrp char(20), @dataGrp datetime, @sir_numere_pozitii varchar(max),   
 @sub char(9), @CantAprob0BKBP int, @TermPeSurse int, @docXMLIaPozContract xml, @userASiS varchar(20),   
 @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20),  
 @stare char(1), @tip_gestiune_filtru_stoc char(1), @tip_nom char(1), @subtip char(2),   
 @eroare xml,@mesajj varchar(20),@contclient varchar(20),@procpen float,@update int,@Ttermen datetime,  
 @Gluni int, @nr int, @scadenta int , @periodicitate int,@explicatii_pozitii varchar(50),@mesaj varchar(200),  
 @contr_cadru varchar(50),@ext_camp4 varchar(50),@ext_camp5 datetime,@ext_modificari varchar(50),@ext_clauze varchar(500),@gestdepozitBK varchar(20),  
 @T1 float,@T2 float,@T3 float,@T4 float,@T5 float,@T6 float,@T7 float,@T8 float,  
 @T9 float,@T10 float,@T11 float,@T12 float,@jurnal varchar(20),@detalii xml,  @docDetalii xml,   
 @MULTICDBK int, -->setarea care permite operarea BK/BP cu acelasi cod pe mai multe pozitii  
 @inchiriere int -->setarea care identifica cazul cu cantitatea constanta (ex. suprafata)  
  
begin try  
 --BEGIN TRAN  
    
  set @eroare = dbo.wfValidareContract(@parXML)  
  begin  
   set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')  
   if @mesaj<>''  
   raiserror(@mesaj, 11, 1)  
  end   
   
 if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuConSP')  
 begin  
  exec wScriuConSP @sesiune=@sesiune, @parXML=@parXML output  
  select 'Atentie: se apeleaza procedura wScriuConSP din procedura wScriuPozCon. Contactati implementatorul aplicatiei pt. a '+  
   'corecta functionarea aplicatiei(apelare wScriuPozConSP).' as textMesaj, 'Functionare nerecomandata' as titluMesaj  
  for xml raw,root('Mesaje')  
 end  
   
 if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuContractSP')  
 begin  
  exec wScriuContractSP @sesiune=@sesiune, @parXML=@parXML output  
  select 'Atentie: se apeleaza procedura wScriuContractSP din procedura wScriuPozCon. Contactati implementatorul aplicatiei pt. a '+  
   'corecta functionarea aplicatiei(apelare wScriuPozConSP).' as textMesaj, 'Functionare nerecomandata' as titluMesaj  
  for xml raw,root('Mesaje')  
 end  
   
 if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozConSP')  
  exec wScriuPozConSP @sesiune=@sesiune, @parXML=@parXML output  
   
 select @update = isnull(@parXML.value('(/row/row/@update)[1]','int'),0),  
   @Ttermen = isnull(@parXML.value('(/row/row/@Ttermen)[1]','datetime'),''),  
   @gestProprietate='', @clientProprietate='', @lmProprietate='',@gestdepozitBK='',  
   @jurnal =isnull(@parXML.value('(/row/@jurnal)[1]','varchar(20)'),'')  
   
 select @sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @sub end),  
   @CantAprob0BKBP=isnull((case when Parametru='CNAZBKBP' then Val_logica else @CantAprob0BKBP end),0),  
   @TermPeSurse=isnull((case when Parametru='POZSURSE' then Val_logica else @TermPeSurse end),0),  
   @MULTICDBK=isnull((case when Parametru='MULTICDBK' and Tip_parametru='UC' then Val_logica else @MULTICDBK end),0),  
   @inchiriere=isnull((case when Parametru='CHIRIE' and Tip_parametru='UC' then Val_logica else @inchiriere end),0)  
 from par  
 where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='UC' and Parametru in ('CNAZBKBP','POZSURSE','MULTICDBK','CHIRIE'))  
  
 declare @lCuTermene bit  
 select @lCuTermene=Val_logica from par where tip_parametru='UC' and parametru='TERMCNTR'    
   
 EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT  
   
   
 select @gestProprietate=(case when cod_proprietate='GESTBK' then valoare else isnull(@gestProprietate,'') end),   
  @clientProprietate=(case when cod_proprietate='CLIENT' then valoare else isnull(@clientProprietate,'') end),   
  @lmProprietate=(case when cod_proprietate='LOCMUNCA' then valoare else isnull(@lmProprietate,'') end),  
  @gestdepozitBK=(case when cod_proprietate='GESTDEPBK' then valoare else isnull(@gestdepozitBK,'') end)  
 from proprietati   
 where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTBK', 'CLIENT', 'LOCMUNCA','GESTDEPBK') and valoare<>''  
   
 set @stare=0  
 declare @iDoc int  
 EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML  
   
 declare crspozcon cursor for  
 select detalii,tip, upper([contract]), data,   
 upper((case when isnull(gestiune_pozitii, '')<>'' then gestiune_pozitii when isnull(gestiune_antet, '')<>'' then gestiune_antet else ''/*@gestProprietate*/ end)) as gestiune,   
 upper(isnull(gestiune_primitoare, '')) as gestiune_primitoare,   
 upper((case when isnull(tert, '')<>'' then tert when tip in ('BF', 'BK', 'BP') then ''/*@clientProprietate*/ else '' end)) as tert,   
 upper(isnull(factura, '')) as factura,   
 --extcon  
 isnull(contclient,'') as contclient,  
 isnull(procpen,'') as procpen,  
 isnull(contr_cadru,'') as contr_cadru,  
 isnull(ext_camp4,'') as ext_camp4,  
 isnull(ext_camp5,'1901-01-01') as ext_camp5,  
 isnull(ext_modificari,'') as ext_modificari,  
 isnull(ext_clauze,'') as ext_clauze,  
   
 isnull(termen_pozitii, isnull(termen_antet, data)) as termen,   
 isnull(subtip, tip) as subtip,   
 isnull(scadenta,0) as scadenta,  
 --termene  
 isnull(termene, data) as termene,  
 isnull(o_termene, '') as o_termene,  
 isnull(data1,data) as data1,  
   
 upper(case when isnull(lm,'')<>'' then lm else @lmProprietate end) as lm,   
 isnull(info1_antet, '') as info1_antet, isnull(info2_antet, 0) as info2_antet, isnull(info3_antet, 0) as info3_antet,   
 isnull(info4_antet, 0) as info4_antet, isnull(info5_antet, 0) as info5_antet, isnull(info6_antet, '') as info6_antet,   
 isnull(numar_pozitie, 0) as numar_pozitie, upper(isnull(cod, '')) as cod, isnull(o_cod,'') as o_cod,   
 isnull(cantitate, 0) as cantitate,   
 isnull(cant_aprobata, 0) as cant_aprobata,   
   
 --termene  
 isnull(Tcantitate, 0) as Tcantitate,  
 isnull(cantitate_UM1, 0) as cantitate_UM1, isnull(cantitate_UM2, 0) as cantitate_UM2, isnull(cantitate_UM3, 0) as cantitate_UM3,   
 pret,   
   
 --termene  
 Tpret,  
   
 cota_TVA,   
 upper(isnull(valuta, '')) as valuta, isnull(curs, 0) as curs, isnull(explicatii_pozitii,'')as explicatii_pozitii, upper(isnull(explicatii,'')) as explicatii,   
 discount, isnull(punct_livrare, '') as punct_livrare, upper(isnull(modplata, '')) as modplata, isnull(o_modplata,'') as o_modplata,   
 isnull(categ_pret,0) as categ_pret,   
 upper(isnull(lot, '')) as lot, isnull(data_expirarii, '01/01/1901') as data_expirarii, isnull(obiect, '') as obiect,   
 isnull(info1_pozitii, 0) as info1_pozitii, isnull(info2_pozitii, '') as info2_pozitii,   
 isnull(info3_pozitii, 0) as info3_pozitii, isnull(info4_pozitii, '') as info4_pozitii, isnull(info5_pozitii, '') as info5_pozitii,   
 --isnull(info6_pozitii, '01/01/1901') as info6_pozitii,   
 --isnull(info7_pozitii, '01/01/1901') as info7_pozitii,   
 isnull(info8_pozitii, 0) as info8_pozitii, isnull(info9_pozitii, 0) as info9_pozitii, isnull(info10_pozitii, 0) as info10_pozitii, isnull(info11_pozitii, 0) as info11_pozitii, isnull(info12_pozitii, '') as info12_pozitii, isnull(info13_pozitii, '') as in
fo13_pozitii, isnull(info14_pozitii, '') as info14_pozitii, isnull(info15_pozitii, '') as info15_pozitii, isnull(info16_pozitii, '') as info16_pozitii, isnull(info17_pozitii, '') as info17_pozitii,   
 isnull(Gluni,0) as Gluni, isnull(periodicitate,0) as periodicitate  
    
 from OPENXML(@iDoc, '/row/row')   
 WITH   
 (  
  detalii xml '../detalii',  
  tip char(2) '../@tip',   
  [contract] char(20) '../@numar',  
  data datetime '../@data',  
  gestiune_antet char(9) '../@gestiune',  
  gestiune_primitoare char(13) '../@gestprim',   
  tert char(13) '../@tert',  
  punct_livrare char(5) '../@punctlivrare',   
  modplata char(8) '@modplata',   
  o_modplata char(8) '@o_modplata',   
  factura char(20) '../@factura',  
  --extcon  
  contclient varchar(10) '../@contclient',  
  procpen varchar(10) '../@procpen',  
  contr_cadru varchar(50) '../@contr_cadru',  
  ext_camp4 varchar(50) '../@ext_camp4',  
  ext_camp5 datetime '../@ext_camp5',  
  ext_modificari varchar(50) '../@ext_modificari',  
  ext_clauze varchar(500)'../@ext_clauze',  
    
    
  termen_antet datetime '../@termen',  
  termen_pozitii datetime '@termen',  
  subtip char(2) '@subtip',  
  scadenta int '../@scadenta',   
    
  --termene  
  termene datetime '@termene',  
  o_termene datetime '@o_termene',  
    
  data1 datetime '@data1',  
    
  lm char(9) '../@lm',  
  explicatii char(50) '../@explicatii',   
  info1_antet char(13) '../@info1',   
  info2_antet float '../@info2',   
  info3_antet float '../@info3',   
  info4_antet float '../@info4',   
  info5_antet float '../@info5',   
  info6_antet char(20) '../@info6',   
  numar_pozitie int '@numarpozitie',  
  cod char(20) '@cod',  
  o_cod char(20) '@o_cod',  
  cantitate decimal(17, 5) '@cantitate',  
  cant_aprobata decimal(17, 5) '@cant_aprobata',  
    
  --termene  
  Tcantitate decimal(17, 5) '@Tcantitate',  
  cantitate_UM1 decimal(17, 5) '@cantitateum1',  
  cantitate_UM2 decimal(17, 5) '@cantitateum2',  
  cantitate_UM3 decimal(17, 5) '@cantitateum3',  
  cota_TVA decimal(5, 2) '@cotatva',   
  gestiune_pozitii char(9) '@gestiune',   
  pret float '@pret',   
    
  --termene  
  Tpret float '@Tpret',  
    
  valuta char(3) '../@valuta',   
  curs float '@curs',   
  discount float '@discount',   
  categ_pret int '@categpret',   
  lot char(200) '@lot',   
  data_expirarii datetime '@dataexpirarii',   
  obiect varchar(20) '@obiect',   
  explicatii_pozitii char(200) '@explicatii',   
  info1_pozitii float '@info1',   
  info2_pozitii char(13) '@info2',   
  info3_pozitii float '@info3',   
  info4_pozitii char(200) '@info4',   
  info5_pozitii char(13) '@info5',   
  --info6_pozitii datetime '@info6',   
  --info7_pozitii datetime '@info7',   
  info8_pozitii float '@info8',   
  info9_pozitii float '@info9',   
  info10_pozitii float '@info10',   
  info11_pozitii float '@info11',   
  info12_pozitii varchar(200) '@info12',   
  info13_pozitii varchar(200) '@info13',   
  info14_pozitii varchar(200) '@info14',   
  info15_pozitii varchar(200) '@info15',   
  info16_pozitii varchar(200) '@info16',   
  info17_pozitii varchar(200) '@info17',  
  Gluni int '@Gluni',  
  periodicitate int '@periodicitate'  
 )   
  
 open crspozcon  
 fetch next from crspozcon into @detalii, @tip, @contract, @data, @gestiune, @gestiune_primitoare,   
  @tert, @factura,  @contclient,@procpen,@contr_cadru,@ext_camp4,@ext_camp5,@ext_modificari ,@ext_clauze, @termen, @subtip,   
  @scadenta,  
  --termene  
  @termene, @o_termene,@data1,   
    
  @lm, @info1_antet, @info2_antet, @info3_antet, @info4_antet, @info5_antet, @info6_antet,   
  @numar_pozitie, @cod, @o_cod, @cantitate, @cant_aprobata,   
    
  --termene  
  @Tcantitate,   
    
  @cantitate_UM1, @cantitate_UM2, @cantitate_UM3,   
  @pret,   
    
  --termene  
  @Tpret,  
    
  @cota_tva, @valuta, @curs,@explicatii_pozitii, @explicatii, @discount, @punct_livrare, @modplata,@o_modplata, @categ_pret,   
  @lot, @data_expirarii, @obiect, @info1_pozitii, @info2_pozitii, @info3_pozitii, @info4_pozitii, @info5_pozitii,   
  --@info6_pozitii, @info7_pozitii,   
  @info8_pozitii, @info9_pozitii, @info10_pozitii, @info11_pozitii,   
  @info12_pozitii, @info13_pozitii, @info14_pozitii, @info15_pozitii, @info16_pozitii, @info17_pozitii,   
  @Gluni, @periodicitate  
  
 while @@fetch_status = 0  
 begin   
  if @tip in ('BF', 'BK', 'BP') and @tert=''   
  begin  
   set @tert=@clientProprietate-- in caz ca nu s-a introdus tert se ia tertul din propietati  
  end  
  if @categ_pret=0  
   set @categ_pret=isnull((select max(sold_ca_beneficiar) from terti where tert=@tert), 1)  
  if @categ_pret=0  
   set @categ_pret=isnull((select top 1 valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestProprietate), 1)  
  
  if @tip in ('BF', 'BK', 'BP')   
  begin  
   if @gestiune='' and (@gestdepozitBK<>'')   
    set @gestiune=@gestdepozitBK  
     
   -- daca documentul care se opereaza are tert si nu se completeaza punctul de livrare al tertului, pun automat primul.  
   if @tert<>'' and @punct_livrare=''  
    set @punct_livrare=isnull((select top 1 rtrim(identificator) from infotert where Subunitate=@sub and tert=@tert and identificator<>''),'')  
     
   if @gestiune_primitoare='' and (@gestiune='' or @gestiune<>@gestProprietate)   
    set @gestiune_primitoare=@gestProprietate  
  end  
    
  if @gestiune='' and (@tip not in ('BF', 'BK', 'BP') or @gestiune_primitoare='' or @gestiune_primitoare<>@gestProprietate)   
   set @gestiune=@gestProprietate  
    
  if @cod='' and @explicatii_pozitii!='' --Incercam sa luam codul din nomenclatorul special  
  begin  
   select top 1 @cod=cod   
   from nomspec where tert=@tert and Cod_special=@explicatii_pozitii  
   if @cod is null  
    set @cod=''  
  end  
  if @cantitate=0  
   select @cantitate=@cantitate_UM1+@cantitate_UM2*(case when UM_1<>'' then Coeficient_conversie_1 else 0 end)+@cantitate_UM3*(case when UM_2<>'' then Coeficient_conversie_2 else 0 end) from nomencl where cod=@cod  
    
  if @lm='' or @lm is null  
   set @lm=isnull((select max(loc_de_munca) from gestcor where gestiune=@gestiune), '')  
    
  if @cota_tva is null   
   set @cota_TVA=ISNULL((select max(cota_tva) from nomencl where cod=@cod),24)   
    
  if isnull(@contract, '')=''--daca nu s-a introdus numar de contract se ia urmatorul numar din plaja  
  begin  
   declare @fXML xml, @NrDocPrimit varchar(20)  
     
   set @fXML = '<row/>'  
   set @fXML.modify ('insert attribute codMeniu {"CO"} into (/row)[1]')  
   set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')  
   set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')  
   set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')  
   set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')  
     
   exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output  
     
   if ISNULL(@NrDocPrimit, '')<>''  
    set @contract=LTrim(RTrim(CONVERT(char(8), @NrDocPrimit)))  
   if isnull(@contract, '')=''  
   begin  
    declare @ParUltNr char(9), @UltNr int  
    set @ParUltNr='NRCNT' + @tip  
    exec luare_date_par 'UC', @ParUltNr, '', @UltNr output, 0  
    while @UltNr=0 or exists (select 1 from con where subunitate=@Sub and tip=@tip and contract=rtrim(ltrim(convert(char(9), @UltNr))))  
     set @UltNr=@UltNr+1  
    set @contract=rtrim(ltrim(convert(char(9), @UltNr)))  
    exec setare_par 'UC', @ParUltNr, null, null, @UltNr, null  
   end  
  end  
    
  if @tip in ('BK', 'BP') and (isnull(@pret,0)=0 or isnull(@discount,0)=0)  
  begin  
   declare @dXML xml, @doc_in_valuta int, @iaupretamanunt int  
   set @dXML = '<row/>'  
   set @dXML.modify ('insert attribute cod {sql:variable("@cod")} into (/row)[1]')  
   declare @dstr char(10)  
   set @dstr=convert(char(10),@data,101)     
   set @dXML.modify ('insert attribute data {sql:variable("@dstr")} into (/row)[1]')  
   set @dXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]')  
   set @dXML.modify ('insert attribute categpret {sql:variable("@categ_pret")} into (/row)[1]')  
   set @doc_in_valuta=(case when @valuta<>'' then 1 else 0 end)  
   set @dXML.modify ('insert attribute documentinvaluta {sql:variable("@doc_in_valuta")} into (/row)[1]')  
   set @iaupretamanunt=(case when exists (select 1 from gestiuni where Subunitate=@sub and Cod_gestiune=@gestiune_primitoare and Tip_gestiune in ('A','V')) then 1 else 0 end)  
   set @dXML.modify ('insert attribute iaupretamanunt {sql:variable("@iaupretamanunt")} into (/row)[1]')  
   if @pret=0 set @pret=null  
   exec wIaPretDiscount @dXML, @pret output, @discount output  
  end    
  select @pret=isnull(@pret, 0), @discount=isnull(@discount, 0)  
    
  if not exists (select 1 from con where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub) and @update=0  
  begin  
   if @tip in ('BF','FA')   
    if (@tert='' or @tert is null)   
     raiserror('Nu se poate adauga contract fara completare tert!', 11, 1)  
     
   if exists(select 1 from con where Contract=@contract and tip=@tip and (YEAR(data)=YEAR(@data) or @tip='BF'))   
    raiserror('Numarul acesta de contract a fost deja introdus!', 11, 1)  
     
   
  
   insert con --insert in con antetul de contract  
    (Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Stare, Loc_de_munca, Gestiune, Termen, Scadenta,   
    Discount, Valuta, Curs, Mod_plata, Mod_ambalare, Factura, Total_contractat, Total_TVA,   
    Contract_coresp, Mod_penalizare, Procent_penalizare, Procent_avans, Avans,   
    Nr_rate, Val_reziduala, Sold_initial, Cod_dobanda, Dobanda,   
    Incasat, Responsabil, Responsabil_tert, Explicatii, Data_rezilierii)  
   select @Sub, @tip, @contract, @tert, @punct_livrare, @data, '0', @lm, @gestiune, @termen, @scadenta,   
    (case when @tip in ('BF', 'FA') then @Discount else @info5_antet end), @Valuta, @Curs, '', '', @Factura, 0, 0,   
    '', @info1_antet, @info4_antet, 0, 0,   
    0, @info2_antet, @info3_antet, @gestiune_primitoare, @categ_pret as dobanda,   
    0, @info6_antet, (case when @tip in ('BF', 'FA') then '' else @info6_antet end), @explicatii, '1/1/1901'  
      
    set @docDetalii= (select 'con' as tabel, @contract contract, @tip tip, @tert tert, @data data, @sub subunitate, @detalii  
    for xml raw )  
    exec wScriuDetalii @parXML=@docDetalii  
  end  
    
  --scriere in extcon  
  if not exists (select 1 from extcon where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub and Numar_pozitie=1)  
   insert extcon   
    (Subunitate,Tip,Contract,Tert,Data,Numar_pozitie,Precizari,Clauze_speciale,Modificari,Data_modificari,Descriere_atasament,  
    Atasament,Camp_1,Camp_2,Camp_3,Camp_4,Camp_5,Utilizator,Data_operarii,Ora_operarii)         
       select @Sub,@tip, @contract , @tert, @data,1,'','','',@ext_clauze,@ext_modificari,'',@contclient,@procpen,@contr_cadru,@ext_camp4,@ext_camp5,@userASiS,  
    convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', ''))  
    
  --eroare pentru cazul in care se fac modificari pe contracte/comenzi care nu sunt in stare de operare  
  if ISNULL((select max(stare) from con where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub), '0')<>'0'  
   raiserror('Contractul/comanda nu e in starea 0-Operat', 11, 1)  
  
  --->>>>>>>>>>START cod specific lucrului pe termene, valabil numai in cazul contractelor BF<<<<<<<<<<---  
  if @tip in ('BF') /*and @lCuTermene=1*/ --cod specific lucrului cu termene(numai BF)  
  begin  
   if (@tert='' or @tert is null)   
    raiserror('Nu se poate adauga contract fara completare tert!', 11, 1)  
   if @subtip='BA'   
    return   
        
   if isnull(@numar_pozitie,0)=0 --se ia numarul de pozitie urmator  
    set @numar_pozitie=isnull((select max(numar_pozitie) from pozcon where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub),0)+1  
     
   if isnull(@pret,0)=0--daca nu s-a introdus pret se ia pretul din nomenclator  
    set @pret=(select max(Pret_vanzare) from nomencl where Cod=@cod)  
   if isnull(@Tpret,0)=0 --daca nu am valoare pentru pretul pozitiei  
    set @Tpret=@pret   
   set @pret=(case when @inchiriere=1 then @pret else @Tpret end)  
   set @cantitate=(case when @inchiriere=1 then @cantitate else @Tcantitate end)  
     
   -- daca suntem in mod adaugare si nu exista pozitie deja cu acelasi cod se face adaugare pozitie in pozcon  
   if not exists (select 1 from pozcon where subunitate=@sub and tip=@tip and contract=@contract and tert=@tert   
    and data=@data and cod=@cod and (@TermPeSurse=0 or mod_de_plata=@modplata)   
    and /*modificat sa adauge pozitie noua dc are explicatii diferite pt APE-Andrey*/ Explicatii=@explicatii_pozitii)   
    and @update=0 and @subtip<>'TE'  
    insert pozcon   
     (Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret, Pret_promotional,   
     Discount, Termen, Factura, Cant_disponibila, Cant_aprobata, Cant_realizata, Valuta, Cota_TVA,   
     Suma_TVA, Mod_de_plata, UM, Zi_scadenta_din_luna, Explicatii, Numar_pozitie, Utilizator,   
     Data_operarii, Ora_operarii)  
    values (@Sub, @tip, @contract, @tert, @gestiune_primitoare, @data, @cod,   
     @cantitate, @pret, 0, @Discount, @termen, @gestiune, 0, @cant_aprobata, 0, @valuta, @cota_TVA,   
     0, @modplata, '', 0, @explicatii_pozitii, @numar_pozitie, @userASiS,   
     convert(datetime, convert(char(10), getdate(), 104), 104),   
     RTrim(replace(convert(char(8), getdate(), 108), ':', '')))    
     
   else /*Suntem pe mod modificare(update=1), se va face modificare pozitie si termene aferente cu tratare in functie de subtipul utilizat:  
     GT->subtip care permite generare pozitie impreuna cu termene aferente, cu pozibilitate specificare periodicitate  
     TE->subtip specific exclusiv termenelor  
     BF->subtip specific pozitiilor de contracte,  
      are posibilitatea de definire campuri pt. cantitati corespunzatoare fiecarei luni din an(nu in varianta standard).   
      In functie de cantitatile introduse se pot sterge/genera termene */  
    -- Ghita, 29.06.2012: acest subptip este pentru Cristi Vlase, se va separa intr-o procedura specifica  
    if @update=1 and @subtip='BF'-->daca suntem pe tip BF(descris mai sus)  
    begin  
     if exists(select 1 from pozcon where subunitate=@sub and contract=@contract and tert=@tert   
      and data=@data and (cod=@cod or cod=@o_cod)and Cant_realizata=0)--daca pozitia nu a fost facturata se fac modificari pe pozitia de pozcon  
     begin       
       /*Silviu:formez numar pozitie atunci cand vreau sa modific sursa altfel primesc un numar de pozitie nou dupa noua sursa  
       si nu  poate sa faca update la cantitate*/  
      update pozcon set pret=@pret, Mod_de_plata=@modplata, cod=@cod  
       where subunitate=@sub and tip=@tip and contract=@contract   
        and tert=@tert and data=@data and numar_pozitie=@numar_pozitie--and cod=@o_cod  
            
      if @TermPeSurse=0/*in cazul in care nu se lucreaza cu surse pe termene se face modificare si pe codul din termene(dc se lucreaza cu   
        surse, atunci termene.cod=pozcon.numar_pozitie, deci nu mai trebuie modificat codul pe termene)*/   
      begin  
       update termene set cod=@cod   
       where subunitate=@Sub and tip=@tip and contract=@contract   
        and tert=@tert and data=@data and cod=@o_cod  
      end    
        
      --se fac si modificarile corespunzatoare pe termenele aferente pozitiei din pozncon  
      update termene set Pret=@Tpret   
      where subunitate=@Sub and tip=@tip and contract=@contract   
       and tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and pret=0   
        
      if @TermPeSurse=1--daca se lucreaza cu surse pe termene  
      begin  
       /*se citesc cantitatile corespunzatoare fiecarei luni din an din campurile de pe @subtip=BF*/  
       set @T1=isnull(@parXML.value('(/row/row/@Tianuarie)[1]','float'),'')  
       set @T2=isnull(@parXML.value('(/row/row/@Tfebruarie)[1]','float'),'')  
       set @T3=isnull(@parXML.value('(/row/row/@Tmartie)[1]','float'),'')  
       set @T4=isnull(@parXML.value('(/row/row/@Taprilie)[1]','float'),'')  
       set @T5=isnull(@parXML.value('(/row/row/@Tmai)[1]','float'),'')  
       set @T6=isnull(@parXML.value('(/row/row/@Tiunie)[1]','float'),'')  
       set @T7=isnull(@parXML.value('(/row/row/@Tiulie)[1]','float'),'')  
       set @T8=isnull(@parXML.value('(/row/row/@Taugust)[1]','float'),'')  
       set @T9=isnull(@parXML.value('(/row/row/@Tseptembrie)[1]','float'),'')  
       set @T10=isnull(@parXML.value('(/row/row/@Toctombrie)[1]','float'),'')  
       set @T11=isnull(@parXML.value('(/row/row/@Tnoiembrie)[1]','float'),'')  
       set @T12=isnull(@parXML.value('(/row/row/@Tdecembrie)[1]','float'),'')         
          
       declare @termenelocal datetime, @cantitatelocal float  
         
       declare crstermene cursor for /*cursor prin care se face update la termene in conformitate cu cantitatile introduse pt fiecare luna,  
         daca cantitatea introdusa pe o anumita luna este 0, atunci se sterge termenul corespunzator lunei respective*/   
         --<Andrei>: nu inteleg de ce este nevoie de cursor      
       select termen, cantitate from termene   
       where subunitate=@Sub and tip=@tip and contract=@contract   
        and tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end)  
       open crstermene   
       fetch next from crstermene into @termenelocal, @cantitatelocal  
       while @@FETCH_STATUS=0  
       begin  
        update termene set Cantitate=(case when month(@termenelocal)='1'  then @T1  
                 when month(@termenelocal)='2'  then @T2   
                 when month(@termenelocal)='3'  then @T3  
                 when month(@termenelocal)='4'  then @T4  
                 when month(@termenelocal)='5'  then @T5  
                 when month(@termenelocal)='6'  then @T6  
                 when month(@termenelocal)='7'  then @T7  
                 when month(@termenelocal)='8'  then @T8  
                 when month(@termenelocal)='9'  then @T9  
                 when month(@termenelocal)='10' then @T10  
                 when month(@termenelocal)='11' then @T11  
                 when month(@termenelocal)='12' then @T12  
                 else @cantitatelocal  
                 end)  
        where subunitate=@Sub and tip=@tip and contract=@contract and  
         tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and   
         Termen=@termenelocal  
          
        delete from termene where subunitate=@Sub and tip=@tip and contract=@contract and  
         tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end) and   
         Termen=@termenelocal and abs(cantitate)<'0.00001'  
        fetch next from crstermene into @termenelocal, @cantitatelocal  
       end  
       close crstermene  
       deallocate crstermene   
      end  
     end      
     else --in cazul in care de pe aceasta pozitie s-a facturat, se returneaza mesaj de eroare  
      raiserror('De pe acest cod s-a facturat, operatie de modificare pret/sursa/cod nepermisa!',16,1)  
     
  
    /* Pentru toate cantitatile care au fost introduse pe subtipul BF, pentru care nu exista termen generat, se genereaza termen corespunzator.*/  
    if exists(select 1 from pozcon where subunitate=@sub and contract=@contract and tert=@tert   
                 and data=@data and (cod=@cod or cod=@o_cod)and Cant_realizata=0)  
    begin  
     declare @count int, @termenVerificare datetime  
     set @count=0  
     IF OBJECT_ID('tempdb..#termeneLunaOrizontal') IS NOT NULL  
      drop table #termeneLunaOrizontal  
       
     select convert(float,@T1) as T1, @T2 as T2, @T3 as T3,@T4 as T4,@T5 as T5 ,  
       @T6 as T6,@T7 as T7,@T8 as T8,@T9 as T9 ,@T10 as T10,  
       @T11 as T11,@T12 as T12  
       into #termeneLunaOrizontal  
       
     declare @termeneLunaVertical table (valoare varchar(20))  
     insert into @termeneLunaVertical  
     SELECT Orders  
     FROM   
      (SELECT T1, T2, T3, T4, T5, T6, T7, T8, T9,T10,T11,T12  
       FROM #termeneLunaOrizontal) AS p  
      UNPIVOT  
      (Orders FOR Employee IN   
       (T1, T2, T3, T4, T5, T6, T7, T8, T9,T10,T11,T12)  
     )AS unpvt  
       
     declare @valoare float  
     declare verificareTermene cursor for   
     select valoare from @termeneLunaVertical   
     open verificareTermene  
     fetch next from verificareTermene into @valoare  
     while @@FETCH_STATUS=0  
     begin  
        
      set @termenVerificare=(select dateadd(month,@count,dbo.EOM(dbo.BOY(getdate()))))  
      set @count=@count+1  
      if @valoare>0 and not exists (select 1 from termene where subunitate=@Sub and tip=@tip and contract=@contract  
               and tert=@tert and data=@data   
               and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end)   
               and month(termen)=@count)  
      begin  
       insert termene (Subunitate, Tip, Contract, Tert, Cod,   
          Data, Termen, Cantitate, Cant_realizata, Pret, Explicatii,  Val1, Val2, Data1, Data2)  
       values (@sub, @tip, @contract, @tert, (case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end),   
          @data, @termenVerificare,@valoare, 0 , @Tpret, '', 0,0,'','01/01/1901')  
      end  
      fetch next from verificareTermene into @valoare  
     end  
     close verificareTermene  
     deallocate verificareTermene   
    end  
   end   
   -- GT=subtip de generare pozitie si termene aferente cu periodicitate(lunar, bilunar...etc)  
   -- exista 2 variante:   
    -- @inchiriere=0 <=> generare termene pentru pret constant si cantitate cumulata pe pozitie (APE)  
    -- @inchiriere=1 <=> generare termene pentru cantitate constanta (DRDP)  
   if @subtip='GT'   
   begin  
    set @nr=0   
    select @Tcantitate = (case when @periodicitate<3 then @cantitate/convert(float,@periodicitate) else @cantitate*convert(float,@periodicitate) end),  
     @Tpret = @pret  
    if @inchiriere=1  
     select @Tcantitate = @cantitate   
      --, @Tpret = -- modul de calcul pret pe termen, prin impartire tarif din pozcon la numar "rate"  
      --case when (@periodicitate = '1') then round(@pret/@Gluni,2)  
      --when (@periodicitate = '2') then round(@pret/@Gluni/2,2)  
      --when (@periodicitate = '3') then case when (@Gluni < 3) then @pret else round(@pret/(@Gluni/3),2) end  
      --when (@periodicitate = '6') then case when (@Gluni < 6) then @pret else round(@pret/(@Gluni/6),2) end  
      --when (@periodicitate = '12') then case when (@Gluni < 12) then @pret else round(@pret/(@Gluni/12),2) end             
      --else @pret             
      --end  
    /*Generare termene conform periodicitatii si numarului de luni introduse pe macheta*/  
    while @nr<@Gluni*(case when isnull(@periodicitate,1)<3 then isnull(@periodicitate,1) else 1 end)  
    begin  
     if isnull(@periodicitate,1) in ('1','2')  
      set @nr=@nr+1  
     else if isnull(@periodicitate,1) in ('3','6','12')  
      set @nr=@nr+@periodicitate  
     if @periodicitate=2 and convert(float,@nr)/2=convert(int,convert(float,@nr)/2) -- numar par  
      set @termene=DATEADD(day,14,dbo.BOM(@termene))  
     else if @periodicitate in ('3','6','12')  
     begin      
      if not exists(select 1 from termene where  subunitate=@sub and tip=@tip and contract=@contract   
         and tert=@tert and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end)   
         and data=@data)  
       set @termene=@termene  
      else --if @nr>@Gluni and (@nr-@Gluni)<@periodicitate  
       set @termene=dateadd(month,@periodicitate,dbo.BOM(convert(varchar(20),@termene,101)))   
      /*else   
       set @termene=dateadd(month,abs(@nr-@periodicitate),dbo.BOM(@termene))*/  
     end  
     else  
      set @termene=dbo.EOM(@termene)  
     if not exists (select 1 from termene where subunitate=@sub and tip=@tip and contract=@contract   
      and tert=@tert and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end)   
      and Termen=@termene and data=@data)  
      insert termene (Subunitate, Tip, Contract, Tert, Cod, Data, Termen,   
       Cantitate, Cant_realizata, Pret, Explicatii,  Val1, Val2, Data1, Data2)  
      values (@sub, @tip, @contract, @tert, (case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end),   
       @data, @termene, @Tcantitate, 0 , @Tpret, '', 0,0,'','01/01/1901')  
     if isnull(@periodicitate,1)=1 or convert(float,@nr)/2=convert(int,convert(float,@nr)/2) and @periodicitate not in ('3','6','12') -- numar par  
      set @termene=DATEADD(MONTH,1,dbo.BOM(@termene))  
    end   
   end  
   else   
   begin  
    if @subtip='TE'-->subtip specific termenelor(adaugare,modificare termene in cadrul unei pozitii de contract<pozcon>)  
    begin  
     if @update=0--adaugare termen nou in cadrul unei pozitii de contract  
     begin  
      /* In cazul in care suntem pe subtip='TE' si in adaugare, se presupune ca utilizatorul a selectat o pozitie pe care doreste sa adauge un termen,   
      deci citim datele pozitiei selectate. Daca nu primim date in <linie>, atunci returnam eroare*/  
      declare @cod_linie varchar(20),@mod_de_plata_linie varchar(8),@numar_pozitie_linie int  
      set @cod_linie=isnull(@parXML.value('(/row/linie/@cod)[1]','varchar(20)'),'')  
      set @mod_de_plata_linie=isnull(@parXML.value('(/row/linie/@modplata)[1]','varchar(8)'),'')  
      set @numar_pozitie_linie=isnull(@parXML.value('(/row/linie/@numarpozitie)[1]','int'),'')  
      select @numar_pozitie=@numar_pozitie_linie,@cod=@cod_linie, @modplata=@mod_de_plata_linie  
        
      if ISNULL(@cod_linie,'')='' or (isnull(@numar_pozitie_linie,0)=0)-->utilizatorul nu a selectat o pozitie de contract pe care doreste sa adauge termen  
       raiserror('Pentru adaugarea unui termen trebuie sa selectati mai intai o pozitie!',11,1)  
       
      --in cazul in care nu exista deja un termen pe pozitia de pozcon selectata cu aceasi data, se adauga termenul dorit, in caz contrar se returneaza eroare  
      if not exists (select 1 from termene where subunitate=@Sub and tip=@tip and contract=@contract   
       and tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod_linie else ltrim(str(@numar_pozitie_linie)) end)   
       and Termen=@termene) --and pret=@pret)  
        insert termene   
        (Subunitate, Tip, Contract, Tert, Cod, Data, Termen,   
        Cantitate, Cant_realizata, Pret, Explicatii,  Val1, Val2, Data1, Data2)  
       values (@Sub, @tip, @contract, @tert, (case when @TermPeSurse=0 then @cod_linie else ltrim(str(@numar_pozitie_linie)) end), @data, @termene,   
        @Tcantitate, 0 , @Tpret, '', 0,0,@data1,'01/01/1901')  
      else  
       raiserror('Exista deja un termen pentru aceasta data!',16,1)  
         
     end  
     else--modificare termen  
      --daca de pe termenul pe care se doreste sa se faca modificarea s-a facturat,se returneaza mesaj de eroare, altfel se face modificarea dorita  
      if exists (select 1 from termene where Subunitate=@sub and tip=@tip and contract=@contract   
       and tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end)   
       and Termen=@o_termene and cant_realizata=0)  
         
       update Termene set Cantitate=@Tcantitate, Pret=@Tpret , Termen=@termene  
       where Subunitate=@sub and tip=@tip and contract=@contract   
        and tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end)   
        and  Termen=@o_termene  
      else   
       raiserror('De pe acest termen s-a facturat, operatie de modificare cantitate/pret nepermisa!',16,1)       
       
    end  
   end   
     
   --reglare cantitate din pozcon, conform modificarilor din termene->doar BF-uri  
   if @inchiriere=0 -- altfel ramane cantitatea citita  
    set @cantitate=isnull((select SUM(round(cantitate,5)) from Termene where subunitate=@Sub and tip=@tip   
     and contract=@contract and tert=@tert and data=@data and cod=(case when @TermPeSurse=0 then @cod else ltrim(str(@numar_pozitie)) end)),0)  
   update pozcon set cantitate=@cantitate,   
    termen=@termene,-- Pret=ISNULL(@pret,@Tpret),   
    utilizator=@userASiS, data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104),  
    ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')) ,  
    --mod_de_plata=@modplata,  
    Explicatii=@explicatii_pozitii  
     where subunitate=@sub and tip=@tip and contract=@contract and tert=@tert and data=@data and Numar_pozitie=@numar_pozitie  
    --and cod=@cod /*and (@TermPeSurse=0 or mod_de_plata=@modplata)*//*modificat sa nu faca update dc are explicatii diferite pt APE-Andrey*/and Explicatii=@explicatii_pozitii  
  end  
  --->>>>>>>>>> STOP cod specific lucrului pe termene, numai contracte BF<<<<<<<<<---  
    
    
  else -- BK,FA,FC -> nu se lucreaza cu termene  
  begin   
   if (@tert='' or @tert is null) and (@gestiune_primitoare='' or @gestiune_primitoare is null)   
    raiserror('Nu se poate adauga comanda/contract fara completare tert sau gest. primitoare!', 11, 1)   
     
   if isnull(@numar_pozitie,0)=0   
    set @numar_pozitie=isnull((select max(numar_pozitie) from pozcon where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate=@Sub),0)+1  
   else   
   begin  
    delete from pozcon where tip=@tip and contract=@contract and tert=@tert and data=@data and subunitate in (@Sub, 'EXPAND', 'EXPAND2') and numar_pozitie=@numar_pozitie  
    delete detpozcon where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data and numar_pozitie=@numar_pozitie and numar_ordine in (0, 1)  
   end  
   --Daca se lucreaza cu mai multe pozitii pe cod sa dea mesaj de eroare la comenzi la adaugarea aceluiasi cod-pret.  
   if @MULTICDBK=1 and @TermPeSurse=0 and @tip in ('BK','FC')  
    and exists (select 1 from pozcon where Subunitate=@sub and tip=@tip and data=@data and Contract=@contract and tert=@tert and cod=@cod and pret=@pret and Numar_pozitie<>@numar_pozitie)  
   begin  
    raiserror('Cu setarile actuale nu se pot introduce mai multe pozitii cu acelasi cod-pret pe o singura comanda!', 11, 1)   
   end  
   --Daca nu se lucreaza cu mai multe pozitii pe cod sa dea mesaj de eroare la comenzi la adaugarea aceluiasi cod.  
   if @MULTICDBK=0 and @TermPeSurse=0 and @tip in ('BK','FC')  
    and exists (select 1 from pozcon where Subunitate=@sub and tip=@tip and data=@data and Contract=@contract and tert=@tert and cod=@cod and Numar_pozitie<>@numar_pozitie)  
   begin  
    raiserror('Cu setarile actuale nu se pot introduce mai multe pozitii cu acelasi cod pe o singura comanda!', 11, 1)   
   end  
     
   if @cantitate<>0  
   begin  
    insert pozcon   
     (Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret, Pret_promotional, Discount,   
     Termen, Factura, Cant_disponibila, Cant_aprobata, Cant_realizata, Valuta, Cota_TVA,   
     Suma_TVA, Mod_de_plata, UM,   
     Zi_scadenta_din_luna, Explicatii, Numar_pozitie, Utilizator, Data_operarii, Ora_operarii)  
    select @Sub, @tip, @contract, @tert, @gestiune_primitoare, @data,   
     @cod, @cantitate, @pret, 0, @Discount, @termen, @gestiune, 0,   
     (case when @CantAprob0BKBP=1 and @tip in ('BK', 'BP') then 0 else @cant_aprobata end), 0, @valuta, @cota_TVA,   
     round(@pret*@Cota_TVA/100.00*@cantitate*(1.00 - @Discount / 100.00),2), @modplata, '',        0, @explicatii_pozitii, @numar_pozitie, @userASiS,   
     convert(datetime, convert(char(10), getdate(), 104), 104),   
     RTrim(replace(convert(char(8), getdate(), 108), ':', ''))  
   end    
  end  
  
  if @tip not in ('BF', 'FA') and @cantitate<>0 and (@lot<>'' or @data_expirarii>'01/01/1901') or @info1_pozitii<>0 or @info2_pozitii<>'' or @info3_pozitii<>0  
   insert pozcon   
   (Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret,   
    Pret_promotional, Discount, Termen,   
    Factura, Cant_disponibila, Cant_aprobata, Cant_realizata, Valuta, Cota_TVA, Suma_TVA, Mod_de_plata, UM,   
    Zi_scadenta_din_luna, Explicatii, Numar_pozitie, Utilizator, Data_operarii, Ora_operarii)  
   select 'EXPAND', @tip, @contract, @tert, @info2_pozitii, @data, @cod, @info3_pozitii, @info1_pozitii,   
    0, 0, (case when @tip not in ('BF', 'FA') then @data_expirarii else '01/01/1901' end),   
    '', 0, 0, 0, '', 0, 0, '', '',   
    0, (case when @tip not in ('BF', 'FA') then @lot else '' end), @numar_pozitie, '', '01/01/1901', '000000'  
    
  if @info4_pozitii<>'' or @info5_pozitii<>''  
   insert pozcon   
   (Subunitate, Tip, Contract, Tert, Punct_livrare, Data, Cod, Cantitate, Pret, Pret_promotional, Discount, Termen,   
    Factura, Cant_disponibila, Cant_aprobata, Cant_realizata, Valuta, Cota_TVA, Suma_TVA, Mod_de_plata, UM,   
    Zi_scadenta_din_luna, Explicatii, Numar_pozitie, Utilizator, Data_operarii, Ora_operarii)  
   select 'EXPAND2', @tip, @contract, @tert, @info5_pozitii, @data, @cod, 0, 0, 0, 0, '01/01/1901',   
    '', 0, 0, 0, '', 0, 0, '', '',   
    0, @info4_pozitii, @numar_pozitie, '', '01/01/1901', '000000'  
    
  if @tip not in ('BF', 'FA') and (@obiect<>'' or @info6_pozitii>'01/01/1901' or @info7_pozitii>'01/01/1901' or @info8_pozitii<>0 or @info9_pozitii<>0 or @info12_pozitii<>'' or @info13_pozitii<>'' or @info14_pozitii<>'')  
   insert detpozcon  
   (Subunitate, Tip, Contract, Tert, Data, Numar_pozitie, Numar_ordine,   
    Obiect, Punct_livrare, Comanda, Versiune, Stare, Termen, Data_inceput, Data_sfarsit, Garantie,   
    Observatii, Val1, Val2, Data1, Data2, Info1, Info2)  
   select @Sub, @tip, @contract, @tert, @data, @numar_pozitie, 0,   
    @obiect, '', '', 0, '', '01/01/1901', '01/01/1901', '01/01/1901', '',  
    @info12_pozitii, @info8_pozitii, @info9_pozitii, @info6_pozitii, @info7_pozitii, @info13_pozitii, @info14_pozitii  
    
  if @tip not in ('BF', 'FA') and (@info10_pozitii<>0 or @info11_pozitii<>0 or @info15_pozitii<>'' or @info16_pozitii<>'' or @info17_pozitii<>'')  
   insert detpozcon  
   (Subunitate, Tip, Contract, Tert, Data, Numar_pozitie, Numar_ordine,   
    Obiect, Punct_livrare, Comanda, Versiune, Stare, Termen, Data_inceput, Data_sfarsit, Garantie,   
    Observatii, Val1, Val2, Data1, Data2, Info1, Info2)  
   select @Sub, @tip, @contract, @tert, @data, @numar_pozitie, 1,   
    '', '', '', 0, '', '01/01/1901', '01/01/1901', '01/01/1901', '',  
    @info15_pozitii, @info10_pozitii, @info11_pozitii, '01/01/1901', '01/01/1901', @info16_pozitii, @info17_pozitii  
    
  if @numarGrp is null  
   select @tipGrp=@tip, @numarGrp=@contract, @tertGrp=@tert, @dataGrp=@data, @sir_numere_pozitii=''  
    
  if @tip in ('FA') and @tip=@tipGrp and @contract=@numarGrp and @tert=@tertGrp and @data=@dataGrp  
   set @sir_numere_pozitii = @sir_numere_pozitii + (case when @sir_numere_pozitii<>'' then ';' else '' end) + ltrim(str(@numar_pozitie))  
    
    
  -->pt FA,BK,FC-uri cantitatile si valorile din con se vor calcula din pozcon  
  update con set Total_contractat=p.total_contractat,Total_TVA=p.total_tva  
  from   
   (select isnull(SUM(round(cantitate*pret*(1.00 - discount / 100.00),2)),0) as total_contractat,  
     isnull(SUM(round(Suma_TVA,2)),0) as total_tva  
     from pozcon  
     where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data) p  
  where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data and @tip<>'BF'  
    
  -->pt BF-uri cantitatile si valorile din con se vor calcula din termene  
  update con set Total_contractat=p.total_contractat,Total_TVA=p.total_tva  
  from   
   (select isnull(SUM(round(t.cantitate*t.pret*(1.00 - p1.discount / 100.00),2)),0) as total_contractat,  
     isnull(SUM(round(p1.Suma_TVA,2)),0) as total_tva  
     from pozcon p1  
      inner join termene t on p1.subunitate=@Sub and p1.tip=@tip and p1.contract=@contract and p1.tert=@tert and p1.data=@data   
       and t.Subunitate=p1.Subunitate and t.Tip=p1.tip and t.Contract=p1.Contract and t.Tert=p1.Tert   
       and t.cod=(case when @TermPeSurse=0 then p1.cod else ltrim(str(p1.Numar_pozitie)) end)       
     where p1.subunitate=@Sub and p1.tip=@tip and p1.contract=@contract and p1.tert=@tert and p1.data=@data) p  
  where subunitate=@Sub and tip=@tip and contract=@contract and tert=@tert and data=@data and @tip='BF'  
  
   
 fetch next from crspozcon into @detalii, @tip, @contract, @data, @gestiune, @gestiune_primitoare,   
  @tert, @factura,  @contclient,@procpen,@contr_cadru,@ext_camp4,@ext_camp5,@ext_modificari ,@ext_clauze,@termen, @subtip,   
  @scadenta,  
  --termene  
  @termene, @o_termene,@data1,    
    
  @lm, @info1_antet, @info2_antet, @info3_antet, @info4_antet, @info5_antet, @info6_antet,   
  @numar_pozitie, @cod, @o_cod, @cantitate, @cant_aprobata,   
    
  --termene  
  @Tcantitate,   
    
  @cantitate_UM1, @cantitate_UM2, @cantitate_UM3,   
  @pret,   
    
  --termene  
  @Tpret,  
    
  @cota_tva, @valuta, @curs, @explicatii_pozitii,@explicatii, @discount, @punct_livrare, @modplata, @o_modplata, @categ_pret,   
  @lot, @data_expirarii, @obiect, @info1_pozitii, @info2_pozitii, @info3_pozitii, @info4_pozitii, @info5_pozitii,   
  --@info6_pozitii, @info7_pozitii,   
  @info8_pozitii, @info9_pozitii, @info10_pozitii, @info11_pozitii,   
  @info12_pozitii, @info13_pozitii, @info14_pozitii, @info15_pozitii, @info16_pozitii, @info17_pozitii,   
  @Gluni, @periodicitate  
 end  
    
 if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozConSP2')  
  exec wScriuPozConSP2 @sesiune=@sesiune, @parXML=@parXML  
  
 set @docXMLIaPozContract = '<row subunitate="' + rtrim(@sub) + '" tip="' + rtrim(@tipGrp)   
  + '" numar="' + rtrim(@numarGrp) + '" tert="' + rtrim(@tertGrp) + '" data="' + convert(char(10), @dataGrp, 101)+'"/>'  
 exec wIaPozCon @sesiune=@sesiune, @parXML=@docXMLIaPozContract   
   
 --COMMIT TRAN  
end try  
begin catch  
 --ROLLBACK TRAN  
 --if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0  
  --set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'  
 set @mesaj = ERROR_MESSAGE()+'(wScriuPozCon)'  
end catch  
--  
declare @cursorStatus int  
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crspozcon' and session_id=@@SPID )  
if @cursorStatus=1   
 close crspozcon   
if @cursorStatus is not null   
 deallocate crspozcon   
--  
begin try   
 exec sp_xml_removedocument @iDoc   
end try   
begin catch end catch  
  
if ISNULL(@mesaj,'')!=''  
 raiserror(@mesaj, 11, 1)  