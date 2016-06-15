--***
create procedure rapFormComandaLivrare @sesiune varchar(50), @numar varchar(20),
	@data datetime, @idContract int, @parXML varchar(max)
as
begin try
	if exists (select 1 from sys.sysobjects where name = 'rapFormComandaLivrareSP')
	begin
		exec rapFormComandaLivrareSP @sesiune = @sesiune, @idContract = @idContract
		return
	end
	declare
		@unitate varchar(50), @cui varchar(20), @adresa varchar(200),
		@sediu varchar(100), @judet varchar(100), @cont varchar(100), @banca varchar(100),
		@utilizator varchar(20)

	set transaction isolation level read uncommitted

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output
	
	set @unitate = (select rtrim(val_alfanumerica) from par where tip_parametru = 'GE' and parametru = 'NUME')
	set @cui = (select rtrim(val_alfanumerica) from par where tip_parametru = 'GE' and parametru = 'CODFISC')
	set @adresa = (select rtrim(val_alfanumerica) from par where tip_parametru = 'GE' and parametru = 'ADRESA')
	set @sediu = (select rtrim(val_alfanumerica) from par where tip_parametru = 'GE' and parametru = 'SEDIU')
	set @judet = (select rtrim(val_alfanumerica) from par where tip_parametru = 'GE' and parametru = 'JUDET')
	set @cont = (select rtrim(val_alfanumerica) from par where tip_parametru = 'GE' and parametru = 'CONTBC')
	set @banca = (select rtrim(val_alfanumerica) from par where tip_parametru = 'GE' and parametru = 'BANCA')

	select
		/* Header */
		rtrim(@unitate) as UNITATE,
		rtrim(@cui) as CUI,
		rtrim(@adresa) as ADRESA,
		rtrim(@sediu) as SEDIU,
		rtrim(@judet) as JUDET,
		rtrim(@cont) as CONT,
		rtrim(@banca) as BANCA,
		rtrim(c.numar) as NUMAR,
		rtrim(t.Denumire) as DENTERT,
		rtrim(g.Denumire_gestiune) as DENGESTIUNE,
		rtrim(convert(varchar(10), c.data, 103)) as DATA,
		rtrim(t.adresa) AS ADRESATERT,
		rtrim(t.localitate) AS LOCTERT,
		rtrim(t.judet) AS JUDTERT,

		/* Pozitii in tabel */
		row_number() over (order by pc.idPozContract) as nrcrt,
		rtrim(pc.cod) as cod,
		rtrim(n.Denumire) as denumire,
		pc.cantitate as cantitate,
		rtrim(n.um) as um,
		convert(decimal(15,2), pc.pret) as pret,
		convert(decimal(15,2), pc.discount) as discount, --> discount procentual
		convert(decimal(15,2), pc.pret * (1 - ISNULL(pc.discount, 0) / 100.0)) as pret_discountat,
		round(pc.pret * pc.cantitate, 2) as valoare,
		round(pc.pret * pc.cantitate * (1 - ISNULL(pc.discount, 0) / 100.0), 2) as valoare_discountata,

		/* Footer */
		rtrim(c.explicatii) as explicatii,
		'' AS date_tiparire -- sa nu apara mesajul 'Tiparit la data' decat in cadrul unui SP.
	from Contracte c
	inner join PozContracte pc on pc.idContract = c.idContract and c.idContract = @idContract
	left join terti t on t.Tert = c.tert
	left join gestiuni g on g.Cod_gestiune = c.gestiune
	left join nomencl n on n.Cod = pc.cod
		order by pc.idPozContract
end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
