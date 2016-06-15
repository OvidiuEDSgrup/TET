--***
Create procedure wScriuPozCentralizatorFurnizorCod @sesiune varchar(30), @parXML XML
as
declare @aprobat float, @contract varchar(20), @tert varchar(20), @cod varchar(20), @subtip varchar(2), @datacon datetime,@update int,
		@gestprim varchar(30), @gestiune varchar(30), @UTILIZATOR varchar(30), @cantitate float, @numarTE varchar(30)

 select @cod=upper(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(25)'),'')),
        @aprobat=isnull(@parXML.value('(/row/row/@aprobat)[1]', 'float'),''),
        @contract =upper(isnull(@parXML.value('(/row/row/@comanda)[1]', 'varchar(25)'),'')),
        @tert =upper(isnull(@parXML.value('(/row/row/@tert)[1]', 'varchar(25)'),'')),
        @subtip=isnull(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'),''),
        @datacon=isnull(@parXML.value('(/row/row/@datacon)[1]', 'datetime'),''),
        @update=isnull(@parXML.value('(/row/row/@update)[1]', 'int'),0),
        @gestprim=upper(isnull(@parXML.value('(/row/@gestiune)[1]', 'varchar(30)'),'')),
        @cantitate=isnull(@parXML.value('(/row/row/@cantitate)[1]', 'varchar(30)'),'')
        
select @subtip        
begin try
if @subtip='CI' and @update=1
    begin
	 update pozcon set cant_aprobata=@aprobat where cod=@cod and Contract=@contract and tert=@tert and data=@datacon
    end
else 
if @subtip='CN' and @update=0
begin 
	set @numarTE=rtrim(@gestprim)+'-'+convert(varchar(20),getdate(),101)
	declare @input xml
			set @input=(select top 1 'BK' as '@tip', @numarTE as '@numar',@gestprim as '@gestiune', @gestprim as '@gestprim',convert(varchar(20),getdate(),101) as '@data',
									(select rtrim(@cod) as '@cod' ,convert(varchar(20),@cantitate) as '@cantitate', @gestprim as '@gestiune',
									convert(varchar(20),@cantitate) as '@Tcantitate'
									for XML path,type)
									for XML path,type)
									exec wScriuPozCon @sesiune,@input	
end
declare @docXMLIaPozGP xml  
set @docXMLIaPozGP = '<row cod="' + rtrim(@cod) + '"/>'  
select @docXMLIaPozGP
exec wIaPozCentralizatorFurnizorCod @sesiune=@sesiune, @parXML=@docXMLIaPozGP    
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
select * from gestiuni
