--***
/* operatie model... */
create procedure [dbo].[wOPModel]@sesiune varchar(50), @parXML xml
as     

declare @tert varchar(50), @localitate varchar(50)

select	@tert = isnull(@parXML.value('(/row/@tert)[1]', 'varchar(50)'),''),
		@localitate = @parXML.value('(/row/@localitate)[1]', 'varchar(50)')
		

if @tert=''
begin
	raiserror ('Tert necompletat!',11,1)
	return -1
end

/* 

segment cu cod specific fiecarei operatii 

*/


--if @cuSucces=1
/* daca e cu succes - in functie de ce face operatia... */
	select 'Operatia s-a efectuat cu succes, mai ales pentru ca nu face nimic :) !' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
-- else
	/* cand sunt erori */
	raiserror('S-a rezolvat... nu se poate :)',11,1)



