
create proc wStergGrupe @sesiune varchar(250), @parXML xml
as
begin try	
	declare 
		@tip_nomencl varchar(1), @grupa varchar(13), @denumire varchar(50), @cont varchar(50)

	select
		@tip_nomencl=ISNULL(@parXML.value('(/row/@tip_nomencl)[1]','varchar(1)'),''),
		@grupa=ISNULL(@parXML.value('(/row/@grupa)[1]','varchar(13)'),''),
		@denumire=ISNULL(@parXML.value('(/row/@denumire)[1]','varchar(50)'),''),
		@cont=ISNULL(@parXML.value('(/row/@cont)[1]','varchar(50)'),'')
		   
	if exists (select 1 from nomencl n where n.Grupa = @grupa) 
		raiserror ('Grupa selectata nu poate fi stearsa, a fost atribuita in nomenclator!',11,1)
	if exists (select 1 from grupe where grupa_parinte=@grupa) 
		raiserror ('Grupa selectata nu poate fi stearsa, este definita ca si grupa parinte !',11,1)
	else
		begin
			delete from grupe where Grupa=@grupa 
			delete from propgr where Grupa=@grupa
		end		
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
