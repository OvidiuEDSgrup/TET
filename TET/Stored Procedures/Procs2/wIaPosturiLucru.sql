--***
create procedure wIaPosturiLucru @sesiune varchar(50), @parXML XML
as
if exists (select 1 from sys.sysobjects where name = 'wIaPosturiLucruSP' and type = 'P')
	exec wIaPosturiLucruSP @sesiune, @parXML
else      
begin try
	set transaction isolation level READ UNCOMMITTED
	declare 
		@filtruLocMunca varchar(100), @filtruConsilier varchar(100),
		@filtruDenumire varchar(100), @filtruPostLucru varchar(100)

	select
		@filtruLocMunca = '%' + isnull(@parXML.value('(/row/@filtrulocmunca)[1]', 'varchar(100)'), '') + '%',
		@filtruConsilier = '%' + isnull(@parXML.value('(/row/@filtruconsilier)[1]', 'varchar(100)'), '') + '%',
		@filtruDenumire = '%' + isnull(@parXML.value('(/row/@filtrudenumire)[1]', 'varchar(100)'), '') + '%',
		@filtruPostLucru = '%' + isnull(@parXML.value('(/row/@filtrupostlucru)[1]', 'varchar(100)'), '') + '%'

	select top 100
		convert(varchar(100), pl.Postul_de_lucru) as postlucru,
		rtrim(pl.Loc_de_munca) as locmunca, rtrim(pl.Consilier_responsabil) as consilier,
		rtrim(pl.Denumire) as denumire, rtrim(lm.Denumire) as denlm
	from Posturi_de_lucru pl 
	left join lm on cod = pl.Loc_de_munca
	where (pl.Loc_de_munca like @filtruLocMunca or lm.Denumire like @filtruLocMunca) 
		and pl.Denumire like @filtruDenumire
		and pl.Consilier_responsabil like @filtruConsilier 
		and pl.Postul_de_lucru like @filtruPostLucru
	for xml raw

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
