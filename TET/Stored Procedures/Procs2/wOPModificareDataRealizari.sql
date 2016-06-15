
CREATE procedure wOPModificareDataRealizari @sesiune varchar(50), @parXML xml
as
	declare 
		@data datetime, @dataNou datetime, @explicatii varchar(900), @nrCM varchar(20), @nrPP varchar(20), @id int,@doc xml
		
	select 
		@data=@parXML.value('(/parametri/@data)[1]', 'datetime'),
		@dataNou=@parXML.value('(/parametri/@dataNou)[1]', 'datetime'),
		@explicatii=@parXML.value('(/parametri/@explicatii)[1]', 'varchar(900)'),
		@nrCM=@parXML.value('(/parametri/@nrCM)[1]', 'varchar(20)'),
		@nrPP=@parXML.value('(/parametri/@nrPP)[1]', 'varchar(20)'),
		@id=@parXML.value('(/parametri/@idRealizare)[1]', 'int')
		
		
		set @doc= (select 'Modificare data antet' as actiune, @data as data, @dataNou as dataNoua, @explicatii as explicatii for xml raw)
		
		update realizari set data=@dataNou, detalii=@doc where id=@id
		
		--Update pozdoc
		update pozdoc set data=@dataNou where Subunitate='1' and tip='CM'and data=@data and Numar=@nrCM
		delete from doc where tip='CM' and data=@data
		update pozdoc set data=@dataNou where Subunitate='1' and tip='PP'and data=@data and Numar=@nrPP
		delete from doc where tip='PP' and data=@data
