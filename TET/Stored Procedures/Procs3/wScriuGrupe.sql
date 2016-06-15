
create procedure wScriuGrupe  @sesiune varchar(50),@parXML xml 
as  
begin try
	declare 
		@tip_nomencl varchar(1),@tip_nomenclold varchar(1), @grupa varchar(13),@grupaold varchar(13), @denumire varchar(30),
		@denumireold varchar(50),@update bit, @cont varchar(50), @detalii xml, @docDetalii xml,
		@grupa_parinte varchar(13)

	select
		@tip_nomencl = upper(ISNULL(@parXML.value('(/row/@tip)[1]','varchar(1)'),'')),
		@tip_nomenclold = ISNULL(@parXML.value('(/row/@o_tip)[1]','varchar(1)'),''),
		@update = ISNULL(@parXML.value('(/row/@update)[1]','bit'),''),
		@grupa = upper(ltrim(rtrim(ISNULL(@parXML.value('(/row/@grupa)[1]','varchar(13)'),'')))),
		@grupaold = ISNULL(@parXML.value('(/row/@o_grupa)[1]','varchar(13)'),''),
		@grupa_parinte = upper(nullif(@parXML.value('(/row/@grupa_parinte)[1]','varchar(13)'), '')),
		@denumire = ltrim(rtrim(ISNULL(@parXML.value('(/row/@denumire)[1]','varchar(30)'),''))),
		@denumireold = ISNULL(@parXML.value('(/row/@o_denumire)[1]','varchar(30)'),''),
		@cont = ltrim(rtrim(ISNULL(@parXML.value('(/row/@cont)[1]','varchar(50)'),''))),
		@detalii= @parXML.query('/row/detalii/row')
	
	if @cont<>'' and not exists (select 1 from conturi where cont=@cont)
		raiserror ('Contul nu este valid!',11,1)
	
	if exists (select * from grupe where Grupa=@grupa and @grupa!=@grupaold) 
		raiserror ('Grupa deja existenta!',11,1)

	if @update=1 
		update grupe 
			set Tip_de_nomenclator = @tip_nomencl, Denumire= @denumire, grupa_parinte=@grupa_parinte, detalii=@detalii
		where Grupa  = @grupaold
	else  
	begin  
		if isnull(@tip_nomencl,'')='' 
			raiserror ('Introduceti tipul de nomenclator!',11,1)

		if isnull(@grupa,'')='' 
		begin
			if not exists(select convert(float,RTRIM(grupa)) from grupe where ISNUMERIC(rtrim(grupa))=1) 
				set @grupa=1 
			else							
				select @grupa= (select max(convert(float,rtrim(grupa))) from grupe  where ISNUMERIC(rtrim(grupa))=1 and Grupa not like '%,%')+1							
		end	
			
		if isnull(@denumire,'')='' 
			raiserror ('Introduceti denumirea!',11,1)

		insert into grupe(Tip_de_nomenclator, Grupa, Denumire, Proprietate_1, Proprietate_2, Proprietate_3, Proprietate_4, Proprietate_5, Proprietate_6, Proprietate_7, Proprietate_8, Proprietate_9, Proprietate_10, grupa_parinte, detalii)
		values (@tip_nomencl, @grupa, @denumire, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @grupa_parinte, @detalii)			
	end
/*	
	if not exists (select * from propgr where tip=@tip_nomencl and Grupa=@grupa)
		insert into propgr (Tip,Grupa,Numar,Cod_proprietate)
		values(@tip_nomencl,@grupa,0,@cont)
	else
		update propgr set Cod_proprietate=@cont where tip=@tip_nomencl and Grupa=@grupa and Numar=0
*/
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
