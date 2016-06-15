--***
create procedure wRUIaCompetente @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaCompetenteSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaCompetenteSP @sesiune, @parXML output
	return @returnValue
end

declare @filtruDomeniu varchar(30), @filtruTip varchar(30), @filtruID int, @filtruDenumire varchar(200), 
	@utilizator char(10), @lista_lm int, @mesaj varchar(200), @doc xml

begin try
	select
		@filtruDomeniu = isnull(@parXML.value('(/row/@f_domeniu)[1]', 'varchar(30)'), ''),
		@filtruTip = isnull(@parXML.value('(/row/@f_tipcomp)[1]', 'varchar(30)'), ''), 
		@filtruID = @parXML.value('(/row/@f_idcomp)[1]', 'int'),
		@filtruDenumire = isnull(@parXML.value('(/row/@f_dencomp)[1]', 'varchar(200)'), '')
	select @filtruDomeniu = replace(@filtruDomeniu,' ','%'), 
		@filtruTip = replace(@filtruTip,' ','%'),
		@filtruDenumire = replace(@filtruDenumire,' ','%')

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	select @lista_lm=0
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA')

	IF @Utilizator IS NULL
		RETURN -1
set @doc=
	(
	select top 100 c.ID_competenta as id_competenta, c.ID_competenta_parinte as id_competenta_parinte, 
		c.ID_domeniu as id_domeniu, rtrim(c.Denumire) as dencompetenta, 
		c.Tip_competenta as tip_competenta,
		(case when c.tip_competenta=1 then '1-TEHNICA' when c.tip_competenta=2 then '2-MANAGERIALA' when c.tip_competenta=3 then '3-GENERALA' end) as dentipcompetenta, 
		c.tip_calcul_calificativ as tip_calcul, convert(decimal(5,2),c.Procent) as procent, rtrim(c.Descriere) as descriere, 
		(case when rtrim(c.tip_calcul_calificativ)=1 then '1-MEDIE ARITMETICA' when rtrim(c.tip_calcul_calificativ)=2 then '2-SUMA PONDERATA' end) as den_tip_calcul, 
		rtrim(d.Denumire) as dendomeniu, 
--	citesc componentele competentei		
	(select cc.ID_competenta as id_competenta, cc.ID_competenta_parinte as id_competenta_parinte, 
		cc.ID_domeniu as id_domeniu, rtrim(cc.Denumire) as dencompetenta, 
		rtrim(cp.Denumire) as dencompetentaparinte, 
		cc.Tip_competenta as tip_competenta,
		(case when cc.tip_competenta=6 then '6-CUNOSTINTE' when cc.tip_competenta=7 then '7-ABILITATI' when cc.tip_competenta=8 then '8-COMPORTAMENTE' end) as dentipcompetenta, 
		cc.tip_calcul_calificativ as tip_calcul, convert(decimal(5,2),cc.Procent) as procent, 
--		(case when rtrim(cc.tip_calcul_calificativ)=1 then '1-MEDIE ARITMETICA' when rtrim(cc.tip_calcul_calificativ)=2 then '2-SUMA PONDERATA' end) as den_tip_calcul, 
		rtrim(cc.Descriere) as descriere, rtrim(d.Denumire) as dendomeniu
	from RU_competente cc 
		left outer join RU_domenii d on cc.Id_domeniu=d.ID_domeniu
		left outer join RU_competente cp on cp.ID_competenta=cc.ID_competenta_parinte
	where cc.ID_competenta_parinte=c.ID_competenta
	for xml raw, type)
	from RU_competente c 
		left outer join RU_domenii d on c.Id_domeniu=d.ID_domeniu
	where (c.ID_competenta_parinte=0 or c.ID_competenta_parinte is null)
		and (@lista_lm=0 or c.ID_domeniu in (select Valoare from proprietati where tip='LM' and Cod_proprietate='DOMENIU' 
			and Cod in (select Cod from LMFiltrare lu where lu.utilizator=@utilizator)))
		and	(@filtruDomeniu='' or d.Denumire like '%' + @filtruDomeniu + '%')
		and (@filtruTip='' or (case when rtrim(c.tip_competenta)='1' then '1-TEHNICA' when rtrim(c.tip_competenta)='2' then '2-MANAGERIALA' else '3-GENERALA' end) like '%' + @filtruTip + '%')
		and (@filtruID is null or c.ID_competenta=@filtruID)
		and (@filtruDenumire='' or c.Denumire like '%' + @filtruDenumire + '%' or c.ID_competenta like '%' + @filtruDenumire + '%')
	for xml raw,root('Ierarhie'),type
	)

	if @doc is not null
		set @doc.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')	
	
	select @doc for xml path('Date')

end try

begin catch
	set @mesaj = '(wRUIaCompetente) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
	
