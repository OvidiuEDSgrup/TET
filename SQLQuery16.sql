--***  
create procedure wScriuTE @parXmlScriereIesiri xml  
as  
begin try  
declare @Numar char(8) ,@Data datetime,@GestPred char(9),@GestPrim char(9),@GestDest char(20),  
 @Cod char(20),@CodIntrare char(13),@CodIPrim char(13) ,@CodIPrimNou int,@Cantitate float,@LocatiePrim char(30),  
 @PretAmPrim float,@CategPret int,@Valuta char(3),@Curs float,@LM char(9),@Comanda char(40),@ComLivr char(20),@Jurnal char(3),@Stare int,  
 @Barcod char(30),@Schimb int,@Serie char(20),@Utilizator char(10),@PastrCtSt int,  
 @Valoare float,@TotCant float,@NrPozitie int,@CtCoresp char(13),@CtIntermediar char(13),@TVAnx float,@update bit,@subtip varchar(2),@mesaj varchar(200),@tip varchar(2)  
   
 declare @iDoc int  
   EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXmlScriereIesiri  
     
 select @Numar=isnull(numar,''),@Data=data,@GestPred=gestiune,@GestPrim=gestiune_primitoare,@GestDest=contract,  
  @Cod=cod,@CodIntrare=cod_intrare,@CodIPrim=(case when codiPrim='' then null else codiPrim end), @CodIPrimNou=0,@Cantitate=cantitate,@LocatiePrim=locatie,  
  @PretAmPrim=pret_amanunt,@CategPret=ISNULL(categ_pret,''),@Valuta=valuta,@Curs=curs,  
  @LM=lm,@Comanda=comanda_bugetari, @ComLivr=factura,@Jurnal=jurnal,@Stare=stare,@Barcod=barcod,  
  @Schimb=0,@Serie=isnull(serie,0),@Utilizator=ISNULL(utilizator,''),@PastrCtSt=0,@Valoare=null,@TotCant=null,  
  @NrPozitie=ISNULL(numar_pozitie,0),@CtCoresp=cont_corespondent,@CtIntermediar=isnull(contintermediar,''),@TVAnx=TVAnx,@update=isnull(ptupdate,0),@tip=tip,@subtip=subtip      
      
  from OPENXML(@iDoc, '/row')  
  WITH   
  (  
   tip char(2) '@tip',   
   subtip char(2) '@subtip',   
   numar char(8) '@numar',  
   data datetime '@data',  
   tert char(13) '@tert',  
   factura char(20) '@factura',  
   data_facturii datetime '@data_facturii',  
   data_scadentei datetime '@data_scadentei',  
   cont_factura char(13) '@cont_factura',  
   gestiune char(9) '@gestiune',  
   cod char(20) '@cod',  
   cod_intrare char(20) '@cod_intrare',  
   codiPrim char(20) '@codiPrim',  
   cantitate float '@cantitate',   
   valuta varchar(3) '@valuta' ,   
   curs varchar(14) '@curs',  
   pret_valuta float '@pret_valuta',   
   discount float '@discount',   
   pret_amanunt float '@pret_amanunt',   
   lm char(9) '@lm',   
   comanda_bugetari char(40) '@comanda_bugetari',   
   contract char(20) '@contract',  
   jurnal char(3) '@jurnal',   
   stare int '@stare',  
   barcod char(30) '@barcod',   
   tipTVA int '@tipTVA',  
   utilizator char(20) '@utilizator',   
   serie char(20) '@serie',  
   suma_tva float '@suma_tva',   
   cota_TVA float '@cota_TVA',  
   locatie char(30) '@locatie',   
   numar_pozitie int '@numar_pozitie',  
   suprataxe float '@suprataxe',   
   cont_corespondent char(13) '@cont_corespondent',  
   contintermediar char(13) '@contintermediar',  
   ptupdate int '@update',  
   explicatii varchar(30) '@explicatii',  
   punct_livrare varchar(30) '@punct_livrare',  
   categ_pret varchar(30) '@categ_pret' ,   
   gestiune_primitoare varchar(30) '@gestiune_primitoare',  
   TVAnx float '@TVAnx'   
  )  
 set @Comanda=@parXmlScriereIesiri.value('(/row/@comanda_bugetari)[1]', 'varchar(40)') --din cursor nu stie sa citeasca cu spatiile din fata!!   
 if isnull(@utilizator,'')=''  
 begin   
  raiserror('Utilizatorul windows autentificat nu poate fi gasit in tabela de utilizatori ASiS!',11,1)  
  return -1  
 end  
 declare @Sb char(9),@TabPreturi int,  
  @TLitR int,@Accize int,@CtAccCR char(13),@FaraTVAnx int,@Ct348 char(13),@DifPProd int,@CtIntTE char(13),  
  @Ct378 char(13),@AnGest378 int,@AnGr378 int,@Ct4428 char(13),@AnGest4428 int,  
  @TipNom char(1),@CtNom char(13),@PStocNom float,@PAmNom float,@GrNom char(13),@CoefConv2Nom float,@CategNom int,@GreutSpecNom float,@TVANom float,  
  @TipGestPred char(1),@TipGestPrim char(1),@CtGestPrim char(13),  
  @PretSt float,@CtStoc char(13),@PretAmPred float,@LocatieStoc char(30),@DataExpStoc datetime,@DinCust int,@PVanzSt float,  
  @PAmPreturi float,@PVanzPreturi float,  
  @PretVanz float,@CtInterm char(13),@CtAdPred char(13),@CtAdPrim char(13),@CtTVAnxPred char(13),@CtTVAnxPrim char(13),  
  @AccCump float,@AccDat float,@StersPozitie int,@Serii int  
  
 exec luare_date_par 'GE','SUBPRO',0,0,@Sb output  
 exec luare_date_par 'GE','PRETURI',@TabPreturi output,0,''  
 exec luare_date_par 'GE','TIMBRULT2',@TLitR output,0,''  
 exec luare_date_par 'GE','ACCIZE',@Accize output,0,''  
 exec luare_date_par 'GE','CACCIZE',0,0,@CtAccCR output  
 exec luare_date_par 'GE','CADAOS',@AnGest378 output,@AnGr378 output,@Ct378 output  
 exec luare_date_par 'GE','CNTVA',@AnGest4428 output,0,@Ct4428 output  
 exec luare_date_par 'GE','FARATVANE',@FaraTVAnx output,0,''  
 exec luare_date_par 'GE','CONT348',@DifPProd output,0,@Ct348 output  
 exec luare_date_par 'GE','CALTE',0,0,@CtIntTE output  
 exec luare_date_par 'GE', 'SERII', @Serii output, 0, ''  
  
 exec iauNrDataDoc 'TE',@Numar output,@Data output,0  
 if isnull(@Stare,0)=0  
  set @Stare=3  
 if @CodIPrimNou is null   
  set @CodIPrimNou=0  
  
 set @TipNom=''  
 set @CtNom=''  
 set @PStocNom=0  
 set @PAmNom=0  
 set @GrNom=''  
 set @CoefConv2Nom=0  
 set @CategNom=0  
 set @GreutSpecNom=0  
 set @TVANom=0  
 select @TipNom=tip,@CtNom=cont,@PStocNom=pret_stoc,@PAmNom=pret_cu_amanuntul,@GrNom=grupa,  
  @CoefConv2Nom=Coeficient_conversie_1,@CategNom=categorie,@GreutSpecNom=greutate_specifica,@TVANom=Cota_TVA  
 from nomencl  
 where cod=@Cod  
  
 set @TipGestPred=''  
 select @TipGestPred=tip_gestiune  
 from gestiuni   
 where subunitate=@Sb and cod_gestiune=@GestPred  
  
 set @TipGestPrim=''  
 set @CtGestPrim=''  
 select @TipGestPrim=tip_gestiune,@CtGestPrim=cont_contabil_specific  
 from gestiuni   
 where subunitate=@Sb and cod_gestiune=@GestPrim  
  
 select @PretSt=pret,@CtStoc=cont,@TVAnx=(case when @TVAnx is null and tip_gestiune='A' then tva_neexigibil else isnull(@TVAnx,0) end),@PretAmPred=pret_cu_amanuntul,@LocatieStoc=locatie,@DataExpStoc=data_expirarii,  
  @DinCust=are_documente_in_perioada,@PVanzSt=pret_vanzare  
 from stocuri  
 where @TipGestPred<>'V' and subunitate=@Sb and tip_gestiune=@TipGestPred and cod_gestiune=@GestPred and cod=@Cod and cod_intrare=@CodIntrare  
  
 if @PretSt is null set @PretSt=isnull(@PStocNom,0)  
 if @CtStoc is null set @CtStoc=dbo.formezContStoc(isnull(@GestPred,''),isnull(@Cod,''),isnull(@LM,''))  
 if @DinCust is null set @DinCust=0  
  
 select top 1 @PAmPreturi=pret_cu_amanuntul,@PVanzPreturi=pret_vanzare  
 from preturi   
 where @TabPreturi=1 and cod_produs=@Cod and UM=(case when @CategPret<>0 then @CategPret else 1 end)   
   and tip_pret='1' and @Data between data_inferioara and data_superioara   
 order by data_inferioara desc  
  
 if /*@TVAnx is null and */@TipGestPrim='A' and left(@CtGestPrim,2)='35' and @DifPProd=1 and left(@CtStoc,2) in ('33','34') or @FaraTVAnx=1  
  set @TVAnx=0  
 if @TVAnx is null   
  set @TVAnx=@TVANom  
 if @TipGestPred<>'A' and @DifPProd=1 and left(@CtStoc,2) in ('33','34')  
  set @PretAmPred=(case when @TipGestPrim='A' and left(@CtGestPrim,3)='371' then (case when @DinCust=1 then @PVanzSt else @PVanzPreturi end) else 0 /*??? aici ar trebui pret amanunt primitor...*/end)  
 if @PretAmPred is null   
  set @PretAmPred=0  
  
 if isnull(@PretAmPrim,0)=0  
 begin  
  if @TipGestPrim in ('A','C') or @TipGestPrim='V' and @TipGestPred<>'A'  
   set @PretAmPrim=isnull(@PAmPreturi,@PAmNom)  
  if @PretAmPrim is null and @TipGestPrim='V' and @TipGestPred='A'  
   set @PretAmPrim=@PretAmPred  
  if @PretAmPrim is null  
   set @PretAmPrim=@PAmNom  
 end  
 if isnull(@CtCoresp,'')='' and left(@CtStoc,1)='8'  
  set @CtCoresp=@CtStoc  
 if isnull(@CtCoresp,'')='' and left(@CtGestPrim,3)='357' and @TipNom='P'  
  set @CtCoresp='354'  
  
 if isnull(@CodIPrim,'')=''  
  -- mai jos, unde a fost trimis parametrul @Data am pus '1901-01-01' (in 2 locuri), pentru a verifica intreg stocul la primitor, nu doar cel cu data egala cu data documentului  
  set @CodIPrim=dbo.cautareCodIntrare(isnull(@Cod,''),isnull(@GestPrim,''),@TipGestPrim,isnull(@CodIntrare,''),@PretSt,@PretAmPrim,isnull(@CtCoresp,''),@CodIPrimNou,0,'1901-01-01','1901-01-01','','','','','','')  
  
 select @CtCoresp=(case when isnull(@CtCoresp,'')='' then (case when cont in ('0','371.') then '' else cont end) else @CtCoresp end),  
  @PretAmPrim=(case when isnull(@PretAmPrim,0)=0 then pret_cu_amanuntul else @PretAmPrim end),  
  @LocatiePrim=(case when isnull(@LocatiePrim,'')='' then locatie else @LocatiePrim end),@DataExpStoc=data_expirarii  
 from stocuri  
 where @TipGestPrim<>'V' and subunitate=@Sb and tip_gestiune=@TipGestPrim and cod_gestiune=@GestPrim and cod=@Cod and cod_intrare=@CodIPrim  
  
 set @PretVanz=convert(decimal(17, 5), @PretAmPrim/(1.00+isnull(@TVAnx,0)/100))  
  
 if isnull(@LocatiePrim,'')=''   
  set @LocatiePrim=isnull(@LocatieStoc,'')  
 if @DataExpStoc is null  
  set @DataExpStoc=@Data  
 if isnull(@CtCoresp,'')='' and @PastrCtSt=1 and @CtGestPrim=''  
  set @CtCoresp=@CtStoc  
 if isnull(@CtCoresp,'')=''  
  set @CtCoresp=dbo.formezContStoc(isnull(@GestPrim,''),isnull(@Cod,''),isnull(@LM,''))  
  
 if @Accize=1 and @TipGestPred='P'  
 begin  
  declare @AccCategProd int,@AccUnitVanz float  
  exec luare_date_par 'GE','CATEGPRO',@AccCategProd output,0,''  
  if @AccCategProd=1  
  begin  
   set @AccUnitVanz=isnull((select max(acciza_vanzare) from categprod where categoria=@CategNom),0)  
   set @AccDat=round(convert(decimal(17,4),@CoefConv2Nom*@AccUnitVanz*isnull(@Cantitate,0)),3)  
  end  
 end  
 if @AccDat is null set @AccDat=0  
  
 set @Valoare=isnull(@Valoare,0)+round(convert(decimal(17,3),isnull(@Cantitate,0)*@PretSt),2)  
 set @TotCant=isnull(@TotCant,0)+isnull(@Cantitate,0)  
  
 set @CtInterm=(case when @TipGestPred='V' then @CtIntTE when @TLitR=1 then @CtAccCR else @CtIntermediar end)  
  
 if @DifPProd=1 and left(isnull(@CtCoresp,''),1)<>'6' and left(@CtStoc,2) in ('33','34')  
  set @CtAdPred=@Ct348  
 if @CtAdPred is null   
  set @CtAdPred=RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(isnull(@GestPred,'')) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrNom) else '' end)  
 set @CtTVAnxPred=RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(isnull(@GestPred,'')) else '' end)  
 set @CtAdPrim=RTrim(@Ct378)+(case when @AnGest378=1 then '.'+RTrim(isnull(@GestPrim,'')) else '' end)+(case when @AnGr378=1 then '.'+RTrim(@GrNom) else '' end)  
 set @CtTVAnxPrim=RTrim(@Ct4428)+(case when @AnGest4428=1 then '.'+RTrim(isnull(@GestPrim,'')) else '' end)  
  
 set @AccCump=(case when @TLitR=1 then @GreutSpecNom when @TabPreturi=1 then @CategPret else 0 end)  
  
if isnull(@Utilizator,'')=''  
 set @Utilizator=dbo.fIaUtilizator(null)  
  select @utilizator  
 ---start adaugare pozitie noua in pozdoc-----  
 if @update=0 and @subtip<>'SE'  
  begin    
   exec luare_date_par 'DO','POZITIE',0,@NrPozitie output,''--alocare numar pozitie  
   set @NrPozitie=@NrPozitie+1  
      
   ---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------  
   if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0   
    begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui  
     select @cod = (case when @Cod is null then '' else @cod end ),  
         @GestPred = (case when @GestPred is null then '' else @GestPred end),  
         @Cantitate = (case when @Cantitate is null then 0 else @Cantitate end),  
         @CodIntrare = (case when @CodIntrare is null then '' else @CodIntrare end),  
         @GestPrim = (case when @GestPrim is null then '' else @GestPrim end)  
     exec wScriuPDserii 'TE', @Numar, @Data, @GestPred, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, @GestPrim  
     set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='TE' and Numar=@Numar and data=@Data and Gestiune=@GestPred and cod=@Cod   
              and Gestiune_primitoare=@GestPrim and Cod_intrare=isnull(@CodIntrare,'') and Numar_pozitie=@NrPozitie),0)--calcul cantitate pt pozdoc din pdserii  
    end  
   ----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------  
     
   insert pozdoc  
    (Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,  
    Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,  
    Cod_intrare,Cont_de_stoc,Cont_corespondent,  
    TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,  
    Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,  
    Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,  
    Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,  
    Accize_cumparare,Accize_datorate,Contract,Jurnal)   
   values  
    (@Sb,'TE',@Numar,isnull(@Cod,''),@Data,isnull(@GestPred,''),isnull(@Cantitate,0),0,@PretSt,0,  
    @PretVanz,@PretAmPrim,0,0,isnull(@Utilizator,''),convert(datetime, convert(char(10), getdate(), 104), 104),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),  
    isnull(@CodIntrare,''),@CtStoc,isnull(@CtCoresp,''),isnull(@TVAnx,0),@PretAmPred,'E',  
    @LocatiePrim,@DataExpStoc,@NrPozitie,isnull(@LM,''),isnull(@Comanda,''),isnull(@Barcod,''),  
    @CtInterm,@CtAdPrim,@DinCust,@CtAdPred,isnull(@ComLivr,''),isnull(@GestPrim,''),@CtTVAnxPred,  
    @Stare,@CodIPrim,@CtTVAnxPrim,isnull(@Valuta,''),isnull(@Curs,0),@Data,@Data,@Schimb,0,  
    @AccCump,@AccDat,isnull(@GestDest,''),isnull(@Jurnal,''))  
  
    exec setare_par 'DO','POZITIE',null,null,@NrPozitie,null--setare ultimul numarul de pozitie introdus-> ca ultim nr de pozitii pozdoc  
  end  
  
---stop adaugare pozitie noua in pozdoc-----  
    
 -----start modificare pozitie existenta in pozdoc----  
 if @update=1 or @subtip='SE'--situatia in care se modifica o pozitie din pozdoc sau se adauga pozitie cu subtip SE->serie in cadrul pozitiei din pozdoc  
  begin  
     
   ---->>>>>>>>cod specific lucrului pe serii<<<<<<----------------  
   if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>'' and @Serii<>0   
    begin--daca se lucreaza pe serii, si codul introdus are serii se scrie in pdserii codul cu seria lui  
     select @cod = (case when @Cod is null then '' else @cod end ),  
         @GestPred = (case when @GestPred is null then '' else @GestPred end),  
         @Cantitate = (case when @Cantitate is null then 0 else @Cantitate end),  
         @CodIntrare = (case when @CodIntrare is null then '' else @CodIntrare end),  
         @GestPrim = (case when @GestPrim is null then '' else @GestPrim end)  
     exec wScriuPDserii 'TE', @Numar, @Data, @GestPred, @Cod, @CodIntrare, @NrPozitie, @Serie, @Cantitate, @GestPrim  
     set @Cantitate =isnull((select SUM(cantitate) from pdserii where tip='TE' and Numar=@Numar and data=@Data and Gestiune=@GestPred and cod=@Cod   
            and Gestiune_primitoare=@GestPrim and Cod_intrare=@CodIntrare and Numar_pozitie=@NrPozitie),0)--calcul cantitate pt pozdoc din pdserii  
    end  
     
   if @subtip='SE'  
    begin --daca s-a adaugat o pozitie de serie noua, se seteaza cantitatea in pozitia din pozdoc   
     update pozdoc set Cantitate=(case when isnull(@Cantitate,0)<>0 then @Cantitate else Cantitate end)  
     where subunitate=@Sb and tip='TE' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie  
    end      
   ----->>>>>>>sfarsit cod specific lucrului pe serii<<<<<<<---------   
     
   else   
   update pozdoc set   
     Cod=(case when @Cod is null then Cod else @cod end),  
     Gestiune=(case when @GestPred is null then Gestiune else @GestPred end),  
     Cantitate=(case when @Cantitate is null then Cantitate else convert(decimal(11,3),@Cantitate) end),  
     Pret_de_stoc=(case when @PretSt is null then convert(decimal(11,5),Pret_de_stoc) else convert(decimal(11,5),@PretSt) end),  
     Pret_vanzare=(case when @PretVanz is null then convert(decimal(11,5),Pret_vanzare) else convert(decimal(11,5),@PretVanz) end),  
     Pret_cu_amanuntul=(case when @PretAmPrim is null then convert(decimal(11,5),Pret_cu_amanuntul) else convert(decimal(11,5),@PretAmPrim) end),  
     Utilizator=@Utilizator,  
     Data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104),  
     Ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')),  
     Cod_intrare=(case when @CodIntrare is null then Cod_intrare else @CodIntrare end),  
     Cont_de_stoc=(case when @CtStoc is null then Cont_de_stoc else @CtStoc end),      
     Cont_corespondent=(case when @CtCoresp is null then Cont_corespondent else @CtCoresp end),  
     TVA_neexigibil=(case when @TVAnx is null then convert(decimal(11,5),TVA_neexigibil) else convert(decimal(11,5),@TVAnx) end),  
     Pret_amanunt_predator=(case when @PretAmPred is null then convert(decimal(11,5),Pret_amanunt_predator) else convert(decimal(11,5),@PretAmPred) end),  
     Locatie=(case when @LocatiePrim is null then Locatie else @LocatiePrim end),  
     Data_expirarii=(case when @DataExpStoc is null then Data_expirarii else @DataExpStoc end),      
     Loc_de_munca=(case when @LM is null then Loc_de_munca else @LM end),      
     Comanda=(case when @Comanda is null then Comanda else @Comanda end),  
     Barcod=(case when @Barcod is null then Barcod else @Barcod end),      
     Cont_intermediar=(case when @CtInterm is null then Cont_intermediar else @CtInterm end),  
     Cont_venituri=(case when @CtAdPrim is null then Cont_venituri else @CtAdPrim end),  
     Discount=(case when @DinCust is null then convert(decimal(11,5),Discount) else convert(decimal(11,5),@DinCust) end),  
     Tert=(case when @CtAdPred is null then Tert else @CtAdPred end),  
     Factura=(case when @ComLivr is null then Factura else @ComLivr end),  
     Gestiune_primitoare=(case when @GestPrim is null then Gestiune_primitoare else @GestPrim end),  
     Numar_DVI=(case when @CtTVAnxPred is null then Numar_DVI else @CtTVAnxPred end),      
     Stare=(case when @Stare is null then Stare else @Stare end),  
     Grupa=(case when @CodIPrim is null then Grupa else @CodIPrim end),  
     Cont_factura=(case when @CtTVAnxPrim is null then Cont_factura else @CtTVAnxPrim end),      
     Valuta=(case when @Valuta is null then Valuta else @Valuta end),  
     Curs=(case when @Curs is null then Curs else convert(decimal(11,3),@Curs) end),  
     Procent_vama=(case when @Schimb is null then Procent_vama else @Schimb end),  
     Accize_cumparare=(case when @AccCump is null then Accize_cumparare else convert(decimal(11,3),@AccCump) end),   
     Accize_datorate=(case when @AccDat is null then Accize_datorate else convert(decimal(11,3),@AccDat) end),      
     Contract=(case when @GestDest is null then [Contract] else @GestDest end),  
     Jurnal=(case when @Jurnal is null then Jurnal else @Jurnal end)       
   where subunitate=@Sb and tip='TE' and numar=@Numar and data=@Data and numar_pozitie=@NrPozitie  
  end  
  -----stop modificare pozitie existenta in pozdoc----  
   
end try  
begin catch  
 --ROLLBACK TRAN  
 set @mesaj = ERROR_MESSAGE()  
 raiserror(@mesaj, 11, 1)  
end catch  
  
begin try   
 exec sp_xml_removedocument @iDoc   
end try   
begin catch end catch  