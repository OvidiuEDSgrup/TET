CREATE procedure [dbo].[yso_wOPFormularPacheteBonPV] @sesiune varchar(50), @parxml xml
as

declare @datajos datetime ,@datasus datetime, @listaGestiuni varchar(max),  
	@Subunitate varchar(1),@Tip varchar(2),@Numar varchar(20),@Cod varchar(10),@Data datetime ,  
	@Gestiune varchar(10),@Cantitate float ,@Pret_valuta float ,@Pret_de_stoc float,@utilizator varchar(50),@stergere bit,  
	@generare bit,@databon datetime ,@casabon varchar(10),@numarbon int ,@UID varchar(50),@userASiS varchar(50), @msgEroare varchar(max),  
	@codMeniu varchar(2),@vanzator varchar(20),@casamarcat varchar(20),@DetBon int, @NrDoc varchar(20), @cHostid varchar(10),
	@tert varchar(20), @factura varchar(20), @contract varchar(20), @scriuavnefac int

exec luare_date_par 'PO','DETBON',@DetBon output,0,''  
  
select @tip=case ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), '') when 'BC' then 'AC' when 'BY' then 'AP' else '' end,
	@data=isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'01/01/1901'),  
	@numarbon=isnull(@parXML.value('(/parametri/@numar)[1]','int'),''),   
	@datajos=isnull(@parXML.value('(/parametri/@datajos)[1]','datetime'),isnull(@data,'01/01/1901')),  
	@datasus=isnull(@parXML.value('(/parametri/@datasus)[1]','datetime'),isnull(@data,'01/01/1901')),   
	@gestiune =isnull(@parXML.value('(/parametri/@gestiune)[1]','varchar(10)'),''),  
	@codMeniu=isnull(@parXML.value('(/parametri/@codMeniu)[1]','varchar(10)'),''),  
	@vanzator=isnull(@parXML.value('(/parametri/@vanzator)[1]','varchar(10)'),''),  
	@casamarcat=isnull(@parXML.value('(/parametri/@casam)[1]','varchar(10)'),''),  
	@stergere=isnull(@parXML.value('(/parametri/@stergere)[1]','bit'),0),  
	@generare=isnull(@parXML.value('(/parametri/@generare)[1]','bit'),0),
	@tert = isnull(@parXML.value('(/parametri/@tert)[1]','varchar(20)'),''),
	@factura = isnull(@parXML.value('(/parametri/@factura)[1]','varchar(20)'),''),
	@contract = isnull(@parXML.value('(/parametri/@contract)[1]','varchar(20)'),'')
  
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output 

select	@cHostid=LEFT(replace(@userASiS,'.',''),10)

select @numar=isnull(nullif(bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)'),'')
	,left((case when b.Factura_chitanta=1 then rtrim(convert(varchar(4),b.Casa_de_marcat))+right(replace(str(b.Numar_bon),' ','0'),4)
	else ltrim(a.Factura) end),8)) 
from bonuri b
	left join antetBonuri a on a.casa_de_marcat=b.casa_de_marcat and a.Numar_bon=b.Numar_bon and a.Data_bon=b.data and a.Vinzator=b.Vinzator
where b.Tip='21' and b.Casa_de_marcat=@casamarcat and b.Numar_bon=@numarbon and b.Data=@data and b.Vinzator=@vanzator


delete from avnefac where terminal=@cHostid
insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,Factura,Contractul, 
Data_facturii,Loc_munca,Comanda,Gestiune_primitoare,Valuta,Curs,Valoare,Valoare_valuta,Tva_11,Tva_22, 
Cont_beneficiar,Discount) 
values (@cHostid,'1',@tip,@numar,@gestiune,@data,@tert,@factura,@contract, 
convert(datetime,(convert(varchar,getdate(),101)),101),'','','','',0,0,0,0,0,'',0) 

set @scriuavnefac=0
if @parXML.value('(/parametri/@scriuavnefac)[1]','int') is null
	set @parXML.modify ('insert attribute scriuavnefac {sql:variable("@scriuavnefac")} into (/parametri)[1]')
else	
	set @parXML.modify('replace value of (/parametri/@scriuavnefac)[1] with sql:variable("@scriuavnefac")')

declare @nrform varchar(50)
set @nrform='AVIZEXPPK'

if @parXML.value('(/parametri/@nrform)[1]','varchar(50)') is null
		set @parXML.modify ('insert attribute nrform {sql:variable("@nrform")} into (/parametri)[1]')
	else	
		set @parXML.modify('replace value of (/parametri/@nrform)[1] with sql:variable("@nrform")')

set @parxml	= replace(replace(CONVERT(varchar(max),@parXML), '<parametri ', '<row '), '</parametri>', '</row>')

exec wTipFormular @sesiune=@sesiune, @parXML=@parxml
