--***
Create procedure wIaPozRectificariSalarii @sesiune varchar(50), @parXML xml
as  
declare @userASiS varchar(10), @iDoc int, @tip varchar(2), @subtip varchar(2), 
@idRectificare int, @data datetime, @datajos datetime, @datasus datetime, @cautare varchar(500)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

select @cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(500)'), '')

select @idRectificare=xA.row.value('@idRectificare', 'int'), @data=xA.row.value('@data', 'datetime'), 
	@tip=xA.row.value('@tip', 'varchar(2)'), @subtip=xA.row.value('@subtip', 'varchar(2)')
from @parXML.nodes('row') as xA(row) 

set @datajos=dbo.bom(@data)
set @datasus=dbo.eom(@data)

select @tip as tip, @tip as subtip, 
	idPozRectificare, idRectificare, 
	convert(char(10),r.data_rectificata,101) as datarectificata, r.tip_suma as tipsuma, ts.denumire as dentipsuma, 
	convert(decimal(12,2),r.suma) as suma, convert(decimal(12,2),r.procent) as procent,
	'#000000' as culoare 
from PozRectificariSalarii r
	left outer join dbo.fTipSumeSalarii () ts on r.tip_suma=ts.tip_suma
where r.idRectificare=@idRectificare
	and (ts.denumire like '%'+@cautare+'%')
order by r.data_rectificata, ts.ordine, r.tip_suma
for xml raw
