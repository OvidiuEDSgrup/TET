--***  
create procedure [dbo].yso_wOPGenTEsauAPdinBK @sesiune varchar(50), @parXML xml   
as        
declare @Numar char(8) ,@GestPrim varchar(9),@PretAmPrim varchar(20),@CategPret int,@LM char(9),@LMdinBK char(9),@Stare int,  
  @Utilizator char(10),@sub varchar(10),@ftert varchar(20),@fcontract varchar(20),@fdata datetime,@gestiune varchar(20),  
  @tip varchar(2),@datadoc datetime,@observatii varchar(200),@nrmijtransp varchar(13),@serieCI varchar(50), @numarCI varchar(50),   
  @eliberatCI varchar(50), @eroare varchar(200), @err int, @gesttr varchar(20),@faraMesaje bit, @input xml, @numedelegat varchar(100),  
  @GestDest varchar(20), @cod varchar(30)  
  
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output          
  
select @Stare=ISNULL(@parXML.value('(/parametri/@stare)[1]', 'varchar(20)'), ''),  
  @fcontract=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), ''),  
  @ftert=upper(ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'), '')),  
  @fdata=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),  
  @gestiune=ISNULL(@parXML.value('(/parametri/@gestiune)[1]', 'varchar(20)'), ''),  
  @GestPrim=ISNULL(@parXML.value('(/parametri/@gestprim)[1]', 'varchar(20)'), ''),  
  @gesttr=ISNULL(@parXML.value('(/parametri/@gesttr)[1]', 'varchar(20)'), ''),  
  @numar=upper(ISNULL(@parXML.value('(/parametri/@numardoc)[1]', 'varchar(20)'), '')), -- numarul documentului generat. Daca nu se trimite, se genereaza din plaja.  
  @datadoc=ISNULL(@parXML.value('(/parametri/@datadoc)[1]', 'varchar(20)'), ''),  
  @LMdinBK=ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(20)'), ''),  
  @numedelegat=upper(ISNULL(@parXML.value('(/parametri/@numedelegat)[1]', 'varchar(50)'), '')),  
  @nrmijtransp=upper(ISNULL(@parXML.value('(/parametri/@nrmijltransp)[1]', 'varchar(50)'), '')),  
  @serieCI=upper(ISNULL(@parXML.value('(/parametri/@serieci)[1]', 'varchar(50)'), '')),  
  @numarCI=upper(ISNULL(@parXML.value('(/parametri/@numarci)[1]', 'varchar(50)'), '')),  
  @eliberatCI=upper(ISNULL(@parXML.value('(/parametri/@eliberatci)[1]', 'varchar(50)'), '')),  
  @observatii=upper(ISNULL(@parXML.value('(/parametri/@observatii)[1]', 'varchar(50)'), '')),  
  @faraMesaje=ISNULL(@parXML.value('(/parametri/@faramesaje)[1]', 'bit'), 0) -- flag folosit daca nu vrem afisarea de mesaje din procedura  
  
  
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
  
set @lm=(select top 1 valoare from proprietati where tip='UTILIZATOR' and cod=@Utilizator and cod_proprietate='LOCMUNCA' and valoare<>'')  
 if @LM is null  
  set @lm=ISNULL(nullif((select MAX(Loc_de_munca) from gestcor where Gestiune=@gestiune),''),@LMdinBK)  
  
begin try    
    if @numedelegat=''  
       raiserror('Numele delegatului nu este introdus',16,1)  
    if @nrmijtransp=''  
       raiserror('Numarul mijlocului de transport nu este introdus',16,1)     
    if @gesttr<>'' and @ftert<>'' and @GestPrim='' and @Stare ='1'  
      raiserror('Nu este permisa completarea gestiunii de transport in cazul in care comanda este facuta de un client!',16,1)  
    else if @GestPrim<>'' and @Stare='1' --and (@ftert<>'' or @ftert='')  
     set @tip='TE'  
 else if @GestPrim<>'' and @Stare='4' and @ftert=''  
  raiserror('Document deja transferat! Nu se poate genera transfer!',16,1)  
  -- in functie de completare gest. primitoare si stare: AP, TE sau mesaj de eroare  
    else if (@GestPrim<>'' or @GestPrim='') and @Stare in ('4','1') and @ftert<>'' --and (@GestPrim='' or @GestPrim<>'')  
             set @tip='AP'    
    else if @GestPrim='' and @ftert=''  
         raiserror('Document invalid , nu se poate genera transfer/factura deoarece nu este completata gestiunea prim/tert!Operatie anulata!',16,1)   
    else if @stare in ('6') --and (@GestPrim<>'' or @gestprim='') and (@ftert<>'' or @ftert='')   
         raiserror('Document in stare 6-Realizat, Nu se poate genera transfer/factura! ',16,1)  
    else if @stare=0  
      raiserror('Nu se poate genera un transfer/factura pentru comenzi in stare operat!',16,1)  
    else   
      raiserror('Nu se poate genera un transfer/factura',16,1)  
        
    if @GestTr<>''  
  begin  
     set @GestDest=@GestPrim   
     set @GestPrim=@gesttr  
  end  
 else   
     set @gestdest=isnull(@gestdest,'')  
 if @tip='TE'   
  if not exists (select 1 from pozcon p   
   inner join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert  
   where p.Subunitate=@sub and p.tip='BK' and p.contract=@fcontract and   
     con.stare ='1' --and p.tert=@ftert and p.data=@fdata   
    and (p.Cant_aprobata-p.Pret_promotional)>0.001) -- Pret_promotional este refolosit pt. cant. transferata   
   raiserror('Comanda selectata nu are pozitii de transferat - nu se poate genera un document de transfer',16,1)  
 else -- 'AP'  
  if not exists (select 1 from pozcon p   
   inner join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert  
   where p.Subunitate=@sub and p.tip='BK' and p.contract=@fcontract and con.stare in ('1','4') --and p.tert=@ftert and p.data=@fdata   
    and (p.Cant_aprobata-p.cant_realizata)>0.001)   
   raiserror('Comanda selectata nu are pozitii de facturat - nu se poate genera un aviz',16,1)  
     
 if @numar=''  
 begin   
  declare @fXML xml, @NrDocFisc varchar(10)  
  set @fXML = '<row/>'  
  set @fXML.modify ('insert attribute tipmacheta {"O"} into (/row)[1]')  
  set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')  
  set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')  
  exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output  
  set @Numar=@NrDocFisc  
 end  
 if @tip='TE' -- anexadoc  
     if not exists (select 1 from anexadoc where Subunitate=@sub and tip=@tip and numar=@numar and Data=@datadoc)  
   insert anexadoc  
   (Subunitate, Tip, Numar, Data, Numele_delegatului, Seria_buletin, Numar_buletin,   
   Eliberat, Mijloc_de_transport, Numarul_mijlocului, Data_expedierii, Ora_expedierii,   
   Observatii, Punct_livrare, Tip_anexa)  
   values (@sub, @tip, @numar, @datadoc, @numedelegat, @serieCI, @numarCI, @eliberatCI,   
    '', @nrmijtransp, '', '', @observatii, '', '')  
   
 else -- 'AP': anexafac  
     if not exists (select 1 from anexafac where Subunitate=@sub and Numar_factura=@numar)  
   insert anexafac  
   (Subunitate,Numar_factura,Numele_delegatului,Seria_buletin,Numar_buletin,Eliberat,Mijloc_de_transport,  
    Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii)  
   values (@sub, @numar, @numedelegat, @serieCI, @numarCI, @eliberatCI, '',   
           @nrmijtransp, @datadoc, '', @observatii)       
   
     select @CategPret = isnull((select top 1 valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET'   
        and cod= (case when @tip='TE' then @GestPrim else @gestiune end)), 1)  
      
 if @tip='TE'   
 begin     
  set @input=(select top 1 rtrim(@sub) as '@subunitate',@tip as '@tip', @numar as '@numar', convert(varchar(20),@datadoc,101) as '@data',  
         @gestiune as '@gestiune', @GestPrim as '@gestprim', @GestDest as '@contract',  
         @categpret as '@categpret', @lm as '@lm', @fcontract as '@factura',  
     (select   rtrim(p.cod) as '@cod', rtrim(p.cantitate) as '@cantitate',   
         isnull(convert(varchar(20),(select top 1 pret_cu_amanuntul from preturi where cod_produs=p.cod and   
               um=@CategPret order by data_inferioara desc)),0) as '@pamanunt',   
         con.valuta as '@valuta',convert(varchar(20),con.curs) as '@curs', @lm as '@lm'   
        from pozcon p   
        left outer join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert  
        left outer join terti tr on tr.subunitate=p.subunitate and tr.tert=p.tert  
        where p.Subunitate=@sub and p.tip='BK' and p.contract=@fcontract and (p.tert='' or p.tert=@ftert)and p.data=@fdata  
        and p.cant_aprobata-(case when @tip='TE' then p.Pret_promotional else p.cant_realizata end)>0.001  
       for xml PATH, TYPE)  
       for XML PATH, type)  
  exec wScriuPozdoc @sesiune,@input  
 end    
 else  
 begin  
  set @input=(select top 1 rtrim(@sub) as '@subunitate',@tip as '@tip' ,@ftert as '@tert',  
      @numar as '@numar', convert(varchar(20),@datadoc,101) as '@data', @categpret as '@categpret',  
      @LMdinBK as '@lm',@gestiune as '@gestiune',  @fcontract as '@contract',  
  (select convert(varchar(20),p.pret) as '@pvaluta', con.valuta as '@valuta',convert(varchar(20),con.curs) as '@curs',  
      --convert(varchar(20),p.suma_tva) as '@sumatva',   
      @LMdinBK as '@lm',  
      --isnull(convert(varchar(20),(select top 1 pret_cu_amanuntul from preturi where cod_produs=p.cod and   
      --         um=@CategPret order by data_inferioara desc)),0) as '@pamanunt',  
      rtrim(p.cod) as '@cod', rtrim(p.cantitate) as '@cantitate',@fcontract as '@contract'  
      /*startsp*/,p.Discount as '@discount'  
    from pozcon p   
     left outer join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert  
     left outer join terti tr on tr.subunitate=p.subunitate and tr.tert=p.tert  
     where p.Subunitate=@sub and p.tip='BK' and p.contract=@fcontract and (p.tert='' or p.tert=@ftert )and p.data=@fdata  
     and p.cant_aprobata-(case when @tip='TE' then p.Pret_promotional else p.cant_realizata end)>0.001  
    for xml PATH, TYPE)  
    for XML PATH, type)  
  exec wScriuPozdoc @sesiune,@input  
 end     
 declare @nrPozBK int, @nrPozAPsauTE int  
 select @nrPozBK=isnull((select count(distinct p.Cod) from pozcon p   
     left outer join con on con.subunitate=p.subunitate and con.Contract=p.contract and con.Data=p.data and con.tert=p.tert  
     left outer join terti tr on tr.subunitate=p.subunitate and tr.tert=p.tert  
     where p.Subunitate=@sub and p.tip='BK' and p.contract=@fcontract and (p.tert='' or p.tert=@ftert )and p.data=@fdata  
     and p.cant_aprobata-(case when @tip='TE' then p.Pret_promotional else p.cant_realizata end)>0.001),0),  
   @nrPozAPsauTE=(select count(distinct cod) from pozdoc where subunitate = @sub and tip = @tip and numar = @numar and   
        data = convert(varchar(20),@datadoc,101) and (tert = @ftert or @ftert=''))  
 /*startsp*/  
 if @tip='AP'  
  exec ProcGenAPBK 'AP',@numar,@datadoc  
 /*stopsp*/  
 if @faraMesaje!=1  
 begin  
  if @nrPozAPsauTE=0 -- n-a generat nici o pozitie   
   set @err=2  
  if @nrPozAPsauTE=@nrPozBK   
   select 'S-a generat cu succes documentul de tip '+rtrim(case when @tip='TE' then 'TE' else 'AP' end)+' cu numarul '+rtrim(@numar)+' din data de  '+ltrim(convert(varchar(20),@datadoc,103)) as textMesaj for xml raw, root('Mesaje')  
  else if @nrPozAPsauTE<@nrPozBK  
   select 'S-a generat partial documentul de tip ' +rtrim(case when @tip='TE' then 'TE' else 'AP' end)+ ' cu numarul '+rtrim(@numar)+' din data de  '+ltrim(convert(varchar(20),@datadoc,103)) as textMesaj for xml raw, root('Mesaje')  
  else if @err=2  
   select 'Nu s-a generat document! Stoc indisponibil!' as textMesaj for xml raw, root('Mesaje')  
    end  
end try   
begin catch   
 set @eroare='(wOPGenTEsauAPdinBK):'+ERROR_MESSAGE()   
  raiserror(@eroare, 16, 1)  
end catch   