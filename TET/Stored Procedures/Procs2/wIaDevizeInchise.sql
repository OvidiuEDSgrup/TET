--***

create procedure wIaDevizeInchise @sesiune varchar(50), @parXML XML
as
begin
	--
	-- trimitem filtrutipdeviz = '', ca sa aducem toate devizele
	-- daca nu trimitem filtru, procedura wIaDevizeLucru va lua doar devizele care sunt "in lucru".
	--
	if @parXML.value('(/row/@filtrutipdeviz)[1]', 'varchar(100)') is null                  
		set @parXML.modify ('insert attribute filtrutipdeviz {""} into (/row)[1]')

	exec wIaDevizeLucru @sesiune, @parXML
end
