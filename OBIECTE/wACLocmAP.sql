
--***
ALTER procedure [yso].[wACLocmAP] @sesiune varchar(50), @parXML XML as
--declare @sesiune varchar(50), @parXML XML
--set @parXML=convert(xml,N'<row tipMacheta="D" codMeniu="DO" tip="AP" subtip="" update="0" numar="TEST234" data="02/09/2012" gestiune="101" tert="02470320785" lm="" datafacturii="02/09/2012" datascadentei="02/09/2012" aviznefacturat="0" contfactura="" valtotala="0" categpret="" tiptva="0" tvatotala="0" searchText=" "/>')
--set @sesiune='8A046FEC7CEF1'

declare @searchText varchar(80), @userASiS varchar(10), @lista_lm bit, @tert varchar(13), @lmtert varchar(9)

select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
	,@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), '')

declare @subunitate varchar(9)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

set @searchText=UPPER(REPLACE(@searchText, ' ', '%'))

--select @userASiS=id from utilizatori where observatii=SUSER_NAME()
/*Modificare pentru login utilizator sa */
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT


set @lista_lm=0
select @lista_lm=1 from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='LOCMUNCA' and valoare<>''

set @lmtert=''
if @tert<>''
	select @lmtert=rtrim(i.loc_munca) from infotert i where i.Subunitate=@subunitate and i.Tert=@tert and i.Identificator=''

select top 100 rtrim(Cod) as cod, rtrim(Denumire) as denumire
from lm
where (cod like '%'+@searchText+'%' or denumire like '%'+@searchText+'%')
and (@lista_lm=0 or exists (select 1 from proprietati lu where RTrim(lm.cod) like RTrim(lu.valoare)+'%' and lu.tip='UTILIZATOR' and lu.cod=@userASiS and lu.cod_proprietate='LOCMUNCA'))
union 
select top 1 rtrim(Cod) as cod, rtrim(Denumire) as denumire
from lm
where rtrim(@lmtert)<>'' and rtrim(lm.Cod) like rtrim(@lmtert)+'%'
order by 1
for xml raw

GO

