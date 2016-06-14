--***  
create procedure wTipFormular @sesiune varchar(50), @parXML xml                   
as  
set nocount on   
set transaction isolation level read uncommitted  
begin try   
  
declare  @nrform varchar(13),@tip varchar(2),@numar varchar(20),@data datetime,@inXML int, @gestiune varchar(20), @Subunitate varchar(13),  
@tert varchar(20), @factura varchar(20), @contract varchar(20), @debug bit, @selectDeExecutat nvarchar(max),  
@tipformular varchar(2), /*folosit la salvarea sablonului in propr. pt ca @tip se schimba in unele cazuri*/  
@sablon nvarchar(max),@cPtRez nvarchar(4000), @i int,@j int,@lung int , @numeFisier varchar(1000),  
@cColoana varchar(255), @cTextSelect nvarchar(max), @dataStart datetime, @rand int,@maxrand int,@val varchar(max), @cmdShellCommand varchar(4000),   
@fisierSablon varchar(1000), @indexInceputNumeSablon int, @numeSablon varchar(100), @pathSablonDezarhivat varchar(1000), @existaDocx bit, @xml xml,  
@raspunsTMP nvarchar(max), @raspunsFinal nvarchar(max),@start int,@stop int, @cHostid varchar(10),@directorFormulare varchar(1000),@cFisierCuPath varchar(1000),@utilizator varchar(255),  
@eroareSelect int,@msgeroare varchar(1000),@nivel int,@nivelold int, @raspunsCmd int, @numeFisierCurent varchar(1000), @cursorStatus smallint,  
@idFisierDocx int/* prin aceasta variabila identific ce fisier din docx parcurg. Se proceseaza header1.xml, footer1.xml si document.xml */,  
@ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @scriuavnefac int, @extensia varchar(20),@eXML int,  
@numeProcedura varchar(255), @clauzaFrom varchar(1000), @clauzaWhere varchar(1000), @clauzaOrderBy varchar(1000),   
@numeTabelTemp varchar(100),  --tabela in care se scriu datele care sa apara in fisierul final.  
@numeTabelCuText varchar(100)  -- aici se salveaza fisierul generat, pt. ca sa nu stea in ram. la sfarsit se face bcp out din tabela.  
  
declare @coloaneDisponibile table(coloana varchar(255) primary key)  
declare @coloaneLipsa table(coloana varchar(1000)) -- nu pun primary key  
  
--print '0 start' set @dataStart=GETDATE()  
  
select @nrform =  @parXML.value('(/row/@nrform)[1]','varchar(13)'),   
  @tip = @parXML.value('(/row/@tip)[1]','varchar(2)'),   
  @tipformular = @parXML.value('(/row/@tip)[1]','varchar(2)'),   
  @numar = isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'),''),   
  @tert = isnull(@parXML.value('(/row/@tert)[1]','varchar(20)'),''),   
  @numeFisier = @parXML.value('(/row/@numefisier)[1]','varchar(50)'), -- citesc numele fisierului cu extensia lui-> frame-ul stie sa deschida in functie de extensie  
  @directorFormulare = @parXML.value('(/row/@directoroutput)[1]','varchar(500)'), -- Path-ul unde se va scrie fisierul. Daca se trimite in XML, nu se mai citeste din parametri.  
  @scriuavnefac=ISNULL(@parXML.value('(/row/@scriuavnefac)[1]','int'),1),   
  @data = @parXML.value('(/row/@data)[1]','datetime'),  
  @gestiune = isnull(@parXML.value('(/row/@gestiune)[1]','varchar(20)') ,''),  
  @Subunitate = isnull(@parXML.value('(/row/@subunitate)[1]','varchar(20)') ,'1'),  
  @inXML = isnull(@parXML.value('(/row/@inXML)[1]','int'),0), -- vine 1 din PVria sau aplicatie AIR si returneaza XML-ul pt. scriere pe calc. client  
  @debug = isnull(@parXML.value('(/row/@debug)[1]','bit'),0), -- daca e 1, afisez selectul rulat pt. date  
  @factura=@numar,  
  @cTextSelect=''  
    
if @tip in ('BF','BK')   
 set @contract = @numar  
set @contract=isnull(@contract,'')  
  
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null set @utilizator='ASiSria'  
  
----------------------------- calc lungimea maxima a coloanei terminal in avnefac -----------------------------  
set @i = (SELECT min(clmns.max_length) FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id where tbl.name='avnefac' and clmns.name= 'terminal' )  
  
----------------------------- initializari -----------------------------  
select @cHostid=LEFT(replace(@utilizator,'.',''),@i),  
  @directorFormulare=isnull(@directorFormulare,(select top 1 rtrim(val_alfanumerica) from par where Tip_parametru='AR' and Parametru='CALEFORM')),  
  @i=0, @eroareSelect=0,  
  @numeTabelTemp='##rasp'+@cHostID, -- daca se schimba sa nu mai fie ##, sa se umble si la comenzile de drop pt. tabela.  
  @numeTabelCuText='##form'+@cHostID  
  
if @tip = 'BY' --> chemat din consulatare bonuri - bon factura - factura fiscala  
begin  
 set @tip='AP'  
 if @parXML.value('(/row/@factura)[1]','varchar(20)') is not null -- cand se adauga seria in numar si nr_bon <> factura  
  set @numar = @parXML.value('(/row/@factura)[1]','varchar(20)')  
end  
if @tip = 'BC' --> chemat din consulatare bonuri - bon chitanta - factura din bonuri  
begin  
 set @tip='AP'  
 set @numar = @parXML.value('(/row/@factura)[1]','varchar(20)')  
 set @data = convert(datetime,@parXML.value('(/row/@data_facturii)[1]','varchar(20)') ,101)   
 if isnull(@numar,'')=''  
   raiserror('Bonul nu are atasat factura!',16,1)   
end  
if @tip = 'AI'   
 set @factura = @parXML.value('(/row/@factura)[1]','varchar(20)')   
if @tip = 'RE' or  @tip = 'DE'--> registru de casa/banca  
 set @numar = @parXML.value('(/row/@cont)[1]','varchar(20)')   
if @tip = 'SL' --> chemat din consulatare date lunare salarii  
 set @numar=@parXML.value('(/row/@marca)[1]','varchar(6)')  
   
if @tip = 'AB'or @tip = 'AL' OR @tip='OB'--> documente bugetari  
begin  
    set @numar=@parXML.value('(/row/@numar)[1]','varchar(20)')   
 set @factura = @parXML.value('(/row/@indbug)[1]','varchar(20)')   
end   
if @tip in ('FP','FL','FI','PL') --> Fise activitate masini  
 set @numar = @parXML.value('(/row/@fisa)[1]','varchar(20)')   
  
----------------------------- insert in anexafac -----------------------------  
if not exists (select * from anexafac where subunitate=@Subunitate and Numar_factura=@numar)   
begin   
 insert into anexafac (Subunitate,Numar_factura,Numele_delegatului,Seria_buletin,Numar_buletin,   
 Eliberat,Mijloc_de_transport,Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii)   
 values (@Subunitate,@numar,'','','','','','',getdate(),'','')   
end   
  
----------------------------- insert in avnefac -----------------------------  
if @scriuavnefac=1  
begin  
 delete from avnefac where terminal=@cHostid   
 insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,Factura,Contractul,   
 Data_facturii,Loc_munca,Comanda,Gestiune_primitoare,Valuta,Curs,Valoare,Valoare_valuta,Tva_11,Tva_22,   
 Cont_beneficiar,Discount)   
 values (@cHostid,@Subunitate,@tip,@numar,@gestiune,@data,@tert,@factura,@contract,   
 convert(datetime,(convert(varchar,getdate(),101)),101),'','','','',0,0,0,0,0,'',0)   
end   
  
----------------------------- validari si curatenie tabele temp -----------------------------  
if @directorFormulare is null and @inXML = 0  
 raiserror ('Nu este configurat directorul unde se salveaza formularele! Configurati parametrul "AR", "CALEFORM", -> val_alfa ',11,1)  
  
if exists(select * from tempdb.sys.objects where name = @numeTabelTemp)  
begin   
 set @cTextSelect='drop table '+@numeTabelTemp  
 exec (@cTextSelect)   
end  
  
if exists(select * from tempdb.sys.objects where name = @numeTabelCuText)  
begin   
 set @cTextSelect='drop table '+@numeTabelCuText  
 exec (@cTextSelect)   
end  
-- atentie, numele #form... e folosit si in procedura wTipFormularAS2000  
set @cTextSelect='create table '+@numeTabelCuText+' (id int identity not null, valoare varchar(max) null )  
CREATE UNIQUE CLUSTERED INDEX IX_f on '+@numeTabelCuText+' (id)'  
exec (@cTextSelect)   
  
delete from tnivel where hostid=@cHostID  
  
begin try  
set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='listaFisiere' and session_id=@@SPID )  
if @cursorStatus=1   
 close listaFisiere   
if @cursorStatus is not null   
 deallocate listaFisiere   
end try begin catch end catch  
  
-- creare tabela in care se analizeaza raspunsul comenzilor cmdShell  
CREATE TABLE #raspCmdShell(raspunsCmdShell Varchar(MAX))  
  
----------------------------- apelproc - caut linie si rulez procedura daca exista -----------------------------  
set @cTextSelect=null  
  
select @i=CHARINDEX('apelproc', expresie)+9, @j = CHARINDEX(')',expresie,@i), @numeProcedura=SUBSTRING(expresie,@i, @j - @i),  
  @cTextSelect= coalesce(@cTextSelect,'')+   
   'exec '+@numeProcedura+' @sesiune'+ CHAR(10)  
from formular  
where formular = @nrform  
and CHARINDEX('apelproc', expresie)>0  
  
if exists(select * from sysobjects where name=@numeProcedura and type='P')  
 exec sp_executesql @statement=@cTextSelect, @params=N'@sesiune as varchar(max)', @sesiune = @sesiune  
----------------------------- end apelproc - caut linie si rulez procedura daca exista -----------------------------  
  
set @cTextSelect=null  
select @clauzaFrom=rtrim(a.CLFrom), @clauzaWhere=RTRIM(a.CLWhere), @clauzaOrderBy=RTRIM(a.CLOrder)  
from antform a  
where a.Numar_formular = @nrform  
  
begin try  
 if @clauzaFrom='procedura'  
 begin  
  set @numeProcedura=@clauzaWhere  
  ----------------------------- formare date cu procedura -----------------------------  
  set @cTextSelect='exec '+@numeProcedura+' @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output'+CHAR(13)+  
   'set @maxrand = isnull((select count(*) from '+@numeTabelTemp+'),0)'   
  SET @selectDeExecutat=@cTextSelect  
  exec sp_executesql @statement=@cTextSelect, @params=N'@sesiune as varchar(max), @parXML as xml, @numeTabelTemp as varchar(1000) output, @maxrand as int output',   
    @sesiune = @sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output, @maxrand=@maxrand output  
  
  if @maxrand=0  
   raiserror('Comanda SQL folosita pentru luarea datelor nu a returnat date!',11,1)  
  ----------------------------- end formare date cu procedura -----------------------------  
 end  
 else  
 begin  
  ----------------------------- formare select pt. luare date -----------------------------  
  set @cTextSelect=null  
  select @cTextSelect = isnull(@cTextSelect+', ','set transaction isolation level read uncommitted '+char(13)+'select ')+   
   'rtrim('+convert(varchar(8000),f.expresie)+') as ['+rtrim(f.obiect)+']'  
  from formular f where formular=@nrform and obiect<>''   
  
  set @cTextSelect=@cTextSelect+char(13)+' into '+@numeTabelTemp+' '+char(13)+  
   @clauzaFrom+char(13)+  
   'WHERE '+ @clauzaWhere+char(13)+  
   'and avnefac.terminal='+quotename(@cHostid,'''')+' '+char(13)+   
   @clauzaOrderBy  
  ----------------------------- end formare select pt. luare date -----------------------------  
  ----------------------------- rulare select pt. luare date -----------------------------  
  set @selectDeExecutat=@cTextSelect -- selectul trimis spre frame daca sunt erori  
  --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' Incep rulare select'  
  exec (@cTextSelect)   
  set @maxrand=@@rowcount   
  --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' Am rulat select. '+convert(varchar,@maxrand)+' randuri in total'  
  if @cTextSelect is null   
   raiserror('Formularul ales nu este configurat!',11,1)  
  if @maxrand=0  
   raiserror('Formularul nu poate fi generat deoarece comanda SQL rulata nu a returnat date!',11,1)  
  ----------------------------- end rulare select pt. luare date -----------------------------  
 end  
end try  
begin catch  
 set @eroareSelect=1  
 SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
 RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )  
end catch  
  
-- salvez coloanele disponibile in tabela - daca sunt obiecte cu alt nume, se ignora.  
insert into @coloaneDisponibile(coloana)  
select distinct sc.name from tempdb.sys.columns sc where sc.object_id=object_id('tempdb..'+@numeTabelTemp)  
  
----------------------------- pregatire tabela pt luare date mai rapid -----------------------------  
set @cTextSelect='alter table '+@numeTabelTemp+' add numarrand int identity'   
exec (@cTextSelect)   
set @cTextSelect='CREATE UNIQUE CLUSTERED INDEX IX_1 on '+@numeTabelTemp+' (numarrand)'  
exec (@cTextSelect)   
  
----------------------------- determinare tip sablon, extensie si nume fisier -----------------------------  
select @eXML=eXML,@fisierSablon=RTRIM(transformare) from antform where Numar_formular=@nrform  
  
-- citire extensie implicita pt. fisier  -> dezactivat pt. ca se citeste extensia sablonului.   
--set @extensia=isnull(rtrim((select max(rtrim(val_alfanumerica)) from par where par.Tip_parametru='AR' and Parametru='EXTFORM')),'.doc')   
  
if @eXML=0 --formular cu TXT va fi tratat de o alta procedura  
begin  
 if @parXML.value('(/row/@hostid)[1]', 'varchar(100)') is not null                    
  set @parXML.modify('replace value of (/row/@hostid)[1] with sql:variable("@cHostid")')                       
 else             
  set @parXML.modify ('insert attribute hostid {sql:variable("@cHostid")} into (/row)[1]')                       
  
 exec wTipFormularAS2000 @sesiune=@sesiune, @parXML=@parXML  
end  
set @extensia=substring(@fisierSablon, len(@fisierSablon)-charindex('.',reverse(@fisierSablon))+1,len(@fisierSablon))  
if @eXML=0 and @extensia=''  
   set @extensia='.txt'  
  
if @numeFisier is not null /* @numeFisier citit din XML */  
begin -- daca se trimite nume fisier, si acesta contine si extensie, si o determin  
 if charindex('.',@numeFisier)>0  
 begin  
  SET @extensia= substring(@numeFisier, len(@numeFisier)-charindex('.',reverse(@numeFisier))+1,len(@numeFisier))  
  set @numeFisier=substring(@numeFisier, 0, len(@numeFisier)-len(@extensia)+1)  
 end  
end  
else  
begin -- nume fisier implicit  
 set @numeFisier=rtrim(@tip)+rtrim(@numar)  
end  
-- elimin caractere ilegale din numele fisierului  
set @numeFisier = replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(  
   @numefisier,'*',''),'?',''),'>',''),'<',''),'&',''),'%',''),'/',''),'\',''),'[',''),']',''),'|','')  
  
if CHARINDEX('.docx', @fisierSablon)=0  
begin   
 -- daca nu contine docx, ii asociez deja si extensia  
 select @numeFisier = @numefisier+@extensia,  
   @cFisierCuPath=rtrim(@directorFormulare)+@numeFisier,  
   @existaDocx=0  
end  
else  
begin  
 -- la docx nu pun extensia deoarece se creaza un folder cu numele fisierului(fara extensie), iar apoi se arhiveaza;  
 -- in final s-ar putea pune alta extensie dar nu stim cum va reactiona Word-ul daca se genereaza alta extensie.  
 select @numeFisier = replace(@numefisier,'.docx',''),  
   @cFisierCuPath=rtrim(@directorFormulare)+@numeFisier,  
   @existaDocx=1  
    
 set @xml = (select @nrform as nrform, @cFisierCuPath as cFisierCuPath, @fisierSablon as fisierSablon for xml raw)  
 exec DespachetareDocx @sesiune=@sesiune, @parXML=@xml  
  
end  
  
-- citesc toate fisierele care trebuie prelucrate  
declare listaFisiere cursor for  
select nume_fisier, continut from xmlformular where numar_formular=@nrform  
  
open listaFisiere  
fetch next from listaFisiere into @numeFisierCurent, @sablon  
while @@FETCH_STATUS=0  
begin   
 -- formez path pentru fisierul curent  
 select @cFisierCuPath= @directorFormulare+@numeFisier+isnull(@numeFisierCurent,''),  
   @cmdShellCommand = 'del "'+@cFisierCuPath+'"'  
   
 --sterg fisierul anterior daca exista  
 truncate table #raspCmdShell  
 insert #raspCmdShell  
 exec xp_cmdshell @statement=@cmdShellCommand  
   
 --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' procesare '+@cFisierCuPath  
   
 -- daca e formular text, raspunsul e format deja in alta tabela - il scriu si sar la scriere pe disk  
 if @eXML=0  
  goto ScriePeDisk  
   
 -- sterg continutul pentru fisiere anterioare  
 set @cTextSelect='TRUNCATE TABLE '+@numeTabelCuText  
 exec (@cTextSelect)   
   
 -----------------------------  procesare sablon -----------------------------   
 declare @cuvantCheie varchar(5)  
 select @raspunsTMP='',   
   @raspunsFinal='',  
   @lung=isnull(LEN(@sablon),-1),  
   @i=1,  
   @rand=1,  
   @start=1,  
   @nivelold=1,  
   @nivel=0  
  
 --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' inceput scanare sablon('+@cFisierCuPath+'). Lungime totala:'+convert(varchar,@lung)  
  
 ------------------------------ salvex txtul pana la prima variabila -------------------------------------  
 select @i=CHARINDEX('!$MG',@sablon),  
   @i=case when @i=0 then @lung else @i end,  
   @raspunsFinal=substring(@sablon,@start,@i-@start),  
   @start=@i  
   
 if substring(@sablon, @i, 5)='!$MG_'  
 begin  
  --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' insert pana la prima variabila. '  
  set @cTextSelect='insert into '+@numeTabelCuText+' (valoare) values (@raspunsFinal)'   
  exec sp_executesql @statement=@cTextSelect, @params=N'@raspunsFinal as varchar(max)', @raspunsFinal= @raspunsFinal  
  set @raspunsFinal=''  
 end  
  
 while @i<@lung and @i>0  
 begin   
  set @cuvantCheie=SUBSTRING(@sablon,@i,5)  
  --print @cuvantcheie+ convert(varchar,@i)  
  --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' index curent:'+convert(varchar,@i)+' cuvant gasit:'+@cuvantCheie+' rand:'+convert(varchar,@rand)  
  if @cuvantCheie='!$MGR' -- gasit mgrepeat  
  begin   
   if @i-@start>0  
   begin  
    set @raspunsTMP=@raspunsTMP+substring(@sablon,@start,@i-@start)  
   end  
   select @i=@i+11,  
     @start=@i+1,  
     @nivel=@nivel+1  
       
   -- daca a mai fost acest nivel, sunt 2 mgrepeat-uri imbricate la acelasi nivel. Iau @rand din tnivel, pentru a pune aceeasi informatie in ambele repeaturi  
   if exists(select 1 from tnivel where hostid=@cHostid and nivel=@nivel)  
   begin  
    select @rand=primulRand from tnivel where hostid=@cHostid and nivel=@nivel  
    delete from tnivel where hostid=@cHostid and nivel>=@nivel  
   end  
   insert into TNIVEL(hostid,nivel,start,stop, primulRand,expresie,v1,v2) values (@cHostid,@nivel,@i+1,0, @rand, '','','')  
  end   
  else  
  if @cuvantCheie='!$MG_' -- gasit variabila  
  begin   
   select @raspunsTMP=@raspunsTMP+substring(@sablon,@start,@i-@start),  
     @start=@i,  
     @j=@i+5,  
     @i=CHARINDEX('$!',@sablon,@i+1),  
     @start=@i+2,  
     @cColoana=substring(@sablon,@j,@i-@j)   
    
   if @i>0 and @i-@j<50 -- daca @i < 0, nu gaseste tagul $!, daca e >50 probabil word-ul a adaugat alte caractere  
   begin   
    -- verific existenta coloanei. daca nu este, las gol  
    if exists(select * from @coloaneDisponibile c where c.coloana=@cColoana)   
    begin   
     update tnivel set expresie=Expresie+(case when LEN(expresie)>0 then '+' else '' end)+@cColoana   
      where Hostid=@cHostid and nivel=@nivel and stop=0 and expresie=''  
     /* citesc valoarea si o trec prin 'for XML path' pentru a fi pregatita de scriere in fisier - merge bine deoarece fisierele word generate sunt xml-uri.   
      Daca se exporta in alt format, caracterele speciale ar putea cauza probleme */  
     set @cPtRez='set @raspunsTMP=@raspunsTMP+isnull((select ['+@cColoana+'] as [text()] from '+@numeTabelTemp+' where numarrand=@rand for xml path('''') ),'''')'  
     exec sp_executesql @statement=@cPtRez, @params=N'@rand int,@raspunsTMP nvarchar(max) out', @raspunsTMP=@raspunsTMP output, @rand=@rand  
    end  
    else -- nu am gasit coloana cautata  
     /* mitz: daca e in mod debug, la sfarsit afisez si coloanele neconfigurate pt. ca sa corecteze implementatorul */  
     insert into @coloaneLipsa(coloana) values (@cColoana)  
   end   
   else  
   begin  
    set @raspunsTMP='Eroare identificare tag !$MG_'+substring(@sablon,@j,15)  
    raiserror (@raspunsTMP,11,1)  
   end  
   set @i=@i+1   
  end  
  else  
  if @cuvantCheie='!$MGE' -- gasit endrepeat  
  begin   
   update TNIVEL set stop=@i where hostid=@cHostid and nivel=@nivel and stop=0  
   -- la sfarsitul unei linii, salvez datele in tabela temporara, sau direct in fisier  
   select @raspunsFinal=@raspunsFinal+@raspunsTMP+substring(@sablon,@start,@i-@start),  
     @raspunsTMP=''  
   -- insert in tabela temporara din care se face direct bcp  
   --if @extensia<>'.txt'  
   --begin  
   set @cTextSelect='insert into '+@numeTabelCuText+' (valoare) values (@raspunsFinal)'   
   exec sp_executesql @statement=@cTextSelect, @params=N'@raspunsFinal as varchar(max)', @raspunsFinal=@raspunsFinal  
   set @raspunsFinal=''    
   select @start=@i+1  
   --end  
   -- verific daca acest mgrepeat e in un alt bloc mgrepeat  
   if exists(select 1 from tNivel where nivel=@nivel-1 and hostid=@cHostid)  
   begin  
    -- verific daca s-au schimbat datele din mgrepeatul inferior  
    select @cTextSelect=  
     'update tnivel set v1=isnull((select '+expresie+' from '+@numeTabelTemp+' where numarrand=@rand),'''')'+  
       ', v2=isnull((select '+expresie+' from '+@numeTabelTemp+' where numarrand=@rand+1),'''')   
     where nivel=@nivel-1 and hostid=@cHostid'  
    from tnivel where Nivel=@nivel-1 and hostid=@cHostid and expresie<>''  
    exec sp_executesql @statement=@cTextSelect, @params=N'@rand int, @nivel int, @cHostid varchar(100)', @rand=@rand, @nivel=@nivel, @cHostid=@cHostid  
      
    set @nivelold=@nivel  
    if (@rand=@maxrand) or --(select v1 from tnivel where nivel=@nivel-1 and hostid=@cHostid)<>(select v2 from tnivel where nivel=@nivel-1 and hostid=@cHostid)  
      exists (select 1 from TNivel where nivel=@nivel-1 and hostid=@cHostid and v1<>v2)  
     set @nivel=@nivel-1  
   end  
   if (@nivel=@nivelold) and (@rand<@maxrand)  
   begin  
    select @i=(select start from tnivel where hostid=@cHostid and nivel=@nivel)-1,  
      @start=@i+1  
    -- sterg informatii legate de nivelul mai adanc, daca s-a schimbat info in acest nivel  
    delete from tnivel where hostid=@cHostid and nivel>@nivel   
   end  
   else   
   begin --s-a schimbat nivelul  
    select   
     @i=@i+14,   
     @start=@i+1,  
     @rand=@rand-1,  
     @nivelold=@nivel  
       
      
   end  
   set @rand=@rand+1  
  end   
  set @i=CHARINDEX('!$MG',@sablon,@i+1)  
 end   
 --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' adaug final de sablon(de la ultima aparitie de !$MG)'  
 select @raspunsFinal=@raspunsFinal+@raspunsTMP+substring(@sablon,@start,@lung+1-@start),  
   @raspunsTMP=''  
  
 -- insert in tabela temporara din care se face direct bcp  
 set @cTextSelect='insert into '+@numeTabelCuText+' (valoare) values (@raspunsFinal)'   
 exec sp_executesql @statement=@cTextSelect, @params=N'@raspunsFinal as varchar(max)', @raspunsFinal= @raspunsFinal  
 set @raspunsFinal=''    
  
 --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' terminat sablon.'  
  
 ScriePeDisk:  
 -------------------- salvare fisier pe disk sau trimitere in XML pentru Flex/AIR --------------------------  
 -- legacy - speram sa nu mai generam inXML ci sa se downloadeze de pe server. nu e tratat docx pentru inXML.  
 if @inXML=1 and @existaDocx=0 /* daca inXML=1 trimit fisierul pt. salvarea lui din Flex/AIR */  
 begin   
  /* daca se trimite raspunsul in XML, trebuie luata informatia scrisa in tabela ##form{hostId}.  
   Pentru concatenarea randurilor se foloseste for xml PATH, care este cea mai eficienta.  
   Dupa concatenare, se citeste folosind xQuery pt. transformarea corecta a caracterelor speciale.  
  */  
  declare @MyXMLData XML  
  set @cTextSelect='set @MyXMLData=''<row>''+( select valoare as [text()] from '+@numeTabelCuText+' order by id for xml path('''') )+''</row>'' '   
  exec sp_executesql @statement=@cTextSelect, @params=N'@MyXMLData XML out', @MyXMLData= @MyXMLData out  
  
  set @raspunsFinal=( select x.item.value('row[1]','nvarchar(max)') from @MyXMLData.nodes('/')AS x(item))  
    
  select @raspunsFinal as document, @numeFisier as fisier, @factura as nrFactura, 'wTipFormular' as numeProcedura for xml raw   
 end   
 else   
 begin   
  --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+'inainte de bcp '+@cFisierCuPath  
  declare @nServer varchar(1000)  
  select @nServer=convert(varchar(1000),serverproperty('ServerName')),  
    @cmdShellCommand='bcp "select valoare from '+@numeTabelCuText+' order by id" queryout "'+@cFisierCuPath+'" -T -c  -t -C UTF-8 -S'+@nServer  
     +(case when @extensia='.txt' or @eXML=0 then '' else ' -r ' end/*la txt, pastrez separatorul de linie*/)  
       
    --@cmdShellCommand='bcp "select valoare from '+@numeTabelCuText+' where len(rtrim(valoare))>3 order by id" queryout "'+@cFisierCuPath+'" -T  -c -r -t -C UTF-8 -S '+@nServer  
  exec @raspunsCmd = xp_cmdshell @cmdShellCommand  
  --xp_cmdshell returneaza un rezultat diferit de zero si la warning-uri  
  --vom trata in functie de codurile de eroare primite  
    
  if @raspunsCmd != 0 /* xp_cmdshell returneaza 0 daca nu au fost erori, sau altfel, codul de eroare   
        la OLE e 0 daca nu au fost erori */  
  begin  
   set @msgeroare = 'Eroare la scrierea formularului pe hard-disk in locatia: '+ (   
     case len(@cFisierCuPath) when 0 then 'NEDEFINIT' else @cFisierCuPath end )  
   raiserror (@msgeroare ,11 ,1)  
  end  
  --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' end scriere pe disk'+ @cFisierCuPath  
 end  
   
 fetch next from listaFisiere into @numeFisierCurent, @sablon  
 delete from tnivel where hostid=@cHostID  
end  
  
----------------------------------- arhivare docx(daca este cazul) -----------------------------------  
if @existaDocx=1  
begin  
 declare @cale7z varchar(1000)  
 -- arhivez fisierul generat  
 --print convert(varchar,datediff(millisecond, @dataStart, getdate()))+'Arhivez fisier docx generat...'  
 select @Cale7z=isnull((select rtrim(val_alfanumerica) from par where tip_parametru='AR' and Parametru='Cale7z'),'C:\"Program Files"\7-Zip\')  
 set @cmdShellCommand = @Cale7z+'7z.exe a -r "'+@directorFormulare+@numeFisier+'.docx" "'+@directorFormulare+@numeFisier+'\*"'  
 truncate table #raspCmdShell  
 insert #raspCmdShell  
 exec @raspunsCmd = xp_cmdshell @cmdShellCommand  
 if @debug=1  
  select * from #raspCmdShell  
 set @numeFisier=@numeFisier+'.docx' -- la modificare aici, verifca stergerea folderului la sfarsit  
end  
----------------------------------- end arhivare docx(daca este cazul) -----------------------------------  
  
if @inXML=0  
begin  
 /* trimit numele fisierului generat */   
 select @numeFisier as fisier, 'wTipFormular' as numeProcedura for xml raw, root('Date') -- legacy  
 select @numeFisier as fisier, 'wTipFormular' as numeProcedura for xml raw, root('Mesaje')   
end  
else   
if @inXML=1 and @existaDocx=1  
begin  
 -- creez tabela temporara pentru citire fisiere  
 create table #file_contents(  
  line_number int identity not null,   
  line_contents nvarchar(max) null  
  CONSTRAINT PK_line_number PRIMARY KEY CLUSTERED (line_number)  
 )  
   
 -- citesc document efectiv  
 select @cmdShellCommand = 'type "'+@directorFormulare+@numeFisier+'"',  
   @raspunsFinal=''  
        
 insert #file_contents(line_contents)  
 exec master.dbo.xp_cmdshell @cmdShellCommand  
  
 select @raspunsFinal = @raspunsFinal + isnull(line_contents, '')  
 from #file_contents  
   
 select @raspunsFinal as document, @numeFisier as fisier, @factura as nrFactura, 'wTipFormular' as numeProcedura for xml raw   
 select @numeFisier as fisier, 'wTipFormular' as numeProcedura for xml raw, root('Mesaje')   
end  
  
end try  
begin catch /* daca au fost erori, le trimit mai departe.   
   Folosim try catch pt. a opri firul de executie cand sunt erori */  
 SELECT @ErrorMessage = '(wTipFormular)'+ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
      
    if @eroareSelect = 1 /* daca sunt erori la exec. select format, trimit selectul: folosit in ASiSria si PVria */  
 begin   
  select @cTextSelect as textSelect, @factura as nrFactura, 'wTipFormular' as numeProcedura,   
   'Eroare la executarea comenzii SQL pentru generarea documentului:' as titluIntrebareClipboard,   
   @ErrorMessage+CHAR(13) + 'Doriti salvarea comenzii SQL in clipboard?' intrebareClipboard, @cTextSelect textClipboard  
   for xml raw, root('Mesaje')  
 end  
 --nu trimit erori de aici pentru a inchide fisiere temporare, etc.  
    --RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )  
  
end catch  
  
begin try ------------------------------------ salvez ultimul formular folosit ------------------------------------  
if not exists(select * from proprietati p where p.Tip='PROPUTILIZ' and p.Cod=@utilizator and p.Cod_proprietate='FORM'+@tipformular)  
 insert into proprietati(Cod, Cod_proprietate, Tip, Valoare, Valoare_tupla) values (@utilizator,'FORM'+@tipformular,'PROPUTILIZ',@nrform,'')  
else  
 update proprietati set valoare=@nrform where Tip='PROPUTILIZ' and Cod=@utilizator and Cod_proprietate='FORM'+@tipformular  
end try  
begin catch end catch  
  
-- cleanup tabele temporare, cursoare, etc  
begin try -- drop tabel in care se salveaza datele care se populeaza in sablon  
if exists(select * from tempdb.sys.objects where name = @numeTabelTemp)  
begin   
 set @cTextSelect='drop table '+@numeTabelTemp  
 exec (@cTextSelect)   
end  
end try begin catch end catch  
  
begin try -- drop tabel in care se salveaza formularul  
if exists(select * from tempdb.sys.objects where name = @numeTabelCuText)   
begin   
 set @cTextSelect='drop table '+@numeTabelCuText   
 exec (@cTextSelect)   
end  
end try begin catch end catch  
  
begin try -- inchid cursorul listaFisiere daca e deschis  
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='listaFisiere' and session_id=@@SPID )  
if @cursorStatus=1   
 close listaFisiere   
if @cursorStatus is not null   
 deallocate listaFisiere   
end try begin catch end catch  
  
-- sterg directorul folosit pentru generare docx  
if @existaDocx=1  
 begin try   
  set @cmdShellCommand = 'rmdir /S /Q "'+@directorFormulare+@numeFisier+'"'+CHAR(13)+  
   'rmdir /S /Q "'+@directorFormulare+left(@numeFisier,len(@numeFisier)-5)+'"'  
  truncate table #raspCmdShell  
  insert #raspCmdShell  
  exec @raspunsCmd = xp_cmdshell @cmdShellCommand  
 end try begin catch end catch  
  
begin try -- drop la tabela care salveaza raspunsul diverselor comenzi cmdShell  
 if OBJECT_ID('tempdb..#raspCmdShell') is not null  
  drop table #raspCmdShell  
end try begin catch end catch  
  
if @debug=1  
begin  
 select @selectDeExecutat  
 if exists (select * from @coloaneLipsa)  
  select distinct coloana as obiecte_formular_fara_coloana_in_select from @coloaneLipsa  
end  
--print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' end procedura wTipFormular'  
  
if @ErrorMessage is not null  
 raiserror(@errormessage,@ErrorSeverity,@ErrorState)  