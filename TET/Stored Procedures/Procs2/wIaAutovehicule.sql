--***
create procedure wIaAutovehicule @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sys.sysobjects where name = 'wIaAutovehiculeSP' and type = 'P')
	exec wIaAutovehiculeSP @sesiune, @parXML 
else  
begin try
	set transaction isolation level read uncommitted

	declare
		@filtruNrInmatriculare varchar(100),@filtruDenProprietar varchar(100), 
		@filtruCodChirias varchar(100), @filtruTipAuto varchar(100), @filtruTipMotor varchar(100), 
		@filtruMarca varchar(100), @filtruModel varchar(100), @filtruVersiune varchar(100), 
		@filtruPutereMotor varchar(100), @filtruAnFabricatiej int, @filtruanfabricaties int,
		@filtruCuloare varchar(100), @filtruCarburant varchar(2), @filtruSerieSasiu varchar(20)

	set @filtruNrInmatriculare = '%' + isnull(@parXML.value('(/row/@filtrunrinmatriculare)[1]', 'varchar(100)'), '') + '%'
	set @filtruDenProprietar = '%' + isnull(@parXML.value('(/row/@filtrudenproprietar)[1]', 'varchar(100)'), '') + '%'
	set @filtruTipMotor = '%' + isnull(@parXML.value('(/row/@filtrutipmotor)[1]', 'varchar(100)'), '') + '%'
	set @filtruMarca = '%' + isnull(@parXML.value('(/row/@filtrumarca)[1]', 'varchar(100)'), '') + '%'
	set @filtruModel= '%' + isnull(@parXML.value('(/row/@filtrumodel)[1]', 'varchar(100)'), '') + '%'
	set @filtruVersiune	= '%' + isnull(@parXML.value('(/row/@filtruversiune)[1]', 'varchar(100)'), '') + '%'
	set @filtruPutereMotor = '%' + isnull(@parXML.value('(/row/@filtruputere)[1]', 'varchar(100)'), '')
	set @filtruCuloare = isnull(@parXML.value('(/row/@filtruculoare)[1]', 'varchar(100)'), '')
	set @filtruCarburant = '%' + isnull(@parXML.value('(/row/@filtrucarburant)[1]', 'varchar(1)'), '')
	set @filtruSerieSasiu = '%' + isnull(@parXML.value('(/row/@filtruseriesasiu)[1]', 'varchar(20)'), '') + '%'

-- pentru filtrarea pe an declaram 2 valori intre care se face cautarea , un interval de la... pana la ..
-- anul de fabricatie fiind declarat de tip char trebuie convertit la numeric pt. evitarea erorilor

	declare
		@cfiltruanj varchar(100),@cfiltruans varchar(100),@facfiltrupean int

	set @facfiltrupean = 0
	set @cFiltruanj = isnull(@parXML.value('(/row/@filtruanfabricatiej)[1]', 'varchar(100)'), '')
	set @cFiltruans = isnull(@parXML.value('(/row/@filtruanfabricaties)[1]', 'varchar(100)'), '')

	if ISNUMERIC(@cfiltruanj)=1
	begin
		set @filtruAnFabricatiej=CONVERT(int,@cfiltruanj)
		set @facfiltrupean=1
	end
	else
		set @filtruAnFabricatiej=1900
	
	if ISNUMERIC(@cFiltruans)=1
	begin
		set @filtruAnFabricaties=CONVERT(int,@cfiltruans)
		set @facfiltrupean=1
	end
	else
		set @filtruAnFabricaties=2999

	select top 100
		rtrim(a.Serie_de_sasiu) as seriesasiu, rtrim(a.Cod) as codautovehicul,
		rtrim(a.Nr_circulatie) as nrinmatriculare, RTRIM(a.Cod_proprietar) as codproprietar,
		RTRIM(tp.Denumire) as denproprietar, RTRIM(a.Marca) as marca, RTRIM(a.Model) as model,
		RTRIM(a.Versiune) as versiune, RTRIM(a.Tip_motor) as tipmotor, RTRIM(a.Putere_motor) as puteremotor,
		RTRIM(a.An_fabricatie) as anfabricatie, RTRIM(a.Culoare) as culoare, rtrim(a.Carburant) as carburant, 
		RTRIM(a.Serie_de_motor) as seriemotor, RTRIM(a.cilindree) as cilindree, RTRIM(a.numar_card) as nrcard, 
		RTRIM(a.asigurare) as asigurare, RTRIM(a.asigurare_obligatorie) as asigurareobligatorie, 
		RTRIM(a.Nr_comanda) as com, RTRIM(a.dealer) as dealer, RTRIM(a.cod_antidemaraj) as codantidemaraj, 
		RTRIM(a.cod_radio) as codradio, RTRIM(a.cod_chei) as codchei, RTRIM(a.DAM) as DAM, 
		RTRIM(a.Observatii) as obs, RTRIM(a.furnizor) as furnizor, RTRIM(a.mod_de_plata) as modplata, 
		RTRIM(a.Denumire_firma_leasing) as firmaleasing, convert(varchar(10), a.Data_adeziunii, 101) as dataadeziunii, 
		convert(varchar(10), a.Data_card, 101) as datacard, convert(varchar(10), a.Data_cumpararii, 101) as datacumpararii, 
		convert(varchar(10), a.Data_ITP, 101) as dataITP, convert(varchar(10), a.DDG, 101) as DDG, 
		convert(decimal(17,0), a.Garantie) as garantie, convert(decimal(17,0),a.km_la_bord) as kmbord, 
		RTRIM(c.Denumire) as denculoare
	from auto a
	left outer join terti tp on tp.Subunitate = '1' and tp.Tert = a.cod_proprietar
	left outer join Culori c on c.Cod_culoare = a.Culoare
	where Nr_circulatie like @filtruNrInmatriculare
		and tp.Denumire like @filtruDenProprietar
		and a.Marca like @filtruMarca and a.Model like @filtruModel
		and a.Versiune like @filtruVersiune and a.Tip_motor like @filtruTipMotor
		and a.Putere_motor like @filtruPutereMotor and a.Carburant like @filtruCarburant
		and (@filtruCuloare = '' or c.Denumire like '%' + @filtruCuloare + '%')
		and a.Serie_de_sasiu like @filtruSerieSasiu
		and (@facfiltrupean=0 or (isnumeric(a.An_fabricatie) = 1 and a.An_fabricatie <> '\' --caz particular
			and a.An_fabricatie between @filtruAnFabricatiej and @filtruAnFabricaties))
	for xml raw

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
