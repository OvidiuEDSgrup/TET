
create procedure wIaFisiereTehnologie @sesiune varchar(50), @parXML XML  
as
begin try
	declare 
		@idPozTehnologie int

	select @idPozTehnologie = @parXML.value('(/*/@idTehn)[1]','int')
	
	IF OBJECT_ID('tempdb.dbo.#iduri') IS NOT NULL
		drop table #iduri


	create table #iduri(id int, tip varchar(1), cod varchar(20))
	insert into #iduri(id, tip, cod)
	select 
		pz.id, pz.tip, pz.cod
	from pozTehnologii p
	JOIN pozTehnologii pz on p.id=pz.parinteTop where p.id=@idPozTehnologie

	insert into #iduri(id)
	select @idPozTehnologie

	SELECT 
		RTRIM(fisier) AS fisier, RTRIM(observatii) AS observatii, fp.idFisier idFisier, 
		'<a href="' + 'formulare/uploads/' + rtrim(fisier) + '" target="_blank" /><u> Click </u></a>' AS descarca,
		RTRIM(ISNULL(c.denumire, n.denumire)) denpozitie, fp.idPozTehnologie pozitie, fp.idPozTehnologie idPozTehnologie,
		(case pt.tip when 'M' then 'Material' when  'O' then 'Operatie' when 'R' then 'Reper' end) tippozitie,
		convert(decimal(15,2), pt.ordine_o) ordinepozitie	
	FROM FisiereProductie fp	
	JOIN #iduri id on id.id=fp.idPozTehnologie 
	JOIN PozTehnologii pt on pt.id=id.id
	LEFT JOIN nomencl n on n.cod=id.cod and id.tip='M'
	LEFT JOIN catop c on c.cod=id.cod and id.tip='O'
	order by pt.tip, pt.ordine_o	
	FOR XML raw, root('Date')

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
