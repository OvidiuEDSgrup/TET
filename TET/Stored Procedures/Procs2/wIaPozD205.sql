--***
Create procedure wIaPozD205 @sesiune varchar(50), @parXML xml
as  
Begin
	declare @userASiS varchar(10), @tip varchar(2), @an int, @cautare varchar(100)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	select @tip=xA.row.value('@tip', 'varchar(2)'), @an=xA.row.value('@an', 'int'),
		@cautare=isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(50)'), '') 
	from @parXML.nodes('row') as xA(row) 

	select An as an, rtrim(d.Loc_de_munca) as lm, @tip as tip, 'CD' as subtip, 
	rtrim(d.tip_venit) as tipvenit, d.tip_venit+'-'+rtrim(tv.denumire) as dentipvenit,
	rtrim(tip_impozit) as tipimpozit, d.tip_impozit+'-'+(case when tip_impozit='1' then 'Anticipat' when tip_impozit='2' then 'Final' else '' end) as dentipimpozit,
	rtrim(d.marca) as marca, rtrim(p.nume) as densalariat, rtrim(d.cnp) as cnp, isnull(rtrim(d.nume),'') as nume, isnull(rtrim(d.tip_functie),'') as tipfunctie, 
	convert(decimal(10),d.Venit_brut) as venitbrut, convert(decimal(10),d.Deduceri_personale) as dedpers, 
	convert(decimal(10),d.Deduceri_alte) as dedalte, convert(decimal(10),d.Baza_impozit) as bazaimpozit, convert(decimal(10),d.Impozit) as impozit, 
	'#000000' as culoare 
	from DateD205 d 
		left outer join personal p on p.marca=d.marca
		left outer join fTipVenitD205() tv on tv.Tip_venit=d.Tip_venit
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=isnull(p.loc_de_munca,d.Loc_de_munca)
	where d.An=@an
		and (@cautare='' or d.Marca like @cautare+'%' or d.Nume like '%'+@cautare+'%' or d.Tip_venit like @cautare+'%' or d.Tip_impozit like @cautare+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) 
	order by d.tip_venit, d.nume
	for xml raw
End
