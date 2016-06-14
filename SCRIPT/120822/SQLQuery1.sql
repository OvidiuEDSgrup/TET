--***  
CREATE procedure [dbo].[wDescarcBon] @sesiune varchar(50), @parXML xml  
as  
declare @vanzbon varchar(10), @UID varchar(50), @GestBon varchar(13),@factura varchar(20), @idAntetBonFiltrat int,  
 @msgEroare varchar(max)  
set nocount on  
  
if exists (select 1 from sysobjects where type='P' and name='wDescarcBonSP')  
begin  
  -- Atentie! Va recomandam sa evitati scrierea unei proceduri specifice pentru descarcare.   
  -- Daca totusi alegeti sa folositi, marcati folosind tag-uri de tip /*specific*/ si /*end specific*/   
  -- partea modificata, pentru a putea integra usor codul specific si in   
  -- versiunile mai noi ale procedurii  
  exec wDescarcBonSP @sesiune, @parXML  
  return  
end  
  
set transaction isolation level read committed  
begin try  
/* citesc variabile din parXML */  
select @UID = @parXML.value('(/row/@UID)[1]', 'varchar(50)'),  
  @idAntetBonFiltrat = isnull(@parXML.value('(/row/@idAntetBon)[1]', 'int'),0)  
    
select @GestBon=gestiune, @vanzbon=Vinzator   
 from antetBonuri where idAntetBon=@idAntetBonFiltrat  
  
if @GestBon is null  
 select @GestBon=gestiune, @vanzbon=Vinzator from antetBonuri   
  where UID=@UID  
  
if @GestBon is null and @UID is not null  
begin  
 set @msgEroare='Documentul cautat nu poate fi gasit! '+char(13)+  
  'ID bon='+ISNULL(convert(varchar(30),@idAntetBonFiltrat),'(null)')+char(13)+  
  'UID bon='+isnull(@UID,'(null)')  
 raiserror(@msgeroare,11,1)  
end  
  
--exec DescarcBon @CasaBon,@vanzator,@DataBon,@Numarbon,@GestBon,  
declare @nFetchStatus int,@subunitate varchar(9),@Serii int,  
 @listaGestiuni varchar(202),@NuTEAC int,@NuStocTE int,@CodITE int,  
 @OrdGest int,@TipG varchar(1),  
 @Incas int,@Casa int,@Data datetime,@NrBon int,@Vanz varchar(10),@NrLin int,  
 @TipDoc char(2),@Client varchar(13),@Cod varchar(20),@AreSerii int,@Serie varchar(20),@Coef float,@Cant float,  
 @CotaTVA float,@SumaTVA float,@Pret float,@Disc float,@Barcod varchar(20),@TipNom char(1),  
 @LM varchar(20),@comanda_asis varchar(20),@dataScad datetime,@CategP varchar(5),@PctLiv varchar(20),  
 @contract varchar(20),@Jurn varchar(3),@AP418 int,@CtFact varchar(13),  
 @ExcGest varchar(30),@ExcCont varchar(13), @esteListaGestiuni bit,  
 @GestSt varchar(9),@CodISt varchar(20),@Stoc float, @ContOrd varchar(13),@SerieSt varchar(20),  
 @CantRam float,@CantDesc float,@NrDoc varchar(8),@NrTE varchar(8),@NrRM varchar(8),@CodIPrim varchar(13),  
 @PretDisc float,@PValuta float,@PVanz float,@PretAm float,@TVAunit float,  
 @TVAPoz float,@TVADesc float,@CantExc8 float,@CtStoc varchar(13),@PStoc float,@TertRM varchar(13),  
 @CasaAnt int,@DataAnt datetime,@NrBonAnt int,@VanzAnt varchar(10),@codIntrareInDenumire int, @ClientAnt varchar(20), @dataScadAnt datetime,   
 @bTip int, @facturiDefinitive bit, @tipTVA int, @xml xml, @UidAnt varchar(36),   
 @idAntetBonAnt int, @idAntetBon int, @gestPozitie varchar(30), @listaGestiuniPozitie varchar(300),  
 @rezervareStocComenzi bit, @gestRezervariComenzi varchar(13), @DetaliereBonuri bit, @tmpbon cursor, @CuTranzactii int  
declare @devize table (cod_deviz varchar(20), pozitie int primary key(cod_deviz,pozitie))  
  
select @subunitate=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else isnull(@subunitate,'') end),  
  @Serii=(case when Parametru='SERII' then Val_logica else isnull(@Serii,0) end),  
  @facturiDefinitive=(case when Parametru='FACTDEF' then Val_logica else isnull(@facturiDefinitive,0) end),  
  @rezervareStocComenzi=(case when Parametru='REZSTOCBK' then Val_logica else isnull(@rezervareStocComenzi,0) end),  
  @gestRezervariComenzi=(case when Parametru='REZSTOCBK' then rtrim(Val_alfanumerica) else isnull(@gestRezervariComenzi,'') end),  
  @listaGestiuni=(case when Parametru=@GestBon then rtrim(Val_alfanumerica) else isnull(@listaGestiuni,'') end),  
  @DetaliereBonuri=(case when Parametru='DETBON' then Val_logica else isnull(@DetaliereBonuri, 0) end),  
  @NuTEAC=(case when Parametru='NUTEAC' then Val_logica else isnull(@NuTEAC, 0) end),  
  @NuStocTE=(case when Parametru='NUSTOCTE' then Val_logica else isnull(@NuStocTE, 0) end),  
  @CodITE=(case when Parametru='CODINOUTE' then Val_logica else isnull(@CodITE, 0) end),  
  @OrdGest=(case when Parametru='ORDGEST' then Val_logica else isnull(@OrdGest, 0) end),  
  @codIntrareInDenumire=(case when Parametru='CODIINDEN' then Val_logica else isnull(@codIntrareInDenumire, 0) end)    
from par  
where Tip_parametru='GE' and Parametru in ('SUBPRO', 'SERII', 'FACTDEF', 'REZSTOCBK')  
 or Tip_parametru='PG' and Parametru = @GestBon   
 or Tip_parametru='PO' and Parametru in ('DETBON', 'NUTEAC', 'NUSTOCTE', 'CODINOUTE', 'ORDGEST')   
 or Tip_parametru='PV' and Parametru = 'CODIINDEN'  
  
exec luare_date_par 'GE','TRANZACT', @CuTranzactii output, 0, ''  
set @CuTranzactii=ISNULL(@CuTranzactii,0)  
if @CuTranzactii=1  
 begin transaction descarcaBon  
  
/*   
din PVria v2.3.005 descarc doar cate un bon - uneori se dublau cantitatile descarcate   
din cauza apelarii in paralel a wDescarcBon;  
PV da timeout in 30secunde si reincearca, dar procedura nu se opreste la timeout, ci ruleaza in continuare...   
Filtrez doar dupa idAntetBon  
*/  
set @tmpbon = cursor for   
select   
 (case when b.tip in ('11','21') and b.cod_produs<>'' then 0 else 1 end) as incasare ,  
 b.casa_de_marcat,  
 b.data,  
 b.numar_bon,  
 b.vinzator,  
 b.numar_linie,  
 --(CASE WHEN b.factura_chitanta = 1 THEN 'AC' ELSE 'AP' END) AS tipdoc,  
 isnull(a.bon.value('(/date/document/@tipdoc)[1]','varchar(2)'),  
  (CASE WHEN b.factura_chitanta = 1 THEN 'AC' ELSE 'AP' END)) AS tipdoc,  
 b.client,  
 b.cod_produs,  
 (CASE WHEN @Serii = 1 AND left(isnull(n.UM_2, ''), 1) = 'Y' THEN 1 ELSE 0 END) AS areSerii,  
 b.numar_document_incasare AS serie,  
 (CASE b.um WHEN 2 THEN isnull(n.coeficient_conversie_1, 0) WHEN 3 THEN isnull(n.coeficient_conversie_2, 0) ELSE 1 END) AS coef_conv,  
 b.cantitate,  
 b.cota_tva,  
 b.tva,  
 b.pret,  
 b.discount,  
 b.codplu,  
 isnull(n.tip, '') tipnomencl,  
 rtrim(isnull(b.lm_real, isnull(a.Loc_de_munca, isnull(gestcor.loc_de_munca, '')))) lm,  
 rtrim(isnull(b.Comanda_asis, isnull(a.comanda, ''))) comanda_asis,  
 rtrim(isnull(a.data_scadentei, dateadd(d, isnull(it.discount, 0), b.data))) data_scadentei,  
 isnull(rtrim(a.categorie_de_pret), 0) categorie_de_pret,  
 isnull(rtrim(a.punct_de_livrare), '') punct_de_livrare,  
 rtrim(isnull(b.[contract], isnull(a.contract, ''))) [contract],  
 '' jurnal,  
 /*(CASE WHEN left(isnull(a.explicatii, ''), 1) = '1' THEN 1 ELSE 0 END)*/ 0 AS AP418, -- de gasit loc in tabela sau in XML  
 isnull(rtrim(a.factura), convert(VARCHAR(30), b.numar_bon)) AS factura,  
 b.tip,  
 -- mai jos: tipul de TVA conteaza doar la tertii platitori de TVA, deci cei care au infotert.grupa13 necompletata => atunci depinde de marcajul din Nomenclator  
 -- daca nu exista aceasta linie in infotert sau exista si este pusa pe '1' => tipTVA=0 (TVA normal), adica se ia cota TVA din Nomenclator  
 (CASE WHEN isnull(it.grupa13, 'null') IN ('1','null') THEN 0 ELSE convert(INT, left(n.tip_echipament, 1)) END) AS tipTVA,  
 rtrim(b.Gestiune) as gestiune,  
 a.[uid] AS UID,  
 b.idAntetBon AS idAntetBon  
from bt b  
inner join antetBonuri a on a.idAntetBon=b.idAntetBon --b.casa_de_marcat=a.casa_de_marcat and b.factura_chitanta=a.chitanta and a.numar_bon=b.numar_bon and b.data=a.data_bon  
left outer join gestcor on gestcor.gestiune=b.loc_de_munca  
left outer join nomencl n on n.cod=b.cod_produs  
left outer join infotert it on b.factura_chitanta=0 and it.subunitate=@subunitate and it.tert=b.client and it.identificator=''  
where a.idAntetBon=@idAntetBonFiltrat  
  
open @tmpbon  
fetch next from @tmpbon into @Incas,@Casa,@Data,@NrBon,@Vanz,@NrLin,@TipDoc,@Client,@Cod,@AreSerii,@Serie,@Coef,@Cant,@CotaTVA,@SumaTVA,@Pret,@Disc,@Barcod,@TipNom,@LM,@comanda_asis,@dataScad,@CategP,@PctLiv,@contract,@Jurn,@AP418,@factura,@bTip, @tipTVA,
 @gestPozitie, @UID, @idAntetBon  
select @CasaAnt=@Casa,@DataAnt=@Data,@NrBonAnt=@NrBon,@VanzAnt=@Vanz,@dataScadAnt=@dataScad,@ClientAnt=@Client, @UidAnt=@UID, @idAntetBonAnt=@idAntetBon  
set @nFetchStatus=@@fetch_status  
  
set @esteListaGestiuni = (case when len(@listaGestiuni)>0 then 1 else 0 end)  
if charindex(';'+RTrim(@GestBon)+';',';'+RTrim(@listaGestiuni)+';')=0 and (@TipDoc<>'AC' or @NuStocTE=0)  
 set @listaGestiuni=RTrim(@GestBon)+';'+RTrim(@listaGestiuni)  
  
  
while @nFetchStatus=0  
begin  
 set @Cant=round(convert(decimal(15,5),@Cant*@Coef),3)  
 set @Pret=(case when @Coef=0 then 0 else round(convert(decimal(15,5),@Pret/@Coef),5) end)  
 set @CantExc8=0  
 if @Incas=0  
 begin  
  set @CantRam=@Cant  
  set @CtFact=(case when @TipDoc='AP' and @AP418=1 then '418' else '' end)  
  set @PretDisc=round(convert(decimal(15,5),@Pret*(1-@Disc/100)),5)  
  if @TipDoc not in ('AP','TE') -- rotunjire doar la AC  
   if exists (select 1 from sysobjects where type in ('FN','IF') and name='rot_pret')  
    set @PretDisc=dbo.rot_pret(@PretDisc,0)  
   else  
    set @PretDisc=round(@PretDisc,2)  
  set @PValuta=(case when @TipDoc in ('AC','TE') then round(convert(decimal(15,5),@Pret/(1+@CotaTVA/100)),5) else @Pret end)  
  set @TVAunit=round(convert(decimal(15,4),@PretDisc*@CotaTVA/(100+(case when @TipDoc in ('AC','TE') then @CotaTVA else 0 end))),2)  
  set @PVanz=@PretDisc-(case when @TipDoc in ('AC','TE') then @TVAunit else 0 end)  
  set @PretAm=round(convert(decimal(15,4),@PretDisc+(case when @TipDoc='AP' then @TVAunit else 0 end)),2)  
  set @TVADesc=0   
  
  set @NrDoc=left((case when @TipDoc in ('AP','TE') then LTrim(@factura)   
      when @TipDoc='AC' and @DetaliereBonuri=1 then RTrim(CONVERT(varchar(4),@casa))+right(replace(str(@NrBon),' ','0'),4)   
      else 'B'+LTrim(str(day(@Data)))+'G'+rtrim(@GestBon) end),8)  
    
  -- salvez numarul de document din pozdoc - se va folosi daca trebuie anulat documentul.  
  if (select bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)') from antetBonuri where idAntetBon=@idAntetBon) is null  
   update antetBonuri set Bon.modify ('insert attribute numar_in_pozdoc {sql:variable("@NrDoc")} into (/date/document)[1]')  
    where idAntetBon=@idAntetBon  
  else  
   update antetBonuri set Bon.modify('replace value of (/date/document/@numar_in_pozdoc)[1] with sql:variable("@NrDoc")')  
    where idAntetBon=@idAntetBon  
    
  -- citesc tipul gestiunii pentru fiecare pozitie.  
  select @TipG=tip_gestiune from gestiuni where subunitate=@subunitate and cod_gestiune=@gestPozitie  
    
  /*   
   Gestiunea din pozitii e mai tare decat cea din antet. De regula e diferita la comenzi sau devize.  
   Se descarca prioritar din gestiunea din pozitii. Daca nu este stoc in acea gestiune,  
   se cauta si in gestiunile atasate utilizatorului. (de modificat daca se vrea fortarea gestiunii...).  
  */  
  set @listaGestiuniPozitie = (case when @gestPozitie=@GestBon then @listaGestiuni   
           else @gestPozitie+';'+@listaGestiuni end);  
    
  if @rezervareStocComenzi=1 and isnull(@contract,'')<>''  
  begin  
   -- daca e o pozitie din comanda, descarc din gestiunea de rezervari  
   set @listaGestiuniPozitie = @gestRezervariComenzi+';'+@listaGestiuniPozitie  
     
  end  
    
  --select @listaGestiuniPozitie '@listaGestiuniPozitie', @gestPozitie '@gestPozitie', @GestBon '@GestBon'  
    
  while abs(@CantRam)>=0.001  
  begin  
   set @GestSt=null  
   set @CodISt=null  
   set @Stoc=null  
     
   if (@CantRam<=-0.001) and @TipNom<>'S'  
   begin  
    ----------------------------------------- pozitie storno -----------------------------------------  
    -- citesc fara sa tin cont de lock-uri - oricum citesc date vechi  
    set transaction isolation level read uncommitted  
      
    -- pentru AC-uri caut cod intrare din gestiunea de vanzare.  
    -- pentru AP-uri caut in gestiunile pt. TE automat, si doar dupa aceea in GestBon  
    -- luarea pozitiei e tratata si in wValidareDocumentPV  
    declare @listaGestiuniStorno varchar(300)  
    set @listaGestiuniStorno = (case when @TipDoc='AC' then ';'+rtrim(@GestBon)+';'  
             else /*@TipDoc='AP'*/  
          ';'+replace(@listaGestiuniPozitie, @GestBon+';', '')+';'+rtrim(@GestBon)+';' end)  
      
    -- daca e linie storno, caut un cod intrare in gestiunile atasate.  
    -- iau de aici si gestiunea - pt. AC-uri caut doar in @gestBon, dar pt AP-uri in toate  
    select top 1 @GestSt=s.Cod_gestiune, @CodISt=cod_intrare,   
     @PStoc = s.Pret, @Stoc=@CantRam, @CtStoc= rtrim(cont), @SerieSt=''  
    from stocuri s  
    where subunitate=@subunitate and cod=@Cod --and tip_gestiune=@TipG /* anulat pt. ca in lista gestiuni pot fi mai multe tipuri */  
    and charindex(';'+RTrim(s.cod_gestiune)+';',@listaGestiuniStorno)>0   
    and (s.Tip_gestiune<>'A' or abs(s.Pret_cu_amanuntul-@PretAm)<0.0009)  
    /* nu fac filtru pe comenzi/contract, ci order by, pt. ca sa gasesc ceva cod de intrare */  
    --and (@comanda_asis='' or @comanda_asis=s.comanda) and (@contract='' or @contract=s.contract)  
    order by   
    (case when @comanda_asis='' then 0 else s.Comanda end) desc,   
    (case when @contract='' then 0 else s.Contract end) desc,  
    charindex(';'+RTrim(s.cod_gestiune)+';',@listaGestiuniStorno), s.Data desc  
      
    if isnull(@GestSt,'')=''  
    begin  
     set @msgEroare='Acest produs('+rtrim(@Cod)+') nu a fost vandut la pretul '+ltrim(STR(@PretAm,12,3))  
      +' din gestiunea ('+@listaGestiuniStorno   
      +')! Nu se poate identifica pretul de stoc pentru incarcarea stocului.'  
     raiserror(@msgEroare,11,1)  
    end  
      
    -- scriu AP/AC in pozdoc   
    set @xml=  
     (select top 1 rtrim(@subunitate) as '@subunitate', @TipDoc as '@tip', rtrim(@Client) as '@tert',  
      @NrDoc as '@numar', convert(varchar(20),@Data,101) as '@data', @CategP as '@categpret',  
      @LM as '@lm',@GestSt as '@gestiune',  @contract as '@contract', 5 as '@stare',  
       (select rtrim(@Cod) as '@cod', convert(decimal(14,5),@Stoc) as '@cantitate',   
        convert(decimal(14,5),@PValuta) as '@pvaluta', convert(decimal(14,5),@SumaTVA) as '@sumatva',   
        convert(decimal(14,5),@PretAm) as '@pamanunt',   
        @CodISt as '@codintrare', convert(decimal(14,5),@PStoc) as '@pstoc', @CtStoc as '@contstoc',  
        @LM as '@lm',   
        @contract as '@contract', @comanda_asis as '@comanda'  
        for xml PATH, TYPE)  
      for XML PATH, type)  
    exec wScriuPozdoc @sesiune=@sesiune, @parXml=@xml  
      
    -- scriu TE  
    if @TipDoc='AC' and @NuTEAC=0   
    begin  
     declare @GestStPrim varchar(9)  
     -- daca este alta gestiune in pozitii, pun acolo marfa.  
     if @gestPozitie<>@GestBon  
      set @GestStPrim = @gestPozitie  
     --else -- caut gestiunea din care s-a facut ultimul transfer  
     -- select top 1 @GestStPrim=rtrim(p.Gestiune)  
     --  from pozdoc p where p.Subunitate=@subunitate and p.Tip='TE' and p.Cod=@Cod  
     --   and p.Grupa=@CodISt and p.Gestiune_primitoare=@GestBon  
     --  order by p.Data desc  
       
     -- daca nu am gasit, iau prima gestiune din lista de gestiuni(in afara de gestiunea curenta)  
     if isnull(len(@GestStPrim),0)=0  
      set @GestStPrim = (select top 1 item from dbo.split(@listaGestiuniPozitie,';') where Item <> @GestBon)  
       
     set @xml=  
      (select top 1 rtrim(@subunitate) as '@subunitate', 'TE' as '@tip',   
       @NrDoc as '@numar', convert(varchar(20),@Data,101) as '@data', @CategP as '@categpret',  
       @LM as '@lm',@GestSt as '@gestiune',  @contract as '@contract',  
       @GestStPrim as '@gestprim', 5 as '@stare',  
        (select rtrim(@Cod) as '@cod', convert(decimal(14,5),-1*@Stoc) as '@cantitate',   
         @CodISt as '@codintrare', convert(decimal(14,5),@PStoc) as '@pstoc',   
         @CtStoc as '@contstoc', @LM as '@lm',   
         @contract as '@contract', @comanda_asis as '@comanda'  
         for xml PATH, TYPE)  
       for XML PATH, type)  
       
     if len(@GestStPrim)>0 -- apelez scrierea doar daca am gasit o gestiune valida  
      begin  
       exec wScriuPozdoc @sesiune=@sesiune, @parXml=@xml  
       update pozdoc -- inversez "semnul" [entru a avea transfer in acelasi sens   
        set Gestiune_primitoare=@GestSt, Gestiune=@GestStPrim, Cod_intrare=Grupa, Grupa=@CodISt,   
         Cont_de_stoc=Cont_corespondent, Cont_corespondent=@CtStoc, Cantitate=-Cantitate,   
         Pret_cu_amanuntul=Pret_amanunt_predator,   
         TVA_neexigibil=(select top 1 Cota_TVA from nomencl where nomencl.Cod=pozdoc.Cod)  
        where Subunitate=@subunitate and Tip='TE' and Numar=@NrDoc and Data=@Data   
         and Gestiune_primitoare<>@GestSt  
      end  
    end  
      
    set transaction isolation level read committed  
      
    set @CantRam=0  
    set @TVADesc=@SumaTVA  
    ----------------------------------------- end pozitie storno -----------------------------------------  
   end  
   else -- @CantRam > 0   
   begin  
    ----------------------------------------- pozitie normala -----------------------------------------  
    if @TipNom<>'S'   
    begin  
     -- caut stoc rezervat pe contract / comanda (filtru pe contract/comanda)  
     if isnull(@contract,'')<>'' or ISNULL(@comanda_asis,'')<>''   
     begin   
      exec iauPozitieStoc @Cod=@Cod, @TipGestiune='', @Gestiune=@GestSt output, @Data=null, @CodIntrare=@CodISt output,   
       @PretStoc=@PStoc output, @Stoc=@Stoc output, @ContStoc=@CtStoc output, @DataExpirarii=null,   
       @TVAneex=null, @PretAm=null, @Locatie=null, @Serie=@SerieSt output,   
       @FltTipGest=null, @FltGestiuni=@listaGestiuniPozitie, @FltExcepGestiuni=@ExcGest, @FltData=@Data,   
       @FltCont=null, @FltExcepCont=@ExcCont, @FltDataExpirarii=null, @FltLocatie=null,   
       @FltLM=null, @FltComanda=@comanda_asis, @FltCntr=@contract , @FltFurn=null, @FltLot=null,   
       @FltSerie=@Serie, @OrdCont=@ContOrd, @OrdGestLista=@OrdGest  
       
      -- elimin gestiunea de rezervari, cand caut alt stoc (sa nu iau din ce e rezervat pe alt contract)   
      if @rezervareStocComenzi=1 and isnull(@CodISt,'')='' and isnull(@contract,'')<>''  
       set @listaGestiuniPozitie = replace(@listaGestiuniPozitie, @gestRezervariComenzi+';','')  
     end  
       
     -- caut stoc in lista de gestiuni din care se face TE automat  
     if isnull(@CodISt,'')=''  
      exec iauPozitieStoc @Cod=@Cod, @TipGestiune='', @Gestiune=@GestSt output, @Data=null, @CodIntrare=@CodISt output,   
       @PretStoc=@PStoc output, @Stoc=@Stoc output, @ContStoc=@CtStoc output, @DataExpirarii=null,   
       @TVAneex=null, @PretAm=null, @Locatie=null, @Serie=@SerieSt output,   
       @FltTipGest=null, @FltGestiuni=@listaGestiuniPozitie, @FltExcepGestiuni=@ExcGest, @FltData=@Data,   
       @FltCont=null, @FltExcepCont=@ExcCont, @FltDataExpirarii=null, @FltLocatie=null,   
       @FltLM=null, @FltComanda='', @FltCntr='' , @FltFurn=null, @FltLot=null,   
       @FltSerie=@Serie, @OrdCont=@ContOrd, @OrdGestLista=@OrdGest  
    end  
      
    --select isnull( convert(varchar(300),@GestSt), '@gestst is null')  
    if @codIntrareInDenumire=1 or @GestSt is null  
    begin  
     -- daca nu am gasit stoc, stabilesc gestiunea de vanzare.  
     set @GestSt =   
       (case when @gestPozitie<>@GestBon then @gestPozitie  -- daca in pozitii e alta gestiune decat in antet, ramane ea.  
         else -- vand din prima gestiune disponibila.  
          -- la vanzare servicii din alte gestiuni, nu se va gasi in par, si las @gestpozitie.  
          isnull((select top 1 [dbo].[fStrToken](val_alfanumerica, 1, ';')   
           from par where Tip_parametru='PG' and Parametru=@GestBon), @gestpozitie) end )  
     --select @GestSt '@GestSt after attrib'  
     if @codIntrareInDenumire=1  
      set @CodISt=@Serie  
     else  
      set @CodISt=(case when @TipNom<>'S' and @AreSerii=1 then '' else @Serie end)      
     set @PStoc=@ExcCont  
     set @Stoc=@CantRam  
     set @CtStoc=''  
     set @SerieSt=(case when @TipNom<>'S' then @Serie else '' end)  
    end  
      
    if @CantRam>=0.001 and @CantRam>@Stoc set @CantDesc=@Stoc  
    else set @CantDesc=@CantRam  
      
    set @CantRam=@CantRam-@CantDesc  
  
    -- transfer automat in GESTPV daca nu e pe stoc.  
    -- doar pentru AC-uri  
    if @TipDoc='AC' and @TipNom<>'S' and @NuTEAC=0  
    begin  
     --select 'te',  @GestSt '@GestSt', @GestBon '@GestBon', @gestPozitie '@gestPozitie'  
       
     if @DetaliereBonuri=0  
      set @NrTE=left('TE'+left(replace(convert(char(10),@Data,103),'/',''),4)+rtrim(@GestSt),8)  
     else  
      set @NrTE=@NrDoc  
     set @CodIPrim=''  
       
     --select 'te2',  @GestSt '@GestSt', @GestBon '@GestBon'  
     -- scriu TE doar daca am gasit stoc(@gestst <>'') si daca stocul gasit e in alta gestiune decat cea de vanzare  
     if isnull(@GestSt,'')<>'' and isnull(@GestSt,'')<>@GestBon  
     begin  
      exec scriuTE @Numar=@NrTE, @Data=@Data, @GestPred=@GestSt, @GestPrim=@GestBon, @GestDest='',   
       @Cod=@Cod, @CodIntrare=@CodISt, @CodIPrim=@CodIPrim output, @CodIPrimNou=@CodITE,   
       @Cantitate=@CantDesc, @LocatiePrim='', @PretAmPrim=@Pret, @CategPret=@CategP,  
       @Valuta='', @Curs=0, @LM=@LM, @Comanda=@comanda_asis, @ComLivr='', @Jurnal=@Jurn, @Stare=5,   
       @Barcod=@Barcod, @Schimb=0, @Serie=@SerieSt, @Utilizator=@Vanz, @PastrCtSt=0,  
       @Valoare=0, @TotCant=0  
        
      set @CodISt=@CodIPrim  
     end  
     set @GestSt=@GestBon  
    end  
      
    set @TVAPoz=(case when abs(@CantRam)<0.001 then @SumaTVA-@TVADesc else 0 end)  
    if @TipDoc='AC' set @tipTVA=0 -- bonurile de casa nu pot lucra cu TVA neinregistrat   
    if @tipTVA=1   
    begin -- in pozdoc se pune =2 pentru "TVA neinregistrat"  
     set @tipTVA=2   
     set @CotaTVA=0  
     set @TVAPoz=0  
    end  
      
    if @TipDoc='TE'  
    begin  
     declare @gestprim varchar(20)  
     set @gestprim = (select bon.value('(/date/document/@gestprim)[1]','varchar(50)')   
          from antetBonuri where idAntetBon=@idAntetBon)  
       
     set @xml = (select '' as subtip, @NrDoc as numar, @Data as data, @Client as tert,   
      @GestSt as gestiune, @gestprim as gestiune_primitoare,  
      @Cod as cod, @CodISt as cod_intrare, @CantDesc as cantitate, @LM as lm, @contract as contract,  
      0 as discount, @Jurn as jurnal, 5 as stare, @vanzbon as utilizator, @SerieSt as serie, @Barcod barcod,  
      @CategP as categ_pret,@PretAm as pret_amanunt, @PValuta as pret_valuta  
      for xml raw)  
     --exec scriuTE @NrDoc,@Data,@GestSt,@Client,'',@Cod,@CodISt,'',0,@CantDesc,'',0,@CategP,'',0,@LM,@Com,'',@Jurn,5,@Barcod,0,@SerieSt,@Vanz,0,0,0  
     exec wScriuTE @xml  
    end  
    else  
    begin  
     --select 'ap',  @GestSt '@GestSt', @GestBon '@GestBon'  
     if @TipDoc='AC' and @TipNom='S'  
      set @GestSt=@GestBon  
     declare @pozNoua bit  
     set @pozNoua=(case when @DetaliereBonuri=1 then 1 else 0 end )  
     exec scriuAviz @Tip=@TipDoc,@Numar=@NrDoc,@Data=@Data,@Tert=@Client,@PctLiv=@PctLiv,  
      @CtFact=@CtFact output,@Fact=@NrDoc,@DataFact=@Data,@DataScad=@dataScad,  
      @Gest=@GestSt,@Cod=@Cod,@CodIntrare=@CodISt, @Cantitate=@CantDesc,@PretValuta=@PValuta,  
      @Valuta='',@Curs=0,@Discount=@Disc,@PretVanz=@PVanz,@CotaTVA=@CotaTVA,  
      @SumaTVA=@TVAPoz output,@PretAm=@PretAm,@CategPret=@CategP,@LM=@LM,  
      @Comanda=@comanda_asis, @ComLivr=@contract,@Jurnal=@Jurn,@Stare=5,@Barcod=@Barcod,  
      @TipTVAsauSchimb=@tipTVA,@Suprataxe=0,@Serie=@SerieSt,@Utilizator=@Vanz,  
      @ValFact=0,@ValTVA=0,@ValValuta=0,@NrPozitie=0, @PozitieNoua=@pozNoua  
    end  
    set @TVADesc=@TVADesc+@TVAPoz  
   end ----------------------------------------- end pozitie normala -----------------------------------------  
  end -- end bucla while pentru spargere pe cod intrare  
    
  -- update pentru devize auto  
  -- daca e completat ceva in campul comanda_asis, verific in XML daca e deviz si actualizez pe deviz.  
  if isnull(@comanda_asis,'')<>'' and exists (select 1 from sysobjects where name='pozdevauto')   
  begin  
   declare @codDeviz varchar(20), @pozDeviz int  
   select @xml=bon   
    from antetBonuri a where a.IdAntetBon=@idAntetBon  
     
   -- verific daca s-a finalizat un deviz  
   select @codDeviz = isnull(pozitie.bon.query('data(@coddeviz)').value('.', 'varchar(80)'),''),  
     @pozDeviz = isnull(pozitie.bon.query('data(@pozdeviz)').value('.', 'varchar(80)'),0)--pozdeviz e null pentru linia de manopera(care se cumuleaza)  
    from @xml.nodes('/date/document/pozitii/row[@nrlinie=sql:variable("@NrLin")]') pozitie(bon)  
     
   if @codDeviz<>''    
   begin  
    -- scriu numarul facturii in deviz si schimb starea.  
    update pozdevauto  
      set Numar_aviz=@NrDoc, Data_facturarii=@Data, Stare_pozitie=3  
     where Cod_deviz = @codDeviz   
     and (@pozDeviz=0 or Pozitie_articol = @pozDeviz)   
     and (@pozDeviz>0 or Tip_resursa='M')  
      
    -- salvez faptul ca am modificat pozitia aceasta de deviz.   
    -- daca sunt erori, anulez aceste modificari.  
    if not exists (select * from @devize where cod_deviz=@codDeviz and pozitie=@pozDeviz)  
     insert into @devize(cod_deviz, pozitie)  
      values (@codDeviz, @pozDeviz)  
   end  
   -- schimb stare deviz  
   if not exists (select * from pozdevauto where cod_deviz = @coddeviz and stare_pozitie < 3)  
    update devauto set Stare=3 where cod_deviz = @coddeviz  
  end -- end update pentru devize auto  
 end -- end @Incas=0 (linia = vanzare produs)  
   
 if @TipDoc='AP' and @Incas=1  
 begin  
  declare @contCasa varchar(20)  
  if @bTip='36'  
   set @contCasa=ISNULL((select valoare from proprietati where tip='UTILIZATOR' and Cod_proprietate='CONTCARD' and cod=@Vanz),'5114')  
  else  
   set @contCasa=ISNULL((select valoare from proprietati where tip='UTILIZATOR' and Cod_proprietate='CONTCASA' and cod=@Vanz),'5311')  
    
  declare @denTert varchar(80),@nr_poz_out int  
  set @denTert=ISNULL(rtrim((select top 1 denumire from terti where tert=@Client)),'')  
  -- citesc cont factura (e returnat de scriuAviz, dar cand vom folosi wScriuPozdoc nu il vom mai avea).  
  select @CtFact=rtrim(Cont_factura)  
   from pozdoc p   
   where p.Subunitate=@subunitate and p.Tip=@TipDoc and p.Numar=@NrDoc   
    and p.Data=@Data and p.Cod=@Cod  
    
  exec scriuPozplin @Cont=@contCasa, @Data=@data, @Numar=@NrBon, @Plata_incasare='IB',   
    @Tert=@Client, @Factura=@NrDoc, @Cont_corespondent=@CtFact,   
    @Suma=@Pret, @Valuta='', @Curs=0, @Suma_valuta=0,   
    @TVA11=0, @TVA22=0, @Explicatii=@denTert, @LM=@LM, @Comanda='',   
    @Utilizator=@vanzbon, @Numar_pozitie=@nr_poz_out output, @Jurnal='',   
    @Marca='', @DecontEfect='', @DataScadDecEf=@data  
 end  
 --Aici se vor trata incasarile   
 exec wMutBTBP @Casa,@Vanz,@Data,@NrBon,@NrLin,@TipDoc,@Incas,@Cant,@CantExc8,0  
 fetch next from @tmpbon into @Incas,@Casa,@Data,@NrBon,@Vanz,@NrLin,@TipDoc,@Client,@Cod,@AreSerii,@Serie,@Coef,@Cant,@CotaTVA,@SumaTVA,@Pret,@Disc,@Barcod,@TipNom,@LM,@comanda_asis,@dataScad,@CategP,@PctLiv,@contract,@Jurn,@AP418,@factura,@bTip, @tipTV
A, @gestPozitie, @UID, @idAntetBon  
 set @nFetchStatus=@@fetch_status  
   
 /* operatii de facut dupa descarcarea unui bon */  
 if (@nFetchStatus<>0 or @CasaAnt<>@Casa or @DataAnt<>@Data or @NrBonAnt<>@NrBon or @VanzAnt<>@Vanz)   
 begin  
  -- apelare procedura specifica care sa faca alte operatii.  
  if exists (select 1 from sysobjects where type='P' and name='wDescarcBonSP2')  
  begin  
   set @xml=(select @idAntetBon idAntetBon for xml raw)  
   exec wDescarcBonSP2 @sesiune=@sesiune, @parXML=@xml  
  end  
    
  -- LEGACY: apelare procedura specifica care sa faca alte operatii.  
  if exists (select 1 from sysobjects where type='P' and name='DescarcBonSP')  
   exec DescarcBonSP @CasaAnt,@DataAnt,@NrBonAnt,@VanzAnt,@TipDoc,@NrDoc  
    
  -- apelare procedura care sa trateze puncte de fidelizare.  
  if exists (select 1 from sysobjects where type='P' and name='CalculPuncteBon')  
  begin  
   set @xml=(select @idAntetBonAnt idAntetBon for xml raw)  
   exec CalculPuncteBon @sesiune=@sesiune, @parXML=@xml  
  end  
  if @facturiDefinitive=1 and @TipDoc='AP'  
  begin  
   if exists (select 1 from incfact where subunitate=@subunitate and Numar_factura=@NrDoc and Numar_pozitie=1)  
    update incfact set mod_tp='D' where subunitate=@subunitate and Numar_factura=@NrDoc and Numar_pozitie=1  
   else   
    INSERT INTO incfact(Subunitate,Numar_factura,Numar_pozitie,Mod_plata,Serie_doc,Nr_doc,data_doc,suma_doc,datasc_doc,mod_tp,info_tp,Tert,Cont,Loc_de_munca,Utilizator,Data_operarii,Ora_operarii,Jurnal)  
    select @subunitate, @NrDoc, 1, '', '', @NrDoc, @DataAnt, 0, @dataScadAnt, 'D', '', @ClientAnt,'','',@VanzAnt, @DataAnt, '',''  
  end  
 end  
 select @CasaAnt=@Casa,@DataAnt=@Data,@NrBonAnt=@NrBon,@VanzAnt=@Vanz,@dataScadAnt=@dataScad,@ClientAnt=@Client, @UidAnt=@UID, @idAntetBonAnt=@idAntetBon  
end  
  
if @CuTranzactii=1  
 commit transaction descarcaBon  
  
/*   
-- linii pentru debug  
  
select * from pozdoc   
where Subunitate='1' and data=@DataAnt  
and Numar=@NrDoc  
order by data desc, tip  
  
raiserror('in lucru...',11,1)  
*/  
end try  
begin catch  
 set @msgEroare = ERROR_MESSAGE()+'(wDescarcBon)'  
   
 if @CuTranzactii=1 and EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'descarcaBon')              
  ROLLBACK TRAN descarcaBon  
 else  
 -- daca sunt erori, mut inapoi in bt tot bonul si sterg din pozdoc documentul  
 -- NEFUNCTIONAL pentru cumulare bonuri pe un AC.  
 if @idAntetBon>0  
 begin  
    
  if @TipDoc in ('AP', 'TE') -- la facturi si transferuri, sterg tot timpul din pozdoc  
   delete from pozdoc where Subunitate=@subunitate and tip=@tipDoc and data=@Data and Numar=@NrDoc and stare=5  
    
  -- daca nu se cumuleaza toate bonurile pe un AC, sterg AC-ul partial  
  -- daca e setarea cu detaliere, il las in pace - vor fi erori.  
  if @tipDoc='AC' and @DetaliereBonuri=1   
   delete from pozdoc where Subunitate=@subunitate and tip in ('TE', 'AC') and data=@Data and Numar=@NrDoc and stare=5  
    
  -- anulare modificari in devize  
  if exists (select * from @devize) and exists (select 1 from sysobjects where name='pozdevauto')  
  begin  
   update p  
     set stare_pozitie=2, numar_aviz='', Data_facturarii='1901-01-01'  
    from pozdevauto p  
    inner join @devize d on p.cod_deviz=d.cod_deviz and p.Pozitie_articol=d.pozitie  
    
   update da  
     set da.stare=2  
    from devauto da  
    inner join (select distinct cod_deviz from @devize) d on da.cod_deviz=d.cod_deviz  
    where da.Stare=3  
      
     
   if not exists (select * from pozdevauto where cod_deviz = @coddeviz and stare_pozitie < 3)  
    update devauto set Stare=3 where cod_deviz = @coddeviz  
  end  
    
  -- pentru descarcare bonuri cu cumulare bonuri in un AC, nu mai fac nimic.   
  -- la TE si AP si bonuri detaliate, mut toate pozitiile in bt, pt. ca le-am sters din pozdoc mai sus  
  if @tipDoc<>'AC' or @DetaliereBonuri=0  
  begin  
   insert bt  
   (Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM,   
    Cantitate, Cota_TVA, Tva, Pret, Total, Retur,   
    Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount,   
    lm_real, Comanda_asis,[Contract], idAntetBon)  
   select Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM,   
    Cantitate, Cota_TVA, TVA, Pret, Total, Retur,   
    Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount,   
    lm_real, Comanda_asis,[Contract], idAntetBon  
   from bp where idAntetBon=@idAntetBon  
    
   delete from bp where idAntetBon=@idAntetBon  
  end  
 end  
end catch  
  
begin try  
 -- incerc sa inchid cursoarele doar daca sunt deschise  
 if CURSOR_STATUS('variable','@tmpbon') >= 0  
  close @tmpbon  
 if CURSOR_STATUS('variable','@tmpbon') >= -1  
  deallocate @tmpbon  
end try  
begin catch end catch  
  
if len(@msgEroare)>0  
 raiserror(@msgeroare,11,1)