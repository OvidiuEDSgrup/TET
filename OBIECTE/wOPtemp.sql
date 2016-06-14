DROP procedure wOPtemp 
GO
CREATE procedure wOPtemp @sesiune varchar(50), @parxml xml  
as  
  
declare @tert varchar(13), @numar varchar(20), @utilizator varchar(20), @hostid varchar(20)
	,@data date, @cont varchar(13), @scriuavnefac int
  
select @tert = @parXML.value('(/parametri/row/@tert)[1]','varchar(13)')
	,@numar=@parXML.value('(/parametri/row/@numar)[1]','varchar(20)')
	,@data=@parXML.value('(/parametri/row/@data)[1]','date')
	,@cont=@parXML.value('(/parametri/row/@cont)[1]','varchar(13)')
  
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
set @hostid=LEFT(@utilizator,20)

--if @tert is not null  
-- if @parXML.value('(/parametri/@tert)[1]','varchar(50)') is null  
--  set @parXML.modify ('insert attribute tert {sql:variable("@tert")} into (/parametri)[1]')  
-- else   
--  set @parXML.modify('replace value of (/parametri/@tert)[1] with sql:variable("@tert")')  
  
declare @nrform varchar(50)  
set @nrform='chitpi'  
  
if @parXML.value('(/parametri/@nrform)[1]','varchar(50)') is null  
  set @parXML.modify ('insert attribute nrform {sql:variable("@nrform")} into (/parametri)[1]')  
 else   
  set @parXML.modify('replace value of (/parametri/@nrform)[1] with sql:variable("@nrform")')  

set @scriuavnefac=0
if @parXML.value('(/parametri/@scriuavnefac)[1]','int') is null  
  set @parXML.modify ('insert attribute scriuavnefac {sql:variable("@scriuavnefac")} into (/parametri)[1]')  
 else   
  set @parXML.modify('replace value of (/parametri/@scriuavnefac)[1] with sql:variable("@scriuavnefac")')  
  
set @parxml = replace(replace(CONVERT(varchar(max),@parXML), '<parametri ', '<row '), '</parametri>', '</row>')  

delete avnefac where Terminal=@hostid
insert avnefac
select
@hostid, --Terminal	char	25
'1', --Subunitate	char	9
'RE', --Tip	char	2
@numar, --Numar	char	20
'', --Cod_gestiune	char	9
@data, --Data	datetime	8
@tert, --Cod_tert	char	13
'', --Factura	char	20
@cont, --Contractul	char	20
GETDATE(), --Data_facturii	datetime	8
'', --Loc_munca	char	9
'', --Comanda	char	13
'', --Gestiune_primitoare	char	9
'', --Valuta	char	3
'', --Curs	float	8
'', --Valoare	float	8
'', --Valoare_valuta	float	8
'', --Tva_11	float	8
'', --Tva_22	float	8
'', --Cont_beneficiar	char	13
'' --Discount	real	4
  
exec wTipFormular @sesiune=@sesiune, @parXML=@parxml