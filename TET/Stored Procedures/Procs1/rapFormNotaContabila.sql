--***
create procedure rapFormNotaContabila @sesiune varchar(50), @tip varchar(2), @numar varchar(20), @data datetime
as
begin try
	declare
		@utilizator varchar(20), @subunitate varchar(20)

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	select 
		rtrim(pn.numar) as NC,
		rtrim(convert(varchar(10), pn.data, 103)) as DATA,
		rtrim(pn.cont_debitor) as CONTDB,
		rtrim(pn.cont_creditor) as CONTCR,
		convert(decimal(15,2), pn.suma) as SUMA,
		rtrim(pn.explicatii) as EXPLICATII,
		rtrim(pn.loc_munca) as LM,
		rtrim(pn.comanda) as COMANDA,
		(case when rtrim(isnull(pn.valuta, '')) = '' then '' else rtrim(pn.valuta) end) as VALUTA,
		(case when rtrim(isnull(pn.valuta, '')) = '' then '' else rtrim(pn.curs) end) as CURS,
		(case when rtrim(isnull(pn.valuta, '')) = '' then 0 else convert(decimal(15,2), pn.suma_valuta) end) as SUMAVALUTA
	from pozncon pn
	where pn.subunitate = @subunitate
		and pn.tip = @tip
		and pn.numar = @numar
		and pn.Data = @data

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
