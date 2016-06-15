--***
create procedure [dbo].[wScriuGrupaComenzi]  @sesiune varchar(50),@parXML xml 
as  
begin try
	declare @tipcom varchar(1),@tipcomold varchar(1), @grupa varchar(13),@grupaold varchar(13), @denumire varchar(30),
		@denumireold varchar(30),@update bit, @detalii xml, @docDetalii xml

	select
		@tipcom = upper(ISNULL(@parXML.value('(/row/@tipcom)[1]','varchar(1)'),'')),
		@tipcomold = ISNULL(@parXML.value('(/row/@o_tipcom)[1]','varchar(1)'),''),
		@update = ISNULL(@parXML.value('(/row/@update)[1]','bit'),''),
		@grupa = upper(ltrim(rtrim(ISNULL(@parXML.value('(/row/@grupa)[1]','varchar(13)'),'')))),
		@grupaold = ISNULL(@parXML.value('(/row/@o_grupa)[1]','varchar(13)'),''),
		@denumire = upper(ltrim(rtrim(ISNULL(@parXML.value('(/row/@denumire)[1]','varchar(30)'),'')))),
		@denumireold = ISNULL(@parXML.value('(/row/@o_denumire)[1]','varchar(30)'),''),
		@detalii= @parXML.query('/row/detalii')
/*	
	if @grupa='' 
		raiserror ('Completati grupa!',11,1)
*/	
	if exists (select * from grcom where Grupa=@grupa and @grupa!=@grupaold) --daca mai exista o grupa cu acelasi cod
	begin
		raiserror ('Grupa existenta!',11,1)
		return -1
	end
	if @update=1  --modificare
	begin
		update grcom set Tip_comanda = @tipcom, Denumire_grupa = @denumire where Grupa  = @grupaold
		if exists (select * from pozcom where Subunitate='GR' and Cod_produs = @grupaold and @grupa!=@grupaold) --daca exista o com. cu grupa initiala
		begin  
			raiserror ('Grupa nu poate fi modificata pentru ca a fost atribuita in comenzi!',11,1)
			return -1
		end	
		else -- daca NU exista o com. cu grupa initiala
			update grcom set Grupa=@grupa where Grupa=@grupaold
	end 	
	else  --adaugare 
	begin  
		if isnull(@tipcom,'')='' 
		begin  
			raiserror ('Introduceti tipul de comenzi!',11,1)
			return -1
		end	

		if isnull(@grupa,'')='' 
		begin
			if not exists(select convert(float,RTRIM(grupa)) from grcom where ISNUMERIC(rtrim(grupa))=1) 
				set @grupa=1 
			else
				select @grupa= (select max(convert(float,rtrim(grupa))) from grcom where ISNUMERIC(rtrim(grupa))=1 and Grupa not like '%,%')+1							
		end	
			
		if isnull(@denumire,'')=''  
		begin
			raiserror ('Introduceti denumirea!',11,1)
			return -1
		end	

		insert into grcom(Tip_comanda, Grupa, Denumire_grupa)
			values (@tipcom, @grupa, @denumire)
	end
	/*
	set @docDetalii = (select @grupa grupa, 'grcom' tabel, @detalii for xml raw)
	exec wScriuDetalii @parXML=@docDetalii
	*/
end try

begin catch
	declare @mesajEroare varchar(254)
	set @mesajEroare = ERROR_MESSAGE()
	raiserror(@mesajEroare, 11, 1)	
end catch
