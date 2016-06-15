
CREATE procedure wIaContacte @sesiune varchar(50), @parXML xml  
as 
	declare
		@f_nume varchar(200), @f_adresa varchar(200)

	set @f_nume='%'+replace(ISNULL(@parXML.value('(/*/@f_nume)[1]','varchar(200)'),'%'),' ','%')+'%'
	set @f_adresa='%'+replace(ISNULL(@parXML.value('(/*/@f_adresa)[1]','varchar(200)'),'%'),' ','%')+'%'

	select 
		idContact, nume, email, telefon, adresa, note
	from Contacte
	where isnull(nume,'') like @f_nume and isnull(adresa,'') like @f_adresa 
	for xml RAW, ROOT('Date')
