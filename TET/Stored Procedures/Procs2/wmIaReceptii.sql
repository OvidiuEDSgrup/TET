	
create procedure wmIaReceptii @sesiune varchar(50), @parXML xml as
begin try
	declare
		@actiune_adaugare xml, @lista_receptii xml, @datajos datetime, @datasus datetime,@utilizator varchar(100), @search varchar(200), @nrGestProp int, @nrLmProp int, @incurs bit

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	select @incurs=0
	if exists(select 1 from StariDocumente where inCurs=1)
		select @incurs=1
	
	declare @gestProp table(gest varchar(50))
	insert into @gestProp(gest)
	select rtrim(p.Valoare)
	from proprietati p
	where p.Tip='UTILIZATOR' and p.Tip='GESTIUNE' and p.Cod=@utilizator and p.Valoare<>''
	set @nrGestProp = isnull((select count(*) from @gestProp),0)
	
	declare @lmProp table(lm varchar(50))
	insert into @lmProp(lm)
	select rtrim(p.Valoare)
	from proprietati p
	where p.Tip='UTILIZATOR' and p.Tip='LOCMUNCA' and p.Cod=@utilizator and p.Valoare<>''
	set @nrLmProp = isnull((select count(*) from @lmProp),0)
		
	select 
		@datasus=GETDATE(), 
		@datajos=DATEADD(DAY, -100, GETDATE()),
		@search='%'+ISNULL(@parXML.value('(/*/@searchText)[1]','varchar(200)'),'%')+'%'

	set @actiune_adaugare=
	(
		select 
			'adaugare' cod, 'Adauga receptie noua' denumire, '0x0000ff' as culoare,'C' as tipdetalii, 
			'wmDetaliiDocument' procdetalii,'assets/Imagini/Meniu/AdaugProdus32.png' as poza
		for xml raw, type
	)

	set @lista_receptii=
	(
		SELECT TOP 25
			'Receptia '+RTRIM(d.Numar)+ ' - '+ convert(varchar(10), d.data, 103) as denumire, (case when @nrGestProp<>1 then RTRIM(g.Denumire_gestiune)+ ' - ' else '' end) + convert(varchar(10),d.Numar_pozitii) + ' pozitii' info,
			RTRIM(d.Numar) numar, CONVERT(varchar(10), d.Data,101) data, '1' as toateAtr,
			'C' as tipdetalii, 'wmDetaliiDocument' as procdetalii, RTRIM(d.cod_gestiune) gestiune, rtrim(g.Denumire_gestiune) dengestiune
		from doc d 
		outer apply 
			(
				select top 1 isnull(inCurs,0) as inCurs
				from jurnaldocumente jd
				inner join StariDocumente sd on sd.tipDocument=jd.tip and sd.stare=jd.stare
				where jd.tip=d.tip and jd.numar=d.numar and jd.data=d.data
				order by jd.data_operatii desc, jd.idJurnal desc
			) stare
		LEFT JOIN gestiuni g ON g.Cod_gestiune=d.Cod_gestiune
		left join @gestProp gp on gp.gest=d.Cod_gestiune
		left join @lmProp l on l.lm=d.Loc_munca
		where d.Subunitate='1' and d.data between @datajos and @datasus and d.Tip='RM'
		and (@nrGestProp=0 or gp.gest is not null)
		and (@nrLmProp=0 or l.lm is not null)
		and (isnull(stare.inCurs,0)=@inCurs)
		and d.numar LIKE @search
		order BY data desc, numar desc
		for xml raw, TYPE
	)

	select 
		'RM' as tip, 'wmScriuAntetDocument' as proc_scriere_antet, 'D6' as form_antet, 'MR' as form_pozitie, 'wmIaReceptii' as detalii
	for xml RAW('atribute'),ROOT('Mesaje')
	
	select '1' as _areSearch
	for xml RAW, root('Mesaje')

	select @actiune_adaugare, @lista_receptii
	for xml PATH('Date')

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
