--***
create procedure rapFazMM(@DataJos datetime,@DataSus datetime, @GrupaMasina varchar(50),@Masina varchar(50))
/*
declare @DataJos datetime,@DataSus datetime, @AnRaport int, @LunaRaport int, @GrupaMasina varchar(20),@Masina varchar(20)
set @DataJos='2009-1-1' set @DataSus='2009-1-31'
--*/
as
--if object_id('tempdb.dbo.#elemt') is not null drop table #elemt
set transaction isolation level read uncommitted
declare @eroare varchar(1000)
set @eroare=''
begin try

	declare @q_DataJos datetime, @q_DataSus datetime, @q_GrupaMasina varchar(50),@q_Masina varchar(50)
	select @q_DataJos=@DataJos, @q_DataSus=@DataSus, @q_GrupaMasina=@GrupaMasina, @q_Masina=@Masina

	declare @fltKmEf varchar(500), @fltKmPlin varchar(500), @fltKmGOL varchar(500), 
			@fltAlimentat varchar(500), @fltConsumNormat varchar(500),
			@fltRestRezervor varchar(500), @fltConsumEfectiv varchar(500),
			@fltToate varchar(500)
	
	select @fltKmEf='KmEf', @fltKmPlin='KmExUrbPLIN, KmUrbanPLIN, KmUrbPersPLIN, KmExtUrbPersPLIN',
			@fltKmGOL='KmExUrbGOL, KmUrbanGOL, KmUrbPersGOL, KmExtUrbPersGOL',
			@fltAlimentat='AlimComb',
			@fltConsumNormat='ConsComb',
			@fltRestRezervor='CombInRezervor',
			@fltConsumEfectiv='ConsEf'
--	charindex(','+rtrim(ea.element)+',',','+@fltKmGOL+',')>0
	select @fltToate=','+@fltKmEf+','+@fltKmPlin+','+@fltKmGOL+','+@fltAlimentat+','+
					@fltConsumNormat+','+@fltRestRezervor+','+@fltConsumNormat+','+@fltConsumEfectiv
	
	SELECT a.masina, m.nr_inmatriculare as nr_inmatriculare,max(m.denumire) denumire, a.data, 
		a.fisa, 
		month(a.data) as Luna, year(a.data) as Anul, 
		a.marca, max(s.nume) as Nume, 
	sum(case when ea.element=@fltKmEf then ea.valoare else 0 end) as KmEf, 
	sum(case when charindex(','+rtrim(ea.element)+',',','+@fltKmPlin+',')>0 then ea.valoare else 0 end) as KmPlin, 
	sum(case when charindex(','+rtrim(ea.element)+',',','+@fltKmGOL+',')>0 then ea.valoare else 0 end) as KmGOL, 
	sum(case when ea.element like @fltAlimentat+'%' and et.mod_calcul='O' then ea.valoare else 0 end) as Alimentat, 
	sum(case when ea.element like @fltAlimentat+'%' and et.mod_calcul='O' then isnull(pd.pret_valuta, 0) else 0 end) as PretAlimentare, 
	sum(case when ea.element=@fltConsumNormat then ea.valoare else 0 end) as ConsumNormat, 
	sum(case when rtrim(ea.element)=@fltRestRezervor/*'RestDecl'*/ then ea.valoare else 0 end) as RestRezervor, 
	sum(case when rtrim(ea.element)=@fltConsumEfectiv then ea.valoare else 0 end) as ConsumEfectiv, 
	max(left(p.lm_beneficiar, 1)) as divizia, 
	isnull((select max(cf.valoare) from coefmasini cf where cf.masina=a.masina and cf.coeficient='capRezervor'), 0) as CapRezervor, 
	--sum(isnull((select top 1 valoare from elemactivitati ea1 where exists (select masina from activitati a1 where a1.tip=ea1.tip and a1.fisa=ea1.fisa and a1.data=ea1.data and a1.masina=a.masina) and ea1.element='CombInRezervor' and ea1.data <@q_DataJos order by ea1.data DESC)), 
	isnull((select max(ve.valoare) from valelemimpl ve where ve.masina=a.masina and (ve.element='CombInRezervor' or ve.element='RestComb' or ve.element='RestEst')),0) as RestLunaPrec, 
	0 as PretMediuPrec, 
	0 as PretMediuLuna
	--, (case when ea.element='CombInRezervor' then 1 else 0 end)
	,max(m.grupa)
	FROM activitati a 
	INNER JOIN pozactivitati p ON a.idActivitati=p.idActivitati
	INNER JOIN elemactivitati ea ON p.idPozActivitati=ea.idPozActivitati
	INNER JOIN elemente e ON ea.Element = e.Cod 
	INNER JOIN masini m ON a.Masina = m.cod_masina 
	INNER JOIN tipmasini t ON m.tip_masina = t.Cod 
	INNER JOIN elemtipm et ON et.Tip_masina = m.tip_masina AND et.Element = ea.Element 
	INNER JOIN personal s ON a.Marca = s.Marca 
	LEFT OUTER JOIN pozdoc pd ON ea.element like @fltAlimentat+'%' and et.mod_calcul='O' and pd.tip=ea.tip_document and pd.numar=ea.numar_document and pd.data=ea.data_document and abs(pd.cantitate-ea.valoare)<1 

	WHERE charindex(rtrim(ea.Element),rtrim(@fltToate))>0 and
		a.Tip = 'FP' and  p.data_plecarii between @q_DataJos and @q_DataSus
		and m.grupa like (case when isnull(RTrim(@q_GrupaMasina),'')='' then '%' else @q_GrupaMasina end) 
		--and rtrim(m.grupa)=@q_GrupaMasina
		and a.masina like  (case when isnull(@q_Masina,'')='' then '%' else rtrim(@q_Masina) end) 
--	and (pd.cod is null or pd.cod in ('68', '69') or 1=1) */
	GROUP BY a.masina, a.data, a.fisa, a.marca, m.nr_inmatriculare, month(a.data), year(a.data),
			(case when ea.element=@fltRestRezervor then 1 else 0 end)
	ORDER BY a.Masina, a.Data, a.Fisa, a.marca, (case when ea.element=@fltRestRezervor then 1 else 0 end)

end try
begin catch
	set @eroare='rapFazMM: '+char(10)+ERROR_MESSAGE()
end catch

--if object_id('tempdb.dbo.#elemt') is not null drop table #elemt

if len(@eroare)>0 raiserror(@eroare,16,1)
