--***
create procedure [dbo].[wScriuGrupaTerti]  @sesiune varchar(50),@parXML xml 
as  
begin try
	declare @grupa varchar(13),@grupaold varchar(13), @denumire varchar(30),@denumireold varchar(30),
		@discount decimal(17,2), @update bit, @detalii xml, @docDetalii xml

	select
		@discount = ISNULL(@parXML.value('(/row/@discount)[1]','decimal(17,2)'),0),
		@update = ISNULL(@parXML.value('(/row/@update)[1]','bit'),''),
		@grupa = upper(ltrim(rtrim(ISNULL(@parXML.value('(/row/@grupa)[1]','varchar(13)'),'')))),
		@grupaold = ISNULL(@parXML.value('(/row/@o_grupa)[1]','varchar(13)'),''),
		@denumire = upper(ltrim(rtrim(ISNULL(@parXML.value('(/row/@denumire)[1]','varchar(30)'),'')))),
		@denumireold = ISNULL(@parXML.value('(/row/@o_denumire)[1]','varchar(30)'),''),
		@detalii= @parXML.query('/row/detalii')
	
	if @discount<0
	begin
		raiserror ('Discountul nu poate fi negativ!',11,1)
		return -1
	end
	
	if exists (select * from gterti where Grupa=@grupa and @grupa!=@grupaold) --daca mai exista o grupa cu acelasi cod
	begin
		raiserror ('Grupa existenta!',11,1)
		return -1
	end
	
	if @update=1  --modificare
	begin
		update gterti set Denumire = @denumire, Discount_acordat=@discount where Grupa  = @grupaold
		if exists (select * from terti where /*Subunitate='1' and */Grupa = @grupaold and @grupa!=@grupaold) --daca exista un tert cu grupa initiala
		begin  
			raiserror ('Grupa nu poate fi modificata pentru ca a fost atribuita la terti!',11,1)
			return -1
		end	
		else -- daca nu exista un tert cu grupa initiala
			update gterti set Grupa=@grupa where Grupa=@grupaold
	end 	
	else  --adaugare 
	begin  
		if isnull(@grupa,'')='' 
		begin
			if not exists(select convert(float,RTRIM(grupa)) from gterti where ISNUMERIC(rtrim(grupa))=1) 
				set @grupa=1 
			else
				select @grupa=(select max(convert(float,rtrim(grupa))) from gterti where ISNUMERIC(rtrim(grupa))=1 and Grupa not like '%,%')+1							
		end	
			
		if isnull(@denumire,'')=''  
		begin
			raiserror ('Introduceti denumirea!',11,1)
			return -1
		end	

		insert into gterti (Grupa, Denumire, Discount_acordat)
			values (@grupa, @denumire, @discount)
	end
	/*
	set @docDetalii = (select @grupa grupa, 'gterti' tabel, @detalii for xml raw)
	exec wScriuDetalii @parXML=@docDetalii
	*/
end try

begin catch
	declare @mesajEroare varchar(254)
	set @mesajEroare = ERROR_MESSAGE()
	raiserror(@mesajEroare, 11, 1)	
end catch
