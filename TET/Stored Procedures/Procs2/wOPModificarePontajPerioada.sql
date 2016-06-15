create procedure wOPModificarePontajPerioada (@sesiune varchar(50), @parXML xml='<row/>')
as
begin try 

	set transaction isolation level read uncommitted
	declare @utilizatorASiS varchar(50), @mesaj varchar(1000), 
			@marca varchar(6), @datajos datetime, @datasus datetime, @tip_ore varchar(2), @ore int

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output

	select	
			@marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)'),
			@datajos = rtrim(@parXML.value('(/*/@datajos)[1]', 'datetime')),
			@datasus = rtrim(@parXML.value('(/*/@datasus)[1]', 'datetime')),
			@tip_ore = rtrim(@parXML.value('(/*/@tipore)[1]', 'varchar(50)')),
			@ore = rtrim(@parXML.value('(/*/@ore)[1]', 'int'))

	update pontaj_zilnic set ore=@ore--, tip_ore=@tip_ore	--Diferit: zice d-na Anca ca n-ar fi nevoie de modificarea tipului.
	where data between @datajos and @datasus and marca=@marca
		and	(datename(WeekDay, data) not in ('Saturday','Sunday') and data not in (select data from calendar) or ore<>0)
		and tip_ore not in ('S1','S2','S3','S3','NO')

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesaj, 11, 1)
end catch
