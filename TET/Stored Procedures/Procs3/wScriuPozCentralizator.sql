--***
create procedure wScriuPozCentralizator  @sesiune varchar(30), @parXML XML
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozCentralizatorSP')
begin 
	declare @returnValue int 
	exec @returnValue = wScriuPozCentralizatorSP @sesiune, @parXML output
	return @returnValue
END

RAISERROR('Aceasta procedura nu este testata. Pentru situatii urgente, testati si dezvoltati o procedura specifica.', 11, 1)

declare @aprobat float, @contract varchar(20), @tert varchar(20), @cod varchar(20), @subtip varchar(2), @datacon datetime,@update int

 select @cod=isnull(@parXML.value('(/row/@cod)[1]', 'varchar(25)'),''),
        @aprobat=isnull(@parXML.value('(/row/row/@aprobat)[1]', 'float'),''),
        @contract =isnull(@parXML.value('(/row/row/@comanda)[1]', 'varchar(25)'),''),
        @tert =isnull(@parXML.value('(/row/row/@tert)[1]', 'varchar(25)'),''),
        @subtip=isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'),''),
        @datacon=isnull(@parXML.value('(/row/row/@datacon)[1]', 'datetime'),''),
        @update=isnull(@parXML.value('(/row/row/@update)[1]', 'int'),0)
begin try
 if @subtip='CI' and @update=1
    begin
	 update pozcon set cant_aprobata=@aprobat where cod=@cod and Contract=@contract and tert=@tert and data=@datacon
    end 
declare @docXMLIaPozGP xml  
set @docXMLIaPozGP = '<row cod="' + rtrim(@cod) + '"/>'  
select @docXMLIaPozGP
exec wIaPozCentralizator @sesiune=@sesiune, @parXML=@docXMLIaPozGP    
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
