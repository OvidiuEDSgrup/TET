--***
create procedure rapFormDispozitiePlata @sesiune varchar(50), @parXML xml, @numeTabelTemp varchar(100)=null output
as
begin try     

	set transaction isolation level read uncommitted  
    
	declare
		@cont varchar(20), @data datetime, @numar varchar(20), @idPozPlin int, @nrform varchar(500),
		@subunitate varchar(9), @userASiS varchar(200), @mesaj varchar(max), @numeFirma varchar(200),
		@AdresaFirma varchar(500), @CUI varchar(100), @Judet varchar(100), @banca varchar(100),
		@contBanca varchar(100), @comandaSQL nvarchar(max), @plataincasare char(2)

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS output

	if len(@numeTabelTemp) > 0 --## nu se poate trimite in URL 
		set @numeTabelTemp = '##' + @numeTabelTemp
	
	if exists (select * from tempdb.sys.objects where name = @numeTabelTemp)
	begin 
		set @comandaSQL = 'select @parXML = convert(xml, parXML) from ' + @numeTabelTemp + '
		drop table ' + @numeTabelTemp
		exec sp_executesql @statement = @comandaSQL, @params = N'@parXML as xml output', @parXML = @parXML output
	end

	select
		@cont = @parXML.value('(/row/@cont)[1]', 'varchar(20)'),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@numar = isnull(@parXML.value('(/row/row/@numar)[1]', 'varchar(20)'), ''),
		@idPozPlin = isnull(@parXML.value('(/row/row/@idPozPlin)[1]', 'int'), 0)

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	select
		@numeFirma = (case when Parametru = 'NUME' then rtrim(val_alfanumerica) else @numeFirma end),
		@CUI = (case when Parametru = 'CODFISC' then rtrim(val_alfanumerica) else @CUI end),
		@AdresaFirma = (case when Parametru = 'ADRESA' then rtrim(val_alfanumerica) else @AdresaFirma end),
		@Judet = (case when Parametru = 'JUDET' then rtrim(val_alfanumerica) else @Judet end),
		@contBanca = (case when Parametru = 'CONTBC' then rtrim(val_alfanumerica) else @contBanca end),
		@banca = (case when Parametru =	'BANCA' then rtrim(val_alfanumerica) else @banca end)
	from par
	where Tip_parametru = 'GE' and Parametru in ('SUBPRO', 'NUME', 'CODFISC', 'ADRESA', 'JUDET', 'CONTBC', 'BANCA')

	if @idPozPlin = 0 or @numar = ''
		raiserror('Formularul trebuie apelat pentru o singura pozitie, nu din antet!', 16, 1)

	select
		@numeFirma as FIRMA,
		@AdresaFirma as ADRESA,
		@CUI as CUI,
		@Judet as JUDET,
		@contBanca as CONTBC,
		@banca as BANCA,
		p.numar as nrchit, 
		p.data as data,
		rtrim(pp.Nume) as dentert,
		rtrim(ff.Denumire) as functia,
		convert(decimal(15,2), p.Suma) as suma,
		rtrim(dbo.Nr2Text(p.suma)) as sumaStr,
		rtrim(p.Explicatii) as explicatii,
		substring(pp.Copii, 1, 2) as seriaCI,
		substring(pp.Copii, 4, 6) as numarCI,
		left(p.Plata_incasare, 1) as plata_incasare
	into #selectMare
	from pozplin p
	left outer join facturi f on f.Tip = 0x46 and f.Tert = p.Tert and f.Factura = p.Factura
	left outer join personal pp on p.Marca = pp.Marca
	left outer join functii ff on pp.cod_functie = ff.cod_functie
	where p.Subunitate = @subunitate
		and p.Cont = @cont
		and p.Data = @data
		and p.Numar = @numar
		and p.idPozPlin = @idPozPlin
	
	set @comandaSQL = 'select * from #selectMare'

	exec sp_executesql @statement = @comandaSQL

end try    
begin catch    
	set @mesaj = ERROR_MESSAGE() + ' (rapFormDispozitiePlata)'    
	raiserror(@mesaj, 16, 1)    
end catch
