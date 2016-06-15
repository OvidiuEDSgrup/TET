--***
create procedure wIaTarifeSA @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sys.sysobjects where name = 'wIaTarifeSASP' and type = 'P')
	exec wIaTarifeSASP @sesiune, @parXML 
else      
begin try
	set transaction isolation level READ UNCOMMITTED
	declare
		@filtruCod varchar(100), @filtruDenumire varchar(100),
		@filtruTarifJ float, @filtruTarifS float, @filtruValuta varchar(100)

	select
		@filtruCod = '%' + isnull(@parXML.value('(/row/@filtrucod)[1]', 'varchar(100)'), '') + '%',
		@filtruDenumire = '%' + isnull(@parXML.value('(/row/@filtrudenumire)[1]', 'varchar(100)'), '') + '%',
		@filtruTarifJ = isnull(@parXML.value('(/row/@filtrutarifj)[1]', 'float'), -99999999),
		@filtruTarifS = isnull(@parXML.value('(/row/@filtrutarifs)[1]', 'float'), 999999999),
		@filtruValuta = '%' + isnull(@parXML.value('(/row/@filtruvaluta)[1]', 'varchar(100)'), '') + '%'

	select top 100
		rtrim(t.Cod) as cod, rtrim(t.Denumire) as denumire, 
		convert(decimal(17,5), t.Tarif) as tarif, rtrim(t.Valuta) as valuta, 
		rtrim(v.Denumire_valuta) as denvaluta
	from tarifemanopera t 
	left outer join valuta v on v.Valuta = t.Valuta
	where t.Cod like @filtruCod
		and t.Denumire like @filtruDenumire
		and t.Valuta like @filtruValuta
		and t.Tarif between @filtruTarifJ and @filtruTarifS
	for xml raw

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
