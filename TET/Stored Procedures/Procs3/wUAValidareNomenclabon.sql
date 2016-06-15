/****** Object:  StoredProcedure [dbo].[wUAValidareNomenclabon]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wUAValidareNomenclabon] 
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin
	declare     @mesajeroare varchar(600),@cod varchar(20),@o_cod varchar(20),@denumire varchar(30), 
				@um varchar(3),@tarif float,
				@cotatva float,@tipserviciu varchar(2),@contvenituri varchar(13),
				@comanda varchar(13),@lm varchar(9),@update bit
	
	Select      @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
				@cod =isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),''),
				@denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(30)'),''),
				@um =isnull(@parXML.value('(/row/@um)[1]','varchar(80)'),''),
				@tarif = isnull(@parXML.value('(/row/@tarif)[1]','float'),0),
				@cotatva =isnull( @parXML.value('(/row/@cotatva)[1]','float'),''),
				@tipserviciu = isnull(@parXML.value('(/row/@tipserviciu)[1]', 'varchar(2)'),''),
				@contvenituri=isnull(@parXML.value('(/row/@contvenituri)[1]','varchar(13)'),''),
				@comanda= isnull(@parXML.value('(/row/@comanda)[1]','varchar(13)'),''),
				@lm= isnull(@parXML.value('(/row/@lm)[1]','varchar(9)'),''),
				@o_cod= isnull(@parXML.value('(/row/@o_cod)[1]','varchar(20)'),'')
	
	if @update=0
		begin
				if @cod in (select cod from nomenclabon)
			begin
		set @mesajeroare='Codul de serviciu exista deja!'
		raiserror(@mesajeroare,11,1)
		return -1
		end
			end
	
if @update=1 or @update=0
begin			
	if @o_cod in (select cod from pozitiifactabon) and @cod<>@o_cod
	begin
			set @mesajeroare='Codul de serviciu nu se poate modifica , exista pozitii facturi pe acest cod!'
			raiserror(@mesajeroare,11,1)
			return -1
	end
	
		if @o_cod in (select cod from pozcon)
	begin
			set @mesajeroare='Codul de serviciu nu se poate modifica , exista pozitii contracte pe acest cod!'
			raiserror(@mesajeroare,11,1)
			return -1
	end
	
	if @cod = ''
	begin
		set @mesajeroare='Introduceti codul de serviciu!'
		raiserror(@mesajeroare,11,1)
		return -1
	end
	
	if  @um not in (select um from um)
	begin
		set @mesajeroare='UM inexistent in catalogul de unitati de masura!'
		raiserror(@mesajeroare,11,1)
		return -1
	end
	
	if  (@tipserviciu not in (select cod_serviciu from tipuri_de_servicii)) and @tipserviciu<>''
	begin
		set @mesajeroare='Cod serviciu inexistent in catalogul de tipuri de servicii!'
		raiserror(@mesajeroare,11,1)
		return -1
	end
	
	if  (@contvenituri not in (select cont from conturi))and @contvenituri<>''
	begin
		set @mesajeroare='Cont inexistent in planul de conturi!'
		raiserror(@mesajeroare,11,1)
		return -1
	end
	
		if  @contvenituri in (select cont from conturi where are_analitice=1)
	begin
		set @mesajeroare='Contul are analitice!'
		raiserror(@mesajeroare,11,1)
		return -1
	end

	/*	if  @comanda not in (select comanda from comenzi)
	begin
		set @mesajeroare='Comanda inexistenta in catalogul de comenzi!'
		raiserror(@mesajeroare,11,1)
		return -1
	end*/
   
   		if  @lm not in (select cod from lm)
	begin
		set @mesajeroare='Loc de munca invalid catalogul de locuri de munca!'
		raiserror(@mesajeroare,11,1)
		return -1
	end
   
end

	return 0
end
