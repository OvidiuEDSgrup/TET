--***
/**	functie pentru verificare drept pe utilizator */
CREATE function verificDreptUtilizator (@utilizator char(20), @drept char(20))
returns int
As
Begin
	declare @grupa_utilizator char(20)
	set @grupa_utilizator=isnull((select max(id_grup) from gruputiliz where id_utilizator=@utilizator),'')

	return (case when exists (select 1 from 
		(select tip, id, drept from dreptutiliz where tip='U' and id=@utilizator and drept=@drept
		union all
		select tip, id, drept from dreptutiliz where @grupa_utilizator<>'' and tip='G' and id=@grupa_utilizator and drept=@drept) a) then 1 else 0 end)
End
