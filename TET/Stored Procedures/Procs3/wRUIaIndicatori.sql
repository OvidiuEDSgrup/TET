--***
Create procedure wRUIaIndicatori @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaIndicatoriSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaIndicatoriSP @sesiune, @parXML output
	return @returnValue
end

declare @filtruDomeniu varchar(30), @filtruStare varchar(30), @utilizator char(10), @lista_lm int, @mesaj varchar(200)
begin try
	select
		@filtruDomeniu = isnull(@parXML.value('(/row/@f_domeniu)[1]', 'varchar(50)'), ''),
		@filtruStare = isnull(@parXML.value('(/row/@f_stare)[1]', 'varchar(30)'), '')
	select @filtruDomeniu = replace(@filtruDomeniu,' ','%'), 
		@filtruStare = replace(@filtruStare,' ','%')

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select @lista_lm=0
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA')

	select top 100 a.ID_indicator as id_indicator, a.ID_domeniu as id_domeniu, rtrim(b.denumire) as dendomeniu, 
		rtrim(a.Denumire) as denumire, rtrim(a.Descriere) as descriere, 
		rtrim(a.Formula) as formula, rtrim(a.UM) as um, 'N' as tip, 
		a.Interval_jos as interval_jos, a.Interval_sus as interval_sus, 
		rtrim(a.Valori) as valori, rtrim(a.Descriere_valori) as descr_valori, convert(decimal(12,2),a.Procent) as procent,
		rtrim(a.Stare) as stare, (case when a.Stare='A' then 'Activ' else 'Inactiv' end) as denstare,
		rtrim(a.Sursa_documentare) as sursa_doc, a.Responsabil_calcul as responsabil, 
		rtrim(p.Nume) as denresponsabil, a.Periodicitate_calcul as periodicitate,
		(case when a.Stare='I' then '#808080' else '#000000' end) as culoare
	from RU_indicatori a 
		left outer join RU_domenii b on a.ID_domeniu=b.ID_domeniu
		left outer join RU_persoane p on a.Responsabil_calcul=p.ID_pers
	where (@lista_lm=0 or a.ID_domeniu in (select Valoare from proprietati where tip='LM' and Cod_proprietate='DOMENIU' 
		and Cod in (select Cod from LMFiltrare lu where lu.utilizator=@utilizator)))
		and	b.Denumire like '%' + @filtruDomeniu + '%'
		and a.Stare like '%' + @filtruStare + '%'
		
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaIndicatori) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)

