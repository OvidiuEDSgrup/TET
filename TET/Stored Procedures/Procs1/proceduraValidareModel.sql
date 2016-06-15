--***
create procedure proceduraValidareModel @sesiune varchar(50), @parXML xml
as

/* validare structura XML */
if @parXML.exist('/row')=0 /* sau @document.exist('/row/row') daca e nevoie */
begin 
	raiserror ('Structura incorecta in XML!',11,1)
	return -1
end

/* validare un camp din xml */
if @parXML.exist('/row/row')=1 and isnull(@parXML.value('(/row/row/@cod)[1]', 'char(20)'), '') = ''
begin
	raiserror ('Cod necompletat!',11,1)
	return -1
end

/* se poate si citi in o variabila.. */
declare @tert varchar(50), @localitate varchar(50)
select	@tert = @parXML.value('(/row/@tert)[1]', 'varchar(50)'),
		@localitate = @parXML.value('(/row/@localitate)[1]', 'varchar(50)')
		
if @tert is null or @tert=''
begin 
	raiserror('Tert necompletat!',11,1)
	return -1
end


