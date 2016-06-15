	
create procedure wmIaAvize @sesiune varchar(50), @parXML xml as
begin try
	declare
		@actiune_adaugare xml, @lista_ap xml,@datajos datetime, @datasus datetime,@utilizator varchar(100), @search varchar(200), @nrGestProp int, @nrLmProp int

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

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
			'adaugare' cod, 'Adauga' denumire, '0x0000ff' as culoare,'C' as tipdetalii, 
			'wmDetaliiDocument' procdetalii,'assets/Imagini/Meniu/AdaugProdus32.png' as poza
		for xml raw, type
	)
	set @lista_ap=
	(
		select TOP 25
			'Numar '+RTRIM(Numar) as denumire, 'Data '+ convert(varchar(10), data, 103) + ' - ' + convert(varchar(10),Numar_pozitii) + ' pozitii' info,
			RTRIM(Numar) numar, CONVERT(varchar(10), Data,101) data, '1' as toateAtr,
			'C' as tipdetalii, 'wmDetaliiDocument' as procdetalii, rtrim(Cod_tert) tert
		from doc d 
		left join @gestProp gp on gp.gest=d.Cod_gestiune
		left join @lmProp l on l.lm=d.Loc_munca
		where 
			(@nrGestProp=0 or gp.gest is not null)and 
			(@nrLmProp=0 or l.lm is not null) and 
			data between @datajos and @datasus and Tip='AP'		and numar LIKE @search
		order BY data desc
		for xml raw, TYPE			
	)
	
	select 
		'AP' as tip, 'wmScriuAntetDocument' as proc_scriere_antet, 'D2' as form_antet, 'MA' as form_pozitie
	for xml RAW('atribute'),ROOT('Mesaje')

		
	select '1' as _areSearch
	for xml RAW, root('Mesaje')

	select @actiune_adaugare, @lista_ap
	for xml PATH('Date')

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
