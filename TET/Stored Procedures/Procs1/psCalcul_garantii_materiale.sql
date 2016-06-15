--***
/**	procedura pentru calcul garantii materiale conform setarilor **/
Create procedure psCalcul_garantii_materiale
	@dataJos datetime, @dataSus datetime, @marca varchar(6)=null, @lm varchar(9)=null, @Cu_stergere int=0
As
Begin try 
	declare @Cod_benef_gm char(13), @Calcul_garantii_materiale int, @cBaza_garantii char(1), @dataJos_1 datetime, @dataSus_1 datetime 

	set @Cod_benef_gm=dbo.iauParA('PS','CODBGMAT')
	set @Calcul_garantii_materiale=dbo.iauParL('PS','CALCGMAT')
	set @cBaza_garantii=dbo.iauParA('PS','CALCGMAT')
	set @dataJos_1=dbo.bom(@dataJos-1)
	set @dataSus_1=dbo.eom(@dataJos-1)
	
	if @marca is null set @marca=''
	if @lm is null set @lm=''

	if object_id('tempdb..#Garantii') is not null drop table #Garantii

	if @Cu_stergere=1
		delete from resal where data between @dataJos and @dataSus and (@marca='' or marca=@marca) and Cod_beneficiar=@Cod_benef_gm and Numar_document='GARANTII'

	select a.marca, isnull(p.nume,'') as Nume, isnull(convert(int,a.val_inf)*p.Salar_de_incadrare,0) as Valoare_totala_garantie, 
	isnull(round((case when @cBaza_garantii='1' then a.procent/100*p.Salar_de_incadrare when @cBaza_garantii='2' then convert(int,a.Val_inf)*p.Salar_de_incadrare/a.Procent 
		else a.Procent end),0),0) as Valoare_lunara_garantie,
	a.procent as Procent_nrluni_suma, isnull(p.salar_de_incadrare,0) as salar_de_incadrare, 
	(select count(1) from resal r where r.data between @dataJos_1 and @dataSus_1 and r.marca=a.marca and r.cod_beneficiar=@Cod_benef_gm and r.numar_document='GARANTII') Exista_retinere_luna_ant, 
	(select data_document from resal r where r.data between @dataJos_1 and @dataSus_1 and r.marca=a.marca and r.cod_beneficiar=@Cod_benef_gm and r.numar_document='GARANTII') as Data_doc_ant
	into #Garantii
	from extinfop a
		left outer join personal p on p.marca=a.marca 
	where a.cod_inf='GARANTII' and (@marca='' or a.marca=@marca) and (rtrim(a.Val_inf)<>'' or a.Procent<>0)
		and (p.Loc_ramas_vacant=0 or p.Data_plec>@dataJos)

	update resal set Valoare_totala_pe_doc=a.Valoare_totala_garantie, Retinere_progr_la_lichidare=Valoare_lunara_garantie
	from #Garantii a
	where resal.marca=a.Marca and resal.data between @dataJos and @dataSus and resal.cod_beneficiar=@Cod_benef_gm and resal.numar_document='GARANTII' and a.Nume<>''

	insert 
	into resal (Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, Retinere_progr_la_avans, Retinere_progr_la_lichidare, 
		Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare) 
	select @dataSus, a.Marca, @Cod_benef_gm, 'GARANTII', (case when Exista_retinere_luna_ant>0 then a.Data_doc_ant else @dataSus end), a.Valoare_totala_garantie, 
		0, 0, a.Valoare_lunara_garantie, 0, 0, 0
	from #Garantii a 
	where a.Nume<>'' and not exists (select marca from resal where marca=a.Marca and data between @dataJos and @dataSus and cod_beneficiar=@Cod_benef_gm and numar_document='GARANTII') 

	if object_id('tempdb..#Garantii') is not null drop table #Garantii
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura psCalcul_garantii_materiale (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch

