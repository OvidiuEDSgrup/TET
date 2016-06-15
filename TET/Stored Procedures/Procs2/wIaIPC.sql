--***
CREATE procedure wIaIPC @sesiune varchar(50), @parXML xml
as 
set transaction isolation level READ UNCOMMITTED
declare @datal datetime, @datajos datetime, @datasus datetime, @tip varchar(2)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @tip=xA.row.value('@tip', 'char(2)'), @datal=xA.row.value('@datal','datetime'), 
	@datajos=isnull(xA.row.value('@datajos','datetime'),dbo.BOM(isnull(@datal,'01/01/1901'))), 
	@datasus=dbo.Eom(isnull(xA.row.value('@datasus','datetime'),dbo.eOM(isnull(@datal,'01/01/2999')))) 
	from @parXML.nodes('row') as xA(row)  

SELECT convert(char(10),a.Data,101) as datal, @tip as tip, 'Indici '+rtrim(rtrim(max(fc.LunaAlfa))+' '+
convert(char(4),max(fc.An))) as luna, count(1) as nrpozitii
FROM MF_ipc a --select * FROM MF_ipc
inner join fCalendar (@datajos, @datasus) fc on fc.Data=a.Data 
WHERE a.Data between @datajos and @datasus and (@datal is null or a.Data=@datal)
GROUP BY a.Data
union all
SELECT data_lunii, @tip as tip, 'Indici '+rtrim(rtrim((fc.LunaAlfa))+' '+convert(char(4),(fc.An))) 
as luna, 0 as nrpozitii
FROM fCalendar (@datasus, @datasus) fc 
WHERE @datal is null and not exists (select 1 from MF_ipc a where 
a.Data=dbo.eom(@datasus) and (@datal is null or a.Data=@datal)) 
ORDER BY datal
for xml raw
