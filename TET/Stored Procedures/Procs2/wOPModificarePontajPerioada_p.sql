create procedure wOPModificarePontajPerioada_p (@sesiune varchar(50), @parXML xml='<row/>')
as
begin try

	set transaction isolation level read uncommitted
	declare @utilizatorASiS varchar(50), @mesaj varchar(1000), @datalunii datetime, @dataJos datetime, @dataSus datetime, @marca varchar(6), @densalariat varchar(100)

	select	@datalunii = @parXML.value('(/row/@data)[1]', 'datetime'),
			@marca = @parXML.value('(/*/*/@marca)[1]', 'varchar(6)'),
			@densalariat = @parXML.value('(/*/*/@densalariat)[1]', 'varchar(100)')

	select @dataJos = dbo.BOM(@datalunii)
	select @dataSus = dbo.EOM(@datalunii)

	if isnull(@marca,'')=''
		raiserror('Operatie de modificare date pontaj nepermisa pe loc de munca, selectati un salariat de pe loc de munca!',16,1)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output

	select convert(varchar(10),@datajos,101) as datajos, convert(varchar(10),@datasus,101) as datasus, 
		rtrim(@marca) as marca, rtrim(@densalariat) as densalariat
	for xml raw

end try

begin catch
	set @mesaj = error_message() + ' (' + object_name(@@PROCID) + ')'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	raiserror(@mesaj, 11, 1)
end catch
