--***
create procedure wStergActivitati @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @eroare xml ,
        @fisa varchar(20), @data datetime,  @tip varchar(10), @nrpozitii int        

begin try
exec sp_xml_preparedocument @iDoc output, @parXML

select	@tip = isnull(@parXML.value('(/row/@tip)[1]', 'char(2)'),0),
		@fisa = isnull(@parXML.value('(/row/@fisa)[1]', 'varchar(20)'),0),
		@data = isnull(@parXML.value('(/row/@data)[1]', 'datetime'),0)

if ISNULL((select count(1) from pozactivitati where tip=@tip and fisa=@fisa and data=@data), 0)<>0	
		raiserror('Activitatea are pozitii!',11,1)
	else 	
	delete activitati from activitati a, 
		OPENXML (@iDoc, '/row')
				where  Fisa=@fisa and Data=@data and tip=@tip
	exec sp_xml_removedocument @iDoc 
	--select 'ok' as msg for xml raw
	exec wIaPozActivitati @sesiune=@sesiune, @parXML=@parXML

end try
 
	begin catch
		--ROLLBACK TRAN		
		declare @mesaj varchar(255)
		if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
			set @mesaj=ERROR_MESSAGE()
		raiserror(@mesaj, 11, 1)
		--select @eroare FOR XML RAW
	end catch

