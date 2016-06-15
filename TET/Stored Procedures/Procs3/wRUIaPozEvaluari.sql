--***
Create procedure wRUIaPozEvaluari @sesiune varchar(50), @parXML XML
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaPozEvaluariSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaPozEvaluariSP @sesiune=@sesiune, @parXML=@parXML output
	return @returnValue
end

declare @utilizator char(10), @tip varchar(2), @id_evaluare int, @doc xml, @mesaj varchar(200)
begin try
	select @tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)'),
		@id_evaluare=ISNULL(@parXML.value('(/row/@id_evaluare)[1]','int'),0)

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	set @doc= 
	(select pe1.ID_evaluare as id_evaluare, pe1.ID_poz_evaluare as id_poz_evaluare, rtrim(@tip) as tip, rtrim(pe1.tip_evaluat) as subtip, 'Planificare' as denevaluare, 
		(case when pe1.tip_evaluat='PO' then 'Obiectiv: ' else 'Competenta: '
			+isnull((case when d.tip_competenta=1 then 'TEHNICA' when d.tip_competenta=2 then 'MANAGERIALA' when d.tip_competenta=3 then 'GENERALA' end)+' ','')+'(ID='+rtrim(convert(char(10),pe1.ID_competenta))+') ' end)
			+rtrim((case when pe1.Tip_evaluat in ('PO') then o.Denumire else d.Denumire end)) as grupare, 
		pe1.ID_competenta as id_competenta, pe1.ID_obiectiv as id_obiectiv, pe1.ID_indicator as id_indicator, 
		pe1.ID_calificativ as id_calificativ, rtrim(c.Nivel_realizare+'('+rtrim(convert(char(4),c.Calificativ))+')') as dencalificativ,
		rtrim((case when pe1.Tip_evaluat in ('PO') then o.Denumire end)) as denobiectiv,
		rtrim((case when pe1.Tip_evaluat in ('PC') then d.Denumire end)) as dencompetenta,
		rtrim((case when pe1.Tip_evaluat in ('PO') then i.Denumire end)) as denindicator,
		convert(char(10),pe1.Data_inceput,101) as data_inceput, convert(char(10),pe1.Data_sfarsit,101) as data_sfarsit, 
		convert(decimal(12,2),pe1.Nota) as nota, convert(decimal(5,2),pe1.Procent) as procent, 
--		datele din grup
		(select pe.ID_evaluare as id_evaluare, rtrim(@tip) as tip, rtrim(pe.tip_evaluat) as subtip, 'Evaluare' as denevaluare, pe.ID_poz_evaluare as id_poz_evaluare, 
		pe.ID_competenta as id_competenta, rtrim((case when pe.Tip_evaluat in ('EC') then d.Denumire end)) as grupare, 
		rtrim((case when pe.Tip_evaluat in ('EC') then d.Denumire end)) as dencompetenta, 
		pe.ID_obiectiv as id_obiectiv, pe.ID_indicator as id_indicator, pe.ID_evaluator as id_evaluator, rtrim(p.Nume) as denevaluator, 
		convert(char(10),pe.Data_evaluare,101) as data_evaluare, 
		pe.ID_calificativ as id_calificativ, rtrim(c.Nivel_realizare)+'('+rtrim(convert(char(4),c.Calificativ))+')' as dencalificativ, 
		convert(decimal(12,2),pe.Nota) as nota, convert(decimal(5,2),pe.Procent) as procent
		from RU_poz_evaluari pe
			left outer join RU_persoane p on p.ID_pers=pe.ID_evaluator
			left outer join RU_calificative c on c.ID_calificativ=pe.ID_calificativ
			left outer join RU_competente d on d.ID_competenta=pe.ID_competenta
		where pe.ID_evaluare=@id_evaluare and right(pe.Tip_evaluat,1)=right(pe1.Tip_evaluat,1) 
			and (pe.Tip_evaluat='EO' and pe.ID_obiectiv=pe1.ID_obiectiv and pe.ID_indicator=pe1.ID_indicator 
			or pe.Tip_evaluat='EC' and d.ID_competenta_parinte=pe1.ID_competenta)
		order by pe.Data_evaluare, d.Tip_competenta
		for xml raw, type)

		from RU_poz_evaluari pe1
			left outer join RU_competente d on d.ID_competenta=pe1.ID_competenta
			left outer join RU_obiective o on o.ID_obiectiv=pe1.ID_obiectiv
			left outer join RU_calificative c on c.ID_calificativ=pe1.ID_calificativ
			left outer join RU_indicatori i on i.ID_indicator=pe1.ID_indicator
	where pe1.ID_evaluare=@id_evaluare and pe1.Tip_evaluat in ('PO','PC') 
	order by d.Tip_competenta
	for xml raw,root('Ierarhie')
	)
	
	if @doc is not null
		set @doc.modify('insert attribute _expandat {"nu"} into (/Ierarhie)[1]')

	if @doc is null
		set @doc='<Ierarhie />'

	select @doc for xml path('Date')
	
--	if @@ROWCOUNT=0
--		select '<Date><Ierarhie /></Date>'
end try

begin catch
	set @mesaj = '(wRUIaPozEvaluari) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
