	
create procedure wmIaAlteIntrari @sesiune varchar(50), @parXML xml as
begin try
	declare
		@actiune_adaugare xml, @lista_ai xml, @gestiune_filtru varchar(20), @datajos datetime, @datasus datetime, @lm_filtru varchar(20),
		@utilizator varchar(100), @search varchar(200), @areGestProp smallint, @areLmProp smallint


	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	select 
		@datasus=GETDATE(), 
		@datajos=DATEADD(DAY, -100, GETDATE()),
		@search='%'+ISNULL(@parXML.value('(/*/@searchText)[1]','varchar(200)'),'%')+'%'

	declare @gestProp table(gest varchar(50))
	insert into @gestProp(gest)
	select rtrim(p.Valoare)
	from proprietati p
	where p.Tip='UTILIZATOR' and p.cod_proprietate='GESTIUNE' and p.Cod=@utilizator and p.Valoare<>''
	set @areGestProp = (case when exists (select * from @gestProp) then 1 else 0 end)
	
	declare @lmProp table(lm varchar(50))
	insert into @lmProp(lm)
	select rtrim(p.Valoare)
	from proprietati p
	where p.Tip='UTILIZATOR' and p.cod_proprietate='LOCMUNCA' and p.Cod=@utilizator and p.Valoare<>''
	set @areLmProp = (case when exists (select * from @lmProp) then 1 else 0 end)

	set @actiune_adaugare=
	(
		select 
			'adaugare' cod, 'Adauga' denumire, '0x0000ff' as culoare,'C' as tipdetalii, 
			'wmDetaliiDocument' procdetalii,'assets/Imagini/Meniu/AdaugProdus32.png' as poza
		for xml raw, type
	)
	set @lista_ai=
	(
		select TOP 25
			'Numar '+RTRIM(Numar) as denumire, 'Data '+ convert(varchar(10), data, 103) + ' - ' + convert(varchar(10),Numar_pozitii) + ' pozitii' info,
			RTRIM(Numar) numar, CONVERT(varchar(10), Data,101) data, '1' as toateAtr,
			'C' as tipdetalii, 'wmDetaliiDocument' as procdetalii, rtrim(Cod_tert) tert
		from doc  d
		left join @gestProp gp on gp.gest=d.Cod_gestiune
		left join @lmProp l on l.lm=d.Loc_munca
		where 
			d.Subunitate='1' and Tip='AI' and data between @datajos and @datasus 
			and (@areGestProp=0 or gp.gest is not null)
			and (@areLmProp=0 or l.lm is not null) 
			and d.numar LIKE @search
		order BY data desc
		for xml raw, TYPE			
	)
	
	select 
		'AI' as tip, 'wmScriuAntetDocument' as proc_scriere_antet, 'D4' as form_antet, 'MAI' as form_pozitie
	for xml RAW('atribute'),ROOT('Mesaje')

		
	select '1' as _areSearch
	for xml RAW, root('Mesaje')

	select @actiune_adaugare, @lista_ai
	for xml PATH('Date')

end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
