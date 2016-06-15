--***
CREATE procedure wIaRepartizareCheltuieli @sesiune varchar(50), @parXML xml
as

declare @flm varchar(80), @fcomanda varchar(80), @fdiferentainf decimal(13, 3), @fdiferentasup decimal(13, 3),
		@utilizator varchar(20), @mesaj varchar(100)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	select	@flm = isnull(@parXML.value('(/row/@f_lm)[1]', 'varchar(80)'), ''),
			@fcomanda = isnull(@parXML.value('(/row/@f_comanda)[1]', 'varchar(80)'), ''),
			@fdiferentainf = isnull(@parXML.value('(/row/@f_diferentainf)[1]', 'float'), ''),
			@fdiferentasup = isnull(@parXML.value('(/row/@f_diferentasup)[1]', 'float'), '')
	
	SELECT RTRIM(lm) AS lm, RTRIM(comanda) AS comanda, i.incarcat AS incarcat, r.repartizat AS repartizat,
		round(i.incarcat - r.repartizat, 2) AS diferenta
	INTO #costuri
	FROM costuri c
	left join lm l on l.cod = c.lm
	cross apply (select isnull(sum(convert(decimal(20,3), cantitate * valoare)), 0) as incarcat
		from costtmp ct where ct.lm_sup = c.lm and ct.COMANDA_SUP = c.comanda and ct.art_sup NOT IN ('A','P','R','S','N')) as i
	cross apply (select isnull(sum(convert(decimal(20,3), cantitate * valoare)), 0) as repartizat
		from costtmp ct where ct.lm_inf = c.lm and ct.COMANDA_INF = c.comanda and ct.art_inf not in ('A', 'N') and ct.tip <> 'CX') as r
	where (@flm='' or lm+l.Denumire like '%'+@flm+'%')
		and (@fcomanda='' or comanda like '%'+@fcomanda+'%')

	SELECT * FROM #costuri
	WHERE diferenta between @fdiferentainf and @fdiferentasup
	for xml raw, root('Date')

end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
