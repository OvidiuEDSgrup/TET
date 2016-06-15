--***

CREATE procedure [dbo].[wIaDateFormular] @sesiune varchar(50), @parXML xml                 
as
declare  @nrform varchar(13),@tip varchar(2),@numar varchar(20),@data datetime,@inXML int, @gestiune varchar(20), 
@tert varchar(20), @factura varchar(20), @contract varchar(20), @debug bit, @selectDeExecutat nvarchar(max),
@tipformular varchar(2), /*folosit la salvarea sablonului in propr. pt ca @tip se schimba in unele cazuri*/
@ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT,@scriuavnefac int,@conf xml, @date xml


Set @nrform =  @parXML.value('(/row/@nrform)[1]','varchar(13)')  
Set @tip = @parXML.value('(/row/@tip)[1]','varchar(2)') 
Set @tipformular = @parXML.value('(/row/@tip)[1]','varchar(2)') 
set @numar = isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'),'') 
set @tert = isnull(@parXML.value('(/row/@tert)[1]','varchar(20)'),'') 
set @scriuavnefac=ISNULL(@parXML.value('(/row/@scriuavnefac)[1]','int'),1) 
set @factura=@numar

if @tip in ('BF','BK') 
	set @contract = @numar
set @contract=isnull(@contract,'')

Set @data = @parXML.value('(/row/@data)[1]','datetime') 
Set @gestiune = isnull(@parXML.value('(/row/@gestiune)[1]','varchar(20)') ,'')
Set @inXML = isnull(@parXML.value('(/row/@inXML)[1]','int'),0) -- vine 1 din ASiSria.POS si returneaza XML-ul pt. scriere pe calc. client
Set @debug = isnull(@parXML.value('(/row/@debug)[1]','bit'),0) -- daca e 1, fac un select si cu formularul

set nocount on 
declare @sablon nvarchar(max),@rezultat varchar(max),@cPtRez varchar(max), @i int,@j int,@lung int , @numeFisier varchar(max)
declare @expresie varchar(1000),@obiect varchar(1000),@cColoana varchar(255), @cTextSelect nvarchar(max) 
declare @r1 int,@er1 int,@inr1 int,@rand int,@maxrand int,@val varchar(max)
declare @raspuns nvarchar(max),@start int,@stop int 
declare @cHostid varchar(10),@cDirector varchar(1000),@cFisier varchar(100),@utilizator varchar(255)
declare @eroareSelect int,@msgeroare varchar(1000),@nivel int,@nivelold int, @inceputApelProc int, @raspunsCmd int

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
if @utilizator is null set @utilizator='ASiSria'

/* lungimea maxima a coloanei terminal */
set @i = (SELECT min(clmns.max_length) FROM sys.tables AS tbl INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id where tbl.name='avnefac' and clmns.name= 'terminal' )
/* hostid = utilizator, fara '.' in el */
set @cHostid=LEFT(replace(@utilizator,'.',''),@i) --rtrim(ltrim(str(host_id()))) 

set @cDirector=(select top 1 val_alfanumerica from par where Tip_parametru='AR' and Parametru='CALEFORM')
if @cDirector is null and @inXML = 0
	raiserror ('Nu este configurat directorul unde se salveaza formularele! Configurati parametrul "AR", "CALEFORM", -> val_alfa ',11,1)
set @numeFisier = rtrim(@tip)+rtrim(@numar)+'.doc' 
set @cFisier=rtrim(@cDirector)+@numeFisier
set @i=0
set @inr1=0 
set @eroareSelect=0
/* set @nrform='f12' set @tip='RM' set @numar='1234123' set @data='2010-03-16' set @inXML=0 */
delete from tformular where terminal=@cHostID
delete from tnivel where hostid=@cHostID
IF OBJECT_ID('tempdb..##rasp'+@cHostID) IS NOT NULL
--if exists(select * from tempdb.sys.objects where name = '##rasp'+@cHostID) 
begin 
	set @cTextSelect='drop table ##rasp'+@cHostID 
	exec (@cTextSelect) 
end
set @cTextSelect=''

if @tip = 'BY' --> chemat din consulatare bonuri - bon factura
	set @tip='AP'
if @tip = 'BC' --> chemat din consulatare bonuri - bon chitanta
begin
	set @tip='AP'
	set @numar = @parXML.value('(/row/@factura)[1]','varchar(20)') 
end
if @tip = 'AI' 
	set @factura = @parXML.value('(/row/@factura)[1]','varchar(20)') 
if @tip = 'RE' --> registru de casa/banca
	set @numar = @parXML.value('(/row/@cont)[1]','varchar(20)') 
if @tip = 'SL' --> chemat din consulatare date lunare salarii
	set @numar=@parXML.value('(/row/@marca)[1]','varchar(6)')
	
if @tip = 'AB'or @tip = 'AL'--> documente bugetari
    begin
    set @numar=@parXML.value('(/row/@numar)[1]','varchar(20)')	
	set @factura = @parXML.value('(/row/@indbug)[1]','varchar(20)') 
	end	

if not exists (select * from anexafac where subunitate='1' and Numar_factura=@numar) 
begin 
	insert into anexafac (Subunitate,Numar_factura,Numele_delegatului,Seria_buletin,Numar_buletin, 
	Eliberat,Mijloc_de_transport,Numarul_mijlocului,Data_expedierii,Ora_expedierii,Observatii) 
	values ('1',@numar,'','','','','','',getdate(),'','') 
end 
 
if @scriuavnefac=1
begin
	delete from avnefac where terminal=@cHostid 
	insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,Factura,Contractul, 
	Data_facturii,Loc_munca,Comanda,Gestiune_primitoare,Valuta,Curs,Valoare,Valoare_valuta,Tva_11,Tva_22, 
	Cont_beneficiar,Discount) 
	values (@cHostid,'1',@tip,@numar,@gestiune,@data,@tert,@factura,@contract, 
	getdate(),'','','','',0,0,0,0,0,'',0) 
end


declare tmp cursor for 
select expresie,rtrim(obiect) from formular where formular=@nrform and obiect<>'' 
set @cTextSelect='Select ( Select ' 
open tmp 
fetch next from tmp into @expresie,@obiect 

while @@fetch_status=0 
begin 
	set @cTextSelect=@cTextSelect+rtrim(@expresie)+' as '+rtrim(@obiect)+',' 
	fetch next from tmp into @expresie,@obiect 
end 
close tmp 
deallocate tmp 
set @cTextSelect=substring(@cTextSelect,1,len(@cTextSelect)-1)+' ' 
set @cTextSelect=@cTextSelect+' '+(select rtrim(CLFrom) from antform where numar_formular=@nrform)+' WHERE '+ 
(select rtrim(CLWhere) from antform where numar_formular=@nrform)+' and avnefac.terminal='+quotename(@cHostid,'''')+' '+ 
(select rtrim(CLOrder) from antform where numar_formular=@nrform) 

begin try
	set @selectDeExecutat=@cTextSelect
	set @maxrand=@@rowcount 
	if @cTextSelect is null 
		raiserror('Formularul ales nu este configurat!',11,1)
end try
begin catch
	set @eroareSelect=1
	set @selectDeExecutat = @cTextSelect
	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )
end catch


/* apelproc */ 
set @cTextSelect=null
declare @numeProcedura varchar(255)
select @i=CHARINDEX('apelproc', expresie)+9, @j = CHARINDEX(')',expresie,@i), @numeProcedura=SUBSTRING(expresie,@i, @j - @i),
@cTextSelect= coalesce(@cTextSelect,'')+ 
	'if exists(select * from sysobjects where name='+quotename(@numeProcedura,'''')+' and type=''P'') '+char(10)+
	'exec '+@numeProcedura+' '+QUOTENAME(@cHostid,'''')+ CHAR(10)
from formular
where formular = @nrform
and CHARINDEX('apelproc', expresie)>0

exec (@cTextSelect)
/* sfarsit apelproc*/

set @selectDeExecutat = @selectDeExecutat + ' for xml raw, root(''DateFormular''),type)for xml path(''''), root (''Date'')'
if (@debug=1)
	select @selectDeExecutat
exec (@selectDeExecutat) 
