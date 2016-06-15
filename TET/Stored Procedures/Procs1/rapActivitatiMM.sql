--***
create procedure rapActivitatiMM(@cudecada int,@Tip_activitate varchar(1),--@q_AnRaport int,@q_LunaRaport int,
	@GrupaMasina varchar(30),@Masina varchar(30),
	@lm varchar(30),@marca varchar(10),@DataJos datetime,@DataSus datetime)
as
set transaction isolation level read uncommitted
declare @eroare varchar(1000)
set @eroare=''
begin try
/*	--	<initializare configurare elemente standard pt raport (daca nu exista configurarea, se va utiliza configurarea de pe macheta)
		update  e set Ord_raport=Ord_macheta
			from elemtipm e 
		where not exists (select 1 from elemtipm et where e.Tip_masina=et.Tip_masina and et.Ord_raport>0)
	--	/>	*/
	declare @q_cudecada int,@q_Tip_activitate varchar(1),--@q_AnRaport int,@q_LunaRaport int,
		@q_GrupaMasina varchar(30),@q_Masina varchar(30),
		@q_lm varchar(30),@q_marca varchar(10),@q_DataJos datetime,@q_DataSus datetime
	
	select @q_cudecada=convert(int,@cudecada), @q_Tip_activitate=@Tip_activitate --set @q_AnRaport=@AnRaport set @q_LunaRaport=@LunaRaport
			,@q_GrupaMasina=isnull(@GrupaMasina,''), @q_Masina=isnull(@Masina,''), @q_lm=isnull(@lm,'%'), @q_marca=@marca
			,@q_DataJos=@DataJos, @q_DataSus=@DataSus
			
	select @q_GrupaMasina=(case when @q_GrupaMasina='' then '%' else @q_GrupaMasina end), @q_Masina=(case when isnull(@q_Masina,'')='' then '%' else @q_Masina end)

	SELECT     rtrim(a.Masina) Masina, rtrim(m.nr_inmatriculare) nr_inmatriculare, a.Data, 
		rtrim(a.Fisa) Fisa, rtrim(a.Marca) Marca, rtrim(isnull(s.Nume,'<necunoscut>')) as Nume, 
	rtrim(p.Plecare) Plecare, DATEADD(minute, CONVERT(int, SUBSTRING(p.Ora_plecarii, 3, 2)), DATEADD(hour, CONVERT(int, LEFT(p.Ora_plecarii, 2)), p.Data_plecarii)) AS data_ora_plecarii, 
	rtrim(p.Sosire) Sosire, DATEADD(minute, CONVERT(int, SUBSTRING(p.Ora_sosirii, 3, 2)), DATEADD(hour, CONVERT(int, LEFT(p.Ora_sosirii, 2)), p.Data_sosirii)) AS data_ora_sosirii, 
	rtrim(p.Explicatii) Explicatii,
	(case when @q_cudecada=1 then (case when DAY(p.data_plecarii)<=10 then 1 when DAY(p.data_plecarii)<=20 then 2 else 3 end) else null end) AS decada, 
	rtrim(ea.Element) Element, rtrim(e.Denumire) Denumire, ea.Valoare, 
	left(et.grupa, 1) as grupa_1, 
	rtrim(isnull(gr1.denumire, '')) as dengr1, 
	rtrim(substring(et.grupa, 2, 1)) as grupa_2, 
	rtrim(isnull(gr2.denumire, '')) as dengr2, 
	et.Ord_raport, 
	MONTH(p.data_plecarii) AS Luna, YEAR(p.data_plecarii) AS Anul, m.cod_masina+m.denumire+m.nr_inmatriculare as selectie
	--into #tmp
	FROM         activitati a 
	--INNER JOIN pozactivitati p ON a.idActivitati=p.idActivitati
	--INNER JOIN elemactivitati ea ON p.idPozActivitati=ea.idPozActivitati	
	-- pentru cel care va pune la loc id-urile: rog sa comenteze legaturile dupa tip/fisa/data - pentru cei care au replicare
	inner join pozactivitati p on p.Tip=a.Tip and p.Fisa=a.Fisa and p.Data=a.Data	--> se va inlocui cu: a.idActivitati=p.idActivitati
	inner join elemactivitati ea on a.fisa=ea.fisa and a.data=ea.data and a.tip=ea.tip and p.Numar_pozitie=ea.Numar_pozitie	--> se va inlocui cu: p.idPozActivitati=ea.idPozActivitati
	INNER JOIN elemente e ON ea.Element = e.Cod 
	INNER JOIN masini m ON a.Masina = m.cod_masina 
	INNER JOIN tipmasini t ON m.tip_masina = t.Cod 
	INNER JOIN elemtipm et ON et.Tip_masina = m.tip_masina AND et.Element = ea.Element 
	left outer JOIN personal s ON a.Marca = s.Marca
	LEFT OUTER JOIN grrapmt gr1 ON gr1.grupa=left(et.grupa, 1)
	LEFT OUTER JOIN grrapmt gr2 ON len(RTrim(et.grupa))>=2 and gr2.grupa=left(et.grupa, 2)
	WHERE     (@q_Tip_activitate='P' and a.Tip = 'FP' or @q_Tip_activitate='L' and a.Tip='FL') 
		AND (et.Ord_raport > 0) 
		AND p.Data_plecarii between @q_DataJos and @q_DataSus
	--(YEAR(p.Data_plecarii) = @q_AnRaport) AND (MONTH(p.Data_plecarii) = @q_LunaRaport) 
	AND RTrim(m.grupa) LIKE RTrim(@q_GrupaMasina) AND a.masina LIKE RTrim(@q_Masina)
	and (@q_lm is null or a.loc_de_munca like @q_lm) and(@q_marca is null or a.marca=@q_marca)
	ORDER BY a.Masina, p.Data_plecarii, p.Ora_plecarii, p.Fisa, p.Numar_pozitie	
	update par set val_logica=@q_cudecada where tip_parametru='MM' and parametru='CUDECADA'
end try
begin catch
	set @eroare='rapActivitatiMM: '+char(10)+ERROR_MESSAGE()
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)
