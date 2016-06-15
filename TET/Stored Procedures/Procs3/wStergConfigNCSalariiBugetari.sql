--***
CREATE procedure wStergConfigNCSalariiBugetari (@sesiune varchar(250), @parXML xml)
as
declare @utilizator char(20), @mesaj varchar(1000), @lm varchar(6), @nrpozitie int
begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select  @lm=nullif(@parXML.value('(/row/@lm)[1]','varchar(9)'),''),
			@nrpozitie=isnull(@parXML.value('(/row/@nrpozitie)[1]','int'),0)

	if @lm is null
		raiserror('Nu se poate sterge o configurare definita la nivelul unitatii!', 11, 1)

	delete from config_nc 
		where nullif(Loc_de_munca,'') is not null and Loc_de_munca=@lm and Numar_pozitie=@nrpozitie
end try

begin catch
	set @mesaj=ERROR_MESSAGE()+ ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj,11,1) 
end catch


