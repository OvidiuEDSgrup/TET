--***
create procedure wOPScriuUtilizatorED_p @sesiune varchar(50), @parXML XML  
as  

declare @eroare varchar(max)
begin try
	declare @utilizator varchar(100)
	select @utilizator=rtrim(@parXML.value('(/row/@utilizator)[1]','varchar(100)'))
	select 
		rtrim(u.id) utilizator, rtrim(u.nume) numeprenume, rtrim(u.observatii) utilizatorwindows, rtrim(u.info) parolaoffline, (case when marca='GRUP' then 1 else 0 end) egrupa
	from utilizatori u
	where rtrim(u.id)=rtrim(@utilizator)
	for xml raw
end try
begin catch
	select @eroare=error_message()+' (wOPScriuUtilizatorED_p)'
	raiserror(@eroare,16,1)
end catch
