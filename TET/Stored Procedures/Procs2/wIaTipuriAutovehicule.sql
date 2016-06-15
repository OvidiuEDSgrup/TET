--***
create procedure wIaTipuriAutovehicule @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sys.sysobjects where name = 'wIaTipuriAutovehiculeSP' and type = 'P')
	exec wIaTipuriAutovehiculeSP @sesiune, @parXML 
else      
begin try
	set transaction isolation level read uncommitted

	declare
		@filtruNrInmatriculare varchar(100), @filtruDenProprietar varchar(100), 
		@filtruCodChirias varchar(100), @filtruTipAuto varchar(100), @filtruTipMotor varchar(100), 
		@filtruMarca varchar(100), @filtruModel varchar(100), @filtruVersiune varchar(100), 
		@filtruPutereMotor varchar(100), @filtruAnFabricatiej int, @filtruanfabricaties int,
		@filtruCuloare varchar(100), @filtruCarburant varchar(100)

	set @filtruTipMotor = '%' + isnull(@parXML.value('(/row/@tipmotor)[1]', 'varchar(100)'), '') + '%'
	set @filtruMarca = '%' + isnull(@parXML.value('(/row/@marca)[1]', 'varchar(100)'), '') + '%'
	set @filtruModel = '%' + isnull(@parXML.value('(/row/@model)[1]', 'varchar(100)'), '') + '%'
	set @filtruVersiune	= '%' + isnull(@parXML.value('(/row/@versiune)[1]', 'varchar(100)'), '') + '%'
	set @filtruPutereMotor = '%' + isnull(@parXML.value('(/row/@putere)[1]', 'varchar(100)'), '') + '%'

	select top 100 
		rtrim(a.Cod) as cod, rtrim(a.Marca) as marca, rtrim(a.Model) as model,
		rtrim(a.Versiune) as versiune, rtrim(a.Tip_motor) as tipmotor, rtrim(a.Putere) as putere,
		rtrim(a.capacitate) as capacitate, rtrim(a.Grupa) as grupa
	from tipauto a
	where a.Tip_motor like @filtruTipMotor
		and a.Marca like @filtruMarca
		and a.Model like @filtruModel
		and a.Versiune like @filtruVersiune
		and a.Putere like @filtruPutereMotor
	for xml raw

	/*where Nr_circulatie like @filtruNrInmatriculare and isnull(tp.Denumire,'') like @filtruDenProprietar
	and a.Cod_chirias like @filtruCodChirias and a.Tip_auto like @filtruTipAuto
	and a.Marca like @filtruMarca and a.Model like @filtruModel
	and a.Versiune like @filtruVersiune and a.Tip_motor like @filtruTipMotor
	and a.Putere_motor like @filtruPutereMotor and a.Carburant like @filtruCarburant
	and a.Culoare like @filtruCuloare and (@facfiltrupean=0 or (isnumeric(a.An_fabricatie)=1 
	and convert(float,a.An_fabricatie) between @filtruAnFabricatiej and @filtruAnFabricaties))*/

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
