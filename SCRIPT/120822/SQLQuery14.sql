/****** Object:  StoredProcedure [dbo].[wValidareDocumentPVSP]    Script Date: 06/13/2012 13:37:06 ******/  
create procedure [dbo].[wValidareDocumentPVSP1] @sesiune varchar(50), @parXML XML  
as  
declare @returnValue int  
set nocount on  
if exists(select * from sysobjects where name='yso_wValidareDocumentPVSP1' and type='P')        
begin  
 exec @returnValue = yso_wValidareDocumentPVSP1 @sesiune,@parXML  
 return @returnValue   
end  
  
set transaction isolation level read uncommitted  
declare /*generale*/   
  @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @utilizator varchar(10), @dinOffline int, @subunitate varchar(9),   
  @tert varchar(50), @CasaDoc int, @vanzDoc varchar(50),@DataDoc datetime, @DataScad datetime, @zileScadChar varchar(20)/* citesc in varchar pt. a interpreta null */,   
  @numarDoc int, @GESTPV varchar(20), @nFetch int,  
  @facturaDinBon bit, @observatii varchar(8000), @paramXmlString varchar(max), @UID varchar(50), @serieFactura varchar(20), @factura varchar(20),  
  @tipDoc varchar(2), @oraDoc varchar(6), @comandaASiS varchar(50)/*campul comanda din comenzi livrare */,   
  @comLivrare varchar(50), @cDataComenzii varchar(50), @eBon int, @LM varchar(50), @zileScadenta int, @categoriePret int,   
  @incasariPeFactura bit, @numarBonFact varchar(20)/*il pun varchar pt ca sa fie null cand nu e trimis, chiar daca e int*/,   
  @listaGestiuni varchar(max), @vanzareFaraStoc bit, @codiinden int, @eFactura bit, @eTransfer bit, @xml xml  
    
begin try  
  
 exec luare_date_par 'GE','FARASTOC', @vanzareFaraStoc output, null, null  
   
 exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
  
 exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output  
 exec luare_date_par 'PV', 'CODIINDEN', @codiinden output, 0, '' /* setarea e true daca e si codul de intrare in denumirea scanata */  
   
 /* citesc date antet document, locatie si delegat */  
 /*citesc cu // pt. ca la inceput se trimitea doar /document la validare(fara <date>) */  
 select @UID = @parXML.value('(//document/@UID)[1]','varchar(50)'),  
   @CasaDoc = @parXML.value('(//document/@casamarcat)[1]','int'),  
   @numarDoc = @parXML.value('(//document/@numarDoc)[1]','int'),  
   @numarBonFact = @parXML.value('(//document/@numarbon)[1]','varchar(20)'),/*la facturi cu incasari, trimit separat nr. de bon tiparit ca incasare factura*/  
   @tipDoc = @parXML.value('(//document/@tipdoc)[1]','varchar(2)'),  
   @serieFactura = @parXML.value('(//document/@seriefactura)[1]','varchar(20)'),  
   @factura = @parXML.value('(//document/@factura)[1]','varchar(20)'),  
   @DataDoc = @parXML.value('(//document/@data)[1]','datetime'),  
   @facturaDinBon = isnull(@parXML.value('(/date/document/@facturaDinBon)[1]','int'),0),  
   @zileScadChar = @parXML.value('(//document/@zileScad)[1]','varchar(20)'),  
   @DataScad = @parXML.value('(//document/@dataScad)[1]','datetime'),  
   @oraDoc = @parXML.value('(//document/@ora)[1]','varchar(6)'),  
   @tert = @parXML.value('(//document/@tert)[1]','varchar(50)'),  
   @comLivrare = @parXML.value('(//document/@comanda)[1]','varchar(50)'),  
   @cDataComenzii = @parXML.value('(//document/@datacomenzii)[1]','varchar(50)'),  
   @categoriePret=ISNULL(@parXML.value('(/row/@categoriePret)[1]', 'int'), ISNULL(@parXML.value('(//document/@categoriePret)[1]', 'int'), '1')),   
   @GESTPV = @parXML.value('(//document/@GESTPV)[1]','varchar(50)')  
  
 /*  completez date care nu sunt trimise in XML cu date implicite pe sesiune, utilizator, etc. */  
 select @eBon = (case when @tipDoc='AC' then 1 else 0 end),  
   @eFactura = (case when @tipDoc='AP' then 1 else 0 end),  
   @eTransfer = (case when @tipDoc='TE' then 1 else 0 end),  
   @vanzDoc = @utilizator,  
   @tert = isnull(@tert,''),  
   @GESTPV= (case when isnull(@GESTPV,'')<>'' then @GESTPV else dbo.wfProprietateUtilizator('GESTPV', @utilizator) end),  
   @listaGestiuni= dbo.wfListaGestiuniAtasatePV(@GESTPV)  
  
 IF OBJECT_ID('tempdb..#bonTempSP') IS NOT NULL  
  drop table #bonTempSP  
   
 /* tabel cu structura tabelei bt(+coloane in plus) in care se vor salva datele bonului curent */  
 -- a nu se modifica denumirea - poate e folosit prin SP-uri  
 CREATE TABLE #bonTempSP(Casa_de_marcat smallint NOT NULL,Factura_chitanta bit NOT NULL,Numar_bon int NULL/*la factura vine null*/,Numar_linie smallint NOT NULL,Data datetime NOT NULL,  
  Ora char(6),Tip char(2) NOT NULL,Vinzator char(10) NOT NULL,Client char(13) NOT NULL,Cod_citit_de_la_tastatura char(20) NOT NULL,CodPLU char(20) NOT NULL,  
  Cod_produs char(20) NOT NULL,Categorie smallint NOT NULL,UM smallint NOT NULL,Cantitate float NOT NULL,Cota_TVA real NOT NULL,Tva float NOT NULL,Pret float NOT NULL,  
  Total float NOT NULL,Retur bit NOT NULL,Inregistrare_valida bit NOT NULL,Operat bit NOT NULL,Numar_document_incasare char(20) NOT NULL,Data_documentului datetime NOT NULL,  
  Loc_de_munca char(9) NOT NULL,Discount float NOT NULL, o_pretcatalog float, tipNomencl char(1), cont_de_stoc varchar(50)  
  ,stocinstalatori bit, pretcomlivr float, disccomlivr float  
  ,pretamlista float, gestpredte char(9), discinitial float, discmax float, denumire char(150))  
    
 insert #bonTempSP(Casa_de_marcat,Factura_chitanta,Numar_bon,Numar_linie,Data,Ora,Tip,Vinzator,Client,    
  Cod_citit_de_la_tastatura,CodPLU,Cod_produs,Categorie,UM,Cantitate,Cota_TVA,Tva,Pret,    
  Total,Retur,Inregistrare_valida,Operat,Numar_document_incasare,Data_documentului,    
  Loc_de_munca,Discount, o_pretcatalog  
  ,stocinstalatori, pretcomlivr, disccomlivr  
  ,pretamlista, gestpredte, discinitial,discmax,denumire)  
 select @CasaDoc, @eBon as factura_chitanta, @numarDoc,   
 isnull(nrlinie,ROW_NUMBER() over (order by b.tip)) as linie,  
 @DataDoc as data, @oraDoc as ora, b.tip as tip, @vanzDoc as vinzator, @tert as client,   
 isnull(isnull(b.barcode,b.cod),'') as cod_tastatura, isnull(b.cod,'') as cod_plu, isnull(b.cod,'') as cod_produs,   
 '0'/*valabilitate - am lasat implicit 0 pt. linii tip incasare. La produse se face update mai jos */ as categorie,   
 ISNULL(b.um,1) as um, cantitate, isnull(b.cotatva,0) as cota_tva,   
 (case when @tipDoc='AP'   
  then round(round(isnull(b.pretcatalog,b.pret)/(1.00+isnull(b.cotatva,0)/100.00),3)*b.cantitate*(1-isnull(b.discount,0)/100.00)*isnull(b.cotatva,0.00)/100.00,2)   
  else round(b.valoare*isnull(b.cotatva,0)/(100.00+isnull(b.cotatva,0.00)),2) end) as tva,  
 (case when @tipDoc='AP' then round(isnull(b.pretcatalog,b.pret)/(1.00+isnull(b.cotatva,0)/100.00),3) else isnull(b.pretcatalog,b.pret) end) as pret,  
 (case when @tipDoc='AP' then round(isnull(b.pretcatalog,b.pret)/(1.00+isnull(b.cotatva,0)/100.00),3)*b.cantitate else b.valoare end) as total,  
 0 as retur, 1 as inregistrare_valida, '' as operat,   
 (case when @codiinden=1 and charindex('|',b.denumire)>1 then left(b.denumire,charindex('|',b.denumire)-1) else '' end) as nr_doc_incas,   
 '01/01/1901' as data_doc, isnull(gestiune,@GESTPV) as gestiune,  
 isnull(b.discount,0) as discount, o_pretcatalog  
 ,isnull(b.stocinstalatori,0) stocinstalatori  
 ,isnull(b.pretcomlivr,0) pretcomlivr  
 ,ISNULL(disccomlivr,0) disccomlivr  
 ,0 as pretamlista  
 ,b.gestpredte  
 ,0 as discinitial  
 ,0 as discmax  
 ,b.denumire as denumire  
 from (select     
  xA.row.value('@nrlinie', 'int') as nrlinie,  
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
  xA.row.value('@gestiune',' varchar(20)') as gestiune, -- se trimite pentru comenzi/devize  
  xA.row.value('@o_pretcatalog',' decimal(10,3)') as o_pretcatalog  
  ,xA.row.value('@yso_stocinstalatori',' bit') as stocinstalatori  
  ,xA.row.value('@yso_pretcomlivr',' decimal(17,5)') as pretcomlivr  
  ,xA.row.value('@yso_disccomlivr',' decimal(10,2)') as disccomlivr  
  ,xA.row.value('@yso_gestpredte',' varchar(9)') as gestpredte  
  from @parXML.nodes('//document/pozitii/row') as xA (row)  
  ) as b   
    
 update t  
 set categorie=n.categorie, tipNomencl=n.Tip, cont_de_stoc=n.Cont  
  ,pretamlista=coalesce(t.pretcomlivr,pr.Pret_cu_amanuntul,n.Pret_cu_amanuntul,0)  
  ,discinitial=isnull(t.disccomlivr,100*(1-t.pret/isnull(pr.Pret_cu_amanuntul,n.Pret_cu_amanuntul)))  
  ,discmax=(select top 1 CASE ISNUMERIC(valoare) when 1 then CONVERT(float,replace(Valoare,',','')) else null end   
    from proprietati pr   
    where pr.Valoare<>'' and pr.Cod<>'' and pr.tip='GRUPA' and pr.cod_proprietate='DISCMAX'   
      and n.Grupa like RTRIM(pr.Cod)+'%' order by pr.cod desc, pr.Valoare desc)  
 from #bonTempSP t inner join nomencl n on t.Cod_produs=n.cod  
  left join (select p.UM,p.Cod_produs, max(p.Pret_cu_amanuntul) Pret_cu_amanuntul   
     from preturi p group by p.UM,p.Cod_produs) pr on pr.Cod_produs=n.Cod   
   and pr.UM=isnull((select top 1 valoare from proprietati p where p.Tip='GESTIUNE' and p.Cod_proprietate='CATEGPRET'   
      and p.Cod=t.gestpredte and p.Valoare<>''),1)  
   
 -- verific sa nu fie pozitii cu acelasi cod si acelasi pret pentru ca e posibil sa li se dea acelasi cod de intrare   
 -- si atunci, daca vor vrea sa anuleze bonul, va da eroare pt ca unicitatea indexului pe docsters este dupa cod,cod_intrare  
   
 if exists (select 1 from #bonTempSP t where t.Tip='21' group by t.Cod_produs,t.Pret having COUNT(distinct t.Numar_linie)>1)  
  begin  
   set @ErrorMessage=null  
   select @ErrorMessage=ISNULL(@ErrorMessage,'')+CHAR(13)+RTRIM(t.Cod_produs)+'-'+RTRIM(max(n.Denumire))  
   from #bonTempSP t   
    inner join nomencl n on n.Cod=t.Cod_produs  
   group by t.Cod_produs,t.Pret having COUNT(distinct t.Numar_linie)>1  
     
   if isnull(@ErrorMessage,'')<>''  
   begin  
    set @ErrorMessage='Bon invalid! Urmatoarele articole avand acelasi pret trebuie unificate intr-o singura pozitie, insumand cantitatile: '  
     +@ErrorMessage  
    raiserror(@ErrorMessage,11,1)  
   end  
      
  end  
    
 IF OBJECT_ID('tempdb..#stocurisp1') IS NOT NULL  
  drop table #stocurisp1  
    
 -- tabela folosita la validare stoc pt. pozitii cu cant>0, si existenta pret_de_stoc pt pozitii cu cant<0  
 create table #stocurisp1(cod varchar(20), tipnom char(1), pret float, cantitate float, stoc float, gestiune varchar(20) constraint PK_cod_gestiunesp1 primary key(cod, gestiune))  
   
 -- la pozitii storno, verific existenta unui cod de intrare in stoc, pentru cand vor trebui scrise in pozdoc  
 -- identificarea pretului de stoc e tratat si in wDescarcBon  
 if exists (select 1 from #bonTempSP b where b.Cantitate<0.001)  
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
  truncate table #stocurisp1   
  insert into #stocurisp1(gestiune, tipnom, cod, pret)  
   select min(b.Loc_de_munca), max(b.tipNomencl), b.Cod_produs  
    , round(dbo.rot_pret(round(convert(decimal(15,5),b.pret*(1-b.Discount/100)),5),0),2)  
   from #bonTempSP b  
   where b.Cantitate<0.001  
   group by b.Cod_produs, b.Pret, b.Discount  
    
  -- verific daca sunt linii in tabela stocuri   
  -- practic daca e stoc=null, nu a fost linie si nu este pret_de_stoc  
  update st   
   set st.stoc=isnull(st.stoc,0)+s.stoc  
   from #stocurisp1 st  
   inner join   
    (select stocuri.Tip_gestiune, stocuri.cod, stocuri.Pret_cu_amanuntul, SUM(stocuri.stoc) stoc   
     from stocuri   
     inner join #stocurisp1 sf on stocuri.Cod=sf.cod  
     inner join dbo.split(@listaGestiuniPozitie,';') lg on Cod_gestiune=lg.Item   
     where Subunitate=@subunitate  
     group by stocuri.Tip_gestiune,stocuri.cod, stocuri.Pret_cu_amanuntul) s   
    on s.cod=st.cod and abs(s.Pret_cu_amanuntul-st.pret)<0.0009  
    
  declare @stocurisp1 xml=(select * from #stocurisp1 for xml raw)  
  
  if exists ( select * from #stocurisp1 st where st.tipnom<>'S' and st.stoc is null )  
  begin  
   set @ErrorMessage='Urmatoarele produse nu pot fi stornate pt. ca nu au fost vandute din aceasta gestiune:'  
   select @ErrorMessage=@ErrorMessage+CHAR(13)+RTRIM(Denumire)+' ('+RTRIM(nomencl.cod)+')'  
   from #stocurisp1  
   inner join nomencl on #stocurisp1.cod=nomencl.cod  
   where #stocurisp1.stoc is null  
     
   raiserror(@errormessage,11,1)  
  end  
 end  
   
 if exists (select 1 from #bonTempSP b where b.discmax is not null and ISNULL(b.Discount,0)+ISNULL(b.discinitial,0)>b.discmax)  
 begin  
  set @ErrorMessage='Discountul introdus depaseste maximul pe grupa la articolele urmatoare: '  
  select @ErrorMessage=@ErrorMessage+CHAR(13)+RTRIM(b.denumire)+' ('+RTRIM(b.Cod_produs)+')'  
   +', DISCMAX: '+ rtrim(CONVERT(decimal(10,2),b.discmax))  
  from #bonTempSP b   
  where ISNULL(b.Discount,0)+ISNULL(b.discinitial,0)>ISNULL(b.discmax,0)  
  raiserror(@ErrorMessage,11,1)  
 end  
   
end try  
begin catch   
 SELECT @ErrorMessage = ERROR_MESSAGE()+' (wValidareDocumentPVSP1)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
end catch  
  
begin try  
 IF OBJECT_ID('tempdb..#bonTempSP') IS NOT NULL  
  drop table #bonTempSP  
    
 IF OBJECT_ID('tempdb..#stocurisp1') IS NOT NULL  
  drop table #stocurisp1  
end try   
begin catch   
end catch  
  
if LEN(@ErrorMessage)>0  
 RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )  
  