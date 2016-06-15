--***
CREATE procedure wmSituatieFacturiTerti @sesiune varchar(50), @parXML xml 
as


	if @parXML.value('(/row/@wmDetTerti.cod)[1]', 'varchar(20)') is not null                          
		set @parXML.modify('replace value of (/row/@wmDetTerti.cod)[1] with "SB"')                             
	else                   
		set @parXML.modify ('insert attribute wmDetTerti.cod{"SB"} into (/row)[1]')

exec wmDateTerti @sesiune=@sesiune,@parXML=@parXML
