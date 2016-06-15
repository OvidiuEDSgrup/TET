--***
create procedure wIaMesaje @sesiune varchar(50), @parXML xml
as
begin
	declare @versiune int,@maxvers int,@destinatie varchar(40)
	select @versiune= isnull(@parXML.value('(/row/@versiune)[1]', 'int'),0),
		@destinatie= isnull(@parXML.value('(/row/@destinatie)[1]', 'varchar(40)'),''),
	@maxvers=(select MAX(versiune) from asisria..mesaje)
		
	declare @raspuns xml
	set @raspuns=(
	/*Pentru versiune=0 se trimit userii ca si cum ar fi intrat*/
	select * from 
	(select 'in' as tip,s.utilizator as sursa,'' as destinatie,s.utilizator as mesaj
	from ASiSRIA..sesiuniRIA s
	where @versiune=0 and @destinatie=''
	union all
	/*Pentru versiune>0 se iau mesajele de la versiune pana la @maxvers
	pentru a fi siguri ca nu pierdem nicio linie*/
	select tip,sursa,destinatie,mesaj
	from asisria..mesaje
	where versiune between @versiune+1 and @maxvers
	/*destinatia e fie nimic fie trebuie sa fie egala cu userul curent pe care inca nu il am
	asa ca mai stau un pic*/
	and destinatie=@destinatie
	) tabChat
	for xml raw)
	
	/*In prima linie se pune versiunea curenta a mesajelor*/	
	set @raspuns.modify('insert attribute versiune{sql:variable("@maxvers")} into (/row)[1]')
	
	select @raspuns
end
