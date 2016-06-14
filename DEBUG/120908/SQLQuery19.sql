--***  
create procedure wScriuPozConSP @sesiune varchar(50), @parXML xml output   
as   
declare @tip char(2), @contract char(20), @data datetime, @gestiune char(9), @gestiune_primitoare char(13),   
 @tert char(13), @factura char(20), @termen datetime, @termene datetime, @data1 datetime, @lm char(9), @modplata char(8), @o_modplata char(8),  
 @info1_antet char(13), @info2_antet float, @info3_antet float, @info4_antet float, @info5_antet float, @info6_antet char(20),   
 @numar_pozitie int, @cod char(20), @o_cod char(20), @cantitate float, @Tcantitate float, @cantitate_UM1 float, @cantitate_UM2 float, @cantitate_UM3 float,   
 @cod_intrare char(13), @cota_TVA float, @pret float, @Tpret float, @valuta char(3), @curs float, @explicatii char(50), @discount float, @punct_livrare char(5),   
 @categ_pret int, @lot char(200), @data_expirarii datetime, @obiect varchar(20),   
 @info1_pozitii float, @info2_pozitii char(13), @info3_pozitii float, @info4_pozitii char(200), @info5_pozitii char(13),   
 @info6_pozitii datetime, @info7_pozitii datetime, @info8_pozitii float, @info9_pozitii float, @info10_pozitii float, @info11_pozitii float,   
 @info12_pozitii varchar(200), @info13_pozitii varchar(200), @info14_pozitii varchar(200), @info15_pozitii varchar(200), @info16_pozitii varchar(200), @info17_pozitii varchar(200),   
 @tipGrp char(2), @numarGrp char(20), @tertGrp char(20), @dataGrp datetime, @sir_numere_pozitii varchar(max),   
 @sub char(9), @CantAprob0BKBP int, @TermPeSurse int, @docXMLIaPozContract xml, @userASiS varchar(20),   
 @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20),  
 @categPretProprietate varchar(20), @stare char(1), @tip_gestiune_filtru_stoc char(1), @tip_nom char(1), @subtip char(2),   
 @eroare xml,@mesajj varchar(20),@contclient varchar(20),@procpen float,@update int,@Ttermen datetime,  
 @Gluni int, @nr int, @scadenta int , @periodicitate int,@explicatii_pozitii varchar(50),@mesaj varchar(200),  
 @contr_cadru varchar(50),@ext_camp4 varchar(50),@ext_camp5 datetime,@ext_modificari varchar(50),@ext_clauze varchar(500),@gestdepozitBK varchar(20),  
 @T1 float,@T2 float,@T3 float,@T4 float,@T5 float,@T6 float,@T7 float,@T8 float,  
 @T9 float,@T10 float,@T11 float,@T12 float,@jurnal varchar(20),  
 @MULTICDBK int-->setarea care permite operarea BK/BP cu acelasi cod pe mai multe pozitii  
  
begin try  
 --BEGIN TRAN  
    
  set @eroare = dbo.wfValidareContract(@parXML)  
  begin  
   set @mesaj = @eroare.value('(/error/@msgeroare)[1]', 'varchar(255)')  
   if @mesaj<>''  
   raiserror(@mesaj, 11, 1)  
  end   
   
 --if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuConSP')  
 --begin  
 -- exec wScriuConSP @sesiune=@sesiune, @parXML=@parXML output  
 -- select 'Atentie: se apeleaza procedura wScriuConSP din procedura wScriuPozCon. Contactati distribuitorul aplicatiei pt. a '+  
 --  'corecta functionarea aplicatiei(apelare wScriuPozConSP).' as textMesaj, 'Functionare nerecomandata' as titluMesaj  
 -- for xml raw,root('Mesaje')  
 --end  
   
 if exists (select 1 from sysobjects where [type]='P' and [name]='yso_wScriuPozConSP')  
  exec yso_wScriuPozConSP @sesiune=@sesiune, @parXML=@parXML output  
   
 select @update = isnull(@parXML.value('(/row/row/@update)[1]','int'),''),  
   @Ttermen = isnull(@parXML.value('(/row/row/@Ttermen)[1]','datetime'),''),  
   @gestProprietate='', @clientProprietate='', @lmProprietate='',@gestdepozitBK='',  
   @jurnal =isnull(@parXML.value('(/row/@jurnal)[1]','varchar(20)'),'')  
   
 select @sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @sub end),  
   @CantAprob0BKBP=isnull((case when Parametru='CNAZBKBP' then Val_logica else @CantAprob0BKBP end),0),  
   @TermPeSurse=isnull((case when Parametru='POZSURSE' then Val_logica else @TermPeSurse end),0),  
   @MULTICDBK=isnull((case when Parametru='MULTICDBK' and Tip_parametru='UC' then Val_logica else @MULTICDBK end),0)  
 from par  
 where (Tip_parametru='GE' and Parametru ='SUBPRO') or (Tip_parametru='UC' and Parametru in ('CNAZBKBP','POZSURSE','MULTICDBK'))  
  
 EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT  
   
   
 select @gestProprietate=(case when cod_proprietate='GESTBK' then valoare else isnull(@gestProprietate,'') end),   
  @clientProprietate=(case when cod_proprietate='CLIENT' then valoare else isnull(@clientProprietate,'') end),   
  @lmProprietate=(case when cod_proprietate='LOCMUNCA' then valoare else isnull(@lmProprietate,'') end),  
  @gestdepozitBK=(case when cod_proprietate='GESTDEPBK' then valoare else isnull(@gestdepozitBK,'') end)  
 from proprietati   
 where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate in ('GESTBK', 'CLIENT', 'LOCMUNCA','GESTDEPBK') and valoare<>''  
   
 set @stare=0  
 set @categPretProprietate=isnull((select max(sold_ca_beneficiar) from terti where tert=@clientProprietate), 0)  
 if @categPretProprietate=0  
  set @categPretProprietate=isnull((select top 1 valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestProprietate), 1)  
 declare @iDoc int  
 EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML  
   
 declare crspozconsp cursor for  
 select tip, upper([contract]), data,   
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
 isnull(data1,data) as data1,  
   
 upper(case when isnull(lm,'')<>'' then lm else @lmProprietate end) as lm,   
 isnull(info1_antet, '') as info1_antet, isnull(info2_antet, 0) as info2_antet, isnull(info3_antet, 0) as info3_antet,   
 isnull(info4_antet, 0) as info4_antet, isnull(info5_antet, 0) as info5_antet, isnull(info6_antet, '') as info6_antet,   
 isnull(numar_pozitie, 0) as numar_pozitie, upper(isnull(cod, '')) as cod, isnull(o_cod,'') as o_cod,   
 isnull(cantitate, 0) as cantitate,   
 --termene  
 isnull(Tcantitate, 0) as Tcantitate,  
 isnull(cantitate_UM1, 0) as cantitate_UM1, isnull(cantitate_UM2, 0) as cantitate_UM2, isnull(cantitate_UM3, 0) as cantitate_UM3,   
 pret,   
   
 --termene  
 Tpret,  
   
 cota_TVA,   
 upper(isnull(valuta, '')) as valuta, isnull(curs, 0) as curs, isnull(explicatii_pozitii,'')as explicatii_pozitii, upper(isnull(explicatii,'')) as explicatii,   
 discount, isnull(punct_livrare, '') as punct_livrare, upper(isnull(modplata, '')) as modplata, isnull(o_modplata,'') as o_modplata,   
 (case when isnull(categ_pret,0)=0 then @categPretProprietate else isnull(categ_pret,0) end) as categ_pret,   
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
  
 open crspozconsp  
 fetch next from crspozconsp into @tip, @contract, @data, @gestiune, @gestiune_primitoare,   
  @tert, @factura,  @contclient,@procpen,@contr_cadru,@ext_camp4,@ext_camp5,@ext_modificari ,@ext_clauze, @termen, @subtip,   
  @scadenta,  
  --termene  
  @termene, @data1,   
    
  @lm, @info1_antet, @info2_antet, @info3_antet, @info4_antet, @info5_antet, @info6_antet,   
  @numar_pozitie, @cod, @o_cod, @cantitate,   
    
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
  if @tip in ('BF', 'BK', 'BP') and @tert='' set @tert=@clientProprietate  
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
  if @cantitate=0  
   select @cantitate=@cantitate_UM1+@cantitate_UM2*(case when UM_1<>'' then Coeficient_conversie_1 else 0 end)+@cantitate_UM3*(case when UM_2<>'' then Coeficient_conversie_2 else 0 end) from nomencl where cod=@cod  
  if @lm='' or @lm is null  
   set @lm=isnull((select max(loc_de_munca) from gestcor where gestiune=@gestiune), '')  
  if @cota_tva is null   
   set @cota_TVA=ISNULL((select max(cota_tva) from nomencl where cod=@cod),24)   
  --if isnull(@contract, '')=''  
  --begin  
  -- declare @fXML xml, @NrDocPrimit varchar(20)  
     
  -- set @fXML = '<row/>'  
  -- set @fXML.modify ('insert attribute codMeniu {"CO"} into (/row)[1]')  
  -- set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')  
  -- set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')  
  -- set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')  
  -- set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')  
     
  -- exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output  
     
  -- if ISNULL(@NrDocPrimit, '')<>''  
  --  set @contract=LTrim(RTrim(CONVERT(char(8), @NrDocPrimit)))  
  -- if isnull(@contract, '')=''  
  -- begin  
  --  declare @ParUltNr char(9), @UltNr int  
  --  set @ParUltNr='NRCNT' + @tip  
  --  exec luare_date_par 'UC', @ParUltNr, '', @UltNr output, 0  
  --  while @UltNr=0 or exists (select 1 from con where subunitate=@Sub and tip=@tip and contract=rtrim(ltrim(convert(char(9), @UltNr))))  
  --   set @UltNr=@UltNr+1  
  --  set @contract=rtrim(ltrim(convert(char(9), @UltNr)))  
  --  exec setare_par 'UC', @ParUltNr, null, null, @UltNr, null  
  -- end  
  --end  
    
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
   
  if ISNULL(@tert,'')<>'' and isnull(@contr_cadru,'')<>''  
  begin  
   declare @grupa varchar(13)  
     
   select @grupa=n.grupa from nomencl n where n.Cod=@cod  
     
   select top 1 @discount=case   
    when isnull(@discount,0)>0 and isnull(p.Discount,0)>0 then dbo.valoare_minima(@discount,p.Discount,@discount)  
    else ISNULL(@discount,0)+ISNULL(p.Discount,0) end  
   from pozcon p where p.Subunitate= '1' AND p.tip= 'BF' AND p.Contract=@contr_cadru  
   AND p.Tert= @tert and p.Mod_de_plata='G' and @grupa like RTRIM(p.Cod)+'%' order by p.Cod desc, p.Discount desc  
     
   --select top 1 @info1_pozitii=dbo.valoare_minima(@info1_pozitii,p.Pret,@info1_pozitii)  
   -- ,@info3_pozitii=dbo.valoare_minima(@info3_pozitii, p.Cantitate, @info3_pozitii)  
   --from pozcon p where p.Subunitate= 'EXPAND' AND p.tip= 'BF' AND p.Contract=@contr_cadru   
   --AND p.Tert= i.Tert and p.Mod_de_plata='G' and n.Grupa like RTRIM(p.Cod)+'%' order by p.Cod desc, p.Cantitate desc  
  end  
  
  if @tip in ('BK') and isnull(@pret,0)>=0.001  
   and isnull(@discount,0)/*+ISNULL(@info1_pozitii,0)+ISNULL(@info3_pozitii,0)*/>0.001  
  begin  
   declare @discmax float, @grupadiscmax varchar(13), @errdiscmax varchar(max)     
     
   select @grupa=n.grupa from nomencl n where n.Cod=@cod  
   select top 1 @discmax=CASE ISNUMERIC(valoare) when 1 then CONVERT(float,replace(Valoare,',',''))   
    else null end, @grupadiscmax=rtrim(pr.Cod) from proprietati pr   
   where pr.Valoare<>'' and pr.Cod<>'' and tip='GRUPA' and cod_proprietate='DISCMAX'   
    and @grupa like RTRIM(pr.Cod)+'%'  
   order by pr.cod desc, pr.Valoare desc  
   set @errdiscmax='Discountul introdus depaseste maximul de '+RTRIM(CONVERT(decimal(10,3),@discmax))  
    +' admis pe grupa '+rtrim(@grupadiscmax)  
     
   if @grupa=''  
    select 'Atentie: nu este completata grupa pt acest articol. '  
    +'Completati grupa pentru a valida discountul (wScriuPozDocSP).' as textMesaj  
    , 'Functionare nerecomandata' as titluMesaj  
    for xml raw,root('Mesaje')  
   else  
   begin  
    if @discmax is null  
     select 'Atentie: nu este configurat discountul maxim pe grupa acestui articol. '  
     +'Configurati proprietatea DISCMAX pe grupa pentru a valida discountul (wScriuPozDocSP).' as textMesaj  
     , 'Functionare nerecomandata' as titluMesaj  
     for xml raw,root('Mesaje')  
    else  
     if @discount>@discmax  
      raiserror(@errdiscmax,11,1)  
   end  
  end  
  
  if @tip in ('BK') and @cantitate<>0  
  begin  
   declare @cant_aprob decimal(15,3)=@cantitate  
   if @parXML.value('(/row/row/@cant_aprobata)[1]','decimal(15,3)') is null  
    set @parXML.modify ('insert attribute cant_aprobata {sql:variable("@cant_aprob")} into (/row/row)[1]')  
   else  
    if @parXML.value('(/row/row/@cant_aprobata)[1]','decimal(15,3)')<>@cantitate  
     set @parXML.modify('replace value of (/row/row/@cant_aprobata)[1] with sql:variable("@cant_aprob")')   
  end  
   
 fetch next from crspozconsp into @tip, @contract, @data, @gestiune, @gestiune_primitoare,   
  @tert, @factura,  @contclient,@procpen,@contr_cadru,@ext_camp4,@ext_camp5,@ext_modificari ,@ext_clauze,@termen, @subtip,   
  @scadenta,  
  --termene  
  @termene, @data1,    
    
  @lm, @info1_antet, @info2_antet, @info3_antet, @info4_antet, @info5_antet, @info6_antet,   
  @numar_pozitie, @cod, @o_cod, @cantitate,   
    
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
   
 --COMMIT TRAN  
end try  
begin catch  
 --ROLLBACK TRAN  
 --if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0  
  --set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'  
 set @mesaj = ERROR_MESSAGE()+'(wScriuPozConSP)'  
end catch  
--  
declare @cursorStatus int  
set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='crspozconsp' and session_id=@@SPID )  
if @cursorStatus=1   
 close crspozconsp   
if @cursorStatus is not null   
 deallocate crspozconsp   
--  
begin try   
 exec sp_xml_removedocument @iDoc   
end try   
begin catch end catch  
  
if ISNULL(@mesaj,'')!=''  
 raiserror(@mesaj, 11, 1)  