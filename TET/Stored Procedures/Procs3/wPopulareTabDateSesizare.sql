CREATE procedure wPopulareTabDateSesizare @sesiune varchar(50), @parXML xml  
as 

	if @parXML.value('(/row/@update)[1]', 'varchar(9)') is not null                          
		set @parXML.modify('replace value of (/row/@update)[1] with ("0")') 


	select @parXML for xml path('Date')
