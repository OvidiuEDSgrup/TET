--***
Create procedure wACDiagnostic @sesiune varchar(50), @parXML XML
as

declare @subtip varchar(2)
select @subtip=xA.row.value('@subtip', 'varchar(2)') from @parXML.nodes('row') as xA(row)  

declare @searchText varchar(100)
set @searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%')

select top 100 rtrim(Tip_diagnostic) as cod, rtrim(denumire) as denumire 
from dbo.fDiagnostic_CM()
where (@subtip in ('M1','M2') or Tip_diagnostic in ('2-','3-','4-','5-','6-')) 
and (Tip_diagnostic like @searchText+'%' or denumire like '%'+@searchText+'%')
order by Tip_diagnostic
for xml raw
