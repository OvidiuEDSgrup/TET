--***
create procedure [dbo].yso_wScriuGrupe  @sesiune varchar(50),@parXML xml 
as  
begin try
	declare @tip_nomencl varchar(1),@tip_nomenclold varchar(1), @grupa varchar(13),@grupaold varchar(13), @denumire varchar(120),@denumireold varchar(120),@update bit, @cont varchar(50)

	select
		@tip_nomencl = upper(ISNULL(@parXML.value('(/row/@tip)[1]','varchar(1)'),'')),
		@tip_nomenclold = ISNULL(@parXML.value('(/row/@o_tip)[1]','varchar(1)'),''),
		@update = ISNULL(@parXML.value('(/row/@update)[1]','bit'),''),
		@grupa = upper(ltrim(rtrim(ISNULL(@parXML.value('(/row/@grupa)[1]','varchar(13)'),'')))),
		@grupaold = ISNULL(@parXML.value('(/row/@o_grupa)[1]','varchar(13)'),''),
		@denumire = upper(ltrim(rtrim(ISNULL(@parXML.value('(/row/@denumire)[1]','varchar(120)'),'')))),
		@denumireold = ISNULL(@parXML.value('(/row/@o_denumire)[1]','varchar(120)'),''),
		@cont = ltrim(rtrim(ISNULL(@parXML.value('(/row/@cont)[1]','varchar(50)'),'')))
	
	if @cont<>'' and not exists (select 1 from conturi where cont=@cont)
		raiserror ('Contul nu este valid!',11,1)
	
	if exists (select * from grupe where Grupa=@grupa and @grupa!=@grupaold) --daca mai exista o grupa cu acelasi cod
	begin
		raiserror ('Grupa deja existenta!',11,1)
		return -1
	end
	if @update=1  --modificare
	begin  
		update grupe set Tip_de_nomenclator = @tip_nomencl, Denumire= @denumire
		where Grupa  = @grupaold
		if exists (select * from nomencl n where  n.Grupa = @grupaold and @grupa!=@grupaold ) --? daca exista o nomenclatura cu grupa initiala
		begin  
			raiserror ('Grupa nu poate fi modificata pentru ca a fost atribuita in nomenclator!',11,1)
			return -1
		end	
		else -- daca NU exista o nomenclatura cu grupa initiala

-- mitz: aici trebuie block begin/end pentru aceste update-uri?
			update grupe set Grupa=@grupa where Grupa=@grupaold
			
			update propgr set Cod_proprietate=@cont,Tip=@tip_nomencl, Grupa=@grupa
			where Tip=@tip_nomenclold and Grupa=@grupaold and Numar=0	

	end 	
	else  --adaugare 
	begin  
		if isnull(@tip_nomencl,'')='' 
		begin  
			raiserror ('Introduceti tipul de nomenclator!',11,1)
			return -1
		end	
		if isnull(@grupa,'')='' 
		begin
			if not exists(select convert(float,RTRIM(grupa)) from grupe where ISNUMERIC(rtrim(grupa))=1) 
				set @grupa=1 
			else							
				select @grupa= (select max(convert(float,rtrim(grupa))) from grupe  where ISNUMERIC(rtrim(grupa))=1 and Grupa not like '%,%')+1							
		end	
			
	if isnull(@denumire,'')=''  
	begin  
		raiserror ('Introduceti denumirea!',11,1)
		return -1
	end	
		insert into grupe(Tip_de_nomenclator, Grupa, Denumire, Proprietate_1, Proprietate_2, Proprietate_3, Proprietate_4, Proprietate_5, Proprietate_6, Proprietate_7, Proprietate_8, Proprietate_9, Proprietate_10)
		values (@tip_nomencl, @grupa, @denumire, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	
		
	end
	-- adaugare/modificare cont specific
	if not exists (select * from propgr where tip=@tip_nomencl and Grupa=@grupa and Numar=0)
	begin
		insert into propgr (Tip,Grupa,Numar,Cod_proprietate)
		values(@tip_nomencl,@grupa,0,@cont)
	end
	else
	begin
		update propgr set Cod_proprietate=@cont where tip=@tip_nomencl and Grupa=@grupa and Numar=0
	end
end try

begin catch
	declare @mesajEroare varchar(254)
	set @mesajEroare = ERROR_MESSAGE()
	raiserror(@mesajEroare, 11, 1)	
end catch
