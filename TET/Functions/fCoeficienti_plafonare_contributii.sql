--***
/**	functie calcul coef. plafonare	*/
Create function fCoeficienti_plafonare_contributii
	(@dataJos datetime, @dataSus datetime)
returns @plafonare_contributii table
	(Venit_plafonare_CAS float, Numar_mediu_salariati_CAS float, Coeficient_CAS float, Venit_plafonare_CCI float, Numar_salariati_CCI float, Coeficient_CCI float)
As
Begin
	declare @utilizator varchar(20), @multiFirma int, @lista_lm int, @OreLuna int, @SalarMediu float, @SalarMinim float, 
		@NuCAS_H int, @Cassimps_K int, @CASS_colab int, @lFara_plafonare int, @SalComp int,@CorSalComp char(20), @AlocHrana int, @CorAlocHrana char(20),
		@Numar_mediu_salariati_CAS float, @Numar_salariati_CCI float, @vBazaCASCM decimal(7,3)

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @OreLuna=dbo.iauParLN(@dataSus, 'PS', 'ORE_LUNA')
	set @SalarMediu=dbo.iauParLN(@dataSus, 'PS', 'SALMBRUT')
	set @SalarMinim=dbo.iauParLN(@dataSus, 'PS', 'S-MIN-BR')
	set @vBazaCASCM=(case when year(@dataSus)>=2011 then 0.35*@SalarMediu else @SalarMinim end)
	set @NuCAS_H=dbo.iauParL('PS','NUCAS-H')
	set @Cassimps_K=dbo.iauParL('PS','ASSIMPS-K')
	set @CASS_colab=dbo.iauParL('PS','CALFASC')
	set @lFara_plafonare=dbo.iauParL('PS','CCIFPLAF')
	set @SalComp=dbo.iauParL('PS','SALCOMP')
	set @CorSalComp=dbo.iauParA('PS','SALCOMP')
	set @AlocHrana=dbo.iauParL('PS','ALOCHRANA')
	set @CorAlocHrana=dbo.iauParA('PS','ALOCHRANA')

	set @Numar_mediu_salariati_CAS=(case when isnull(dbo.iauParL('PS','NRMEDANG'),1)=1 then dbo.iauParN('PS','NRMEDANG') 
		else isnull((select dbo.fNumar_mediu_angajati_bass(@dataJos,@dataSus)),1) end)
	set @Numar_salariati_CCI=isnull((select dbo.fNumarare_salariati (@dataJos,@dataSus,'C','','','',null)),0)

	insert @plafonare_contributii
	Select sum(round(b.Venit_cond_normale,0)+round(b.Venit_cond_deosebite,0)+round(b.Venit_cond_speciale,0)
		-(b.Ind_c_medical_unitate+b.Ind_c_medical_CAS+b.CMCAS+b.CMunitate+b.Spor_cond_9)
		-(case when @NuCAS_H=1 then b.Suma_impozabila else 0 end)-(case when @Cassimps_K=1 then b.Cons_admin else 0 end))
		+isnull((select sum(round(convert(decimal(10,2),(c.Zcm_18+c.Zcm15-c.Zcm_18_ant)*@vBazaCASCM/(@OreLuna/8.00)+c.Baza_CASCM_ant),0)) from fSumeCMmarca (@dataJos, @dataSus, '') c),0),
		@Numar_mediu_salariati_CAS, 0, 
		sum((case when year(@dataSus)>=2011 and p.Grupa_de_munca in ('O','P') and p.Tip_colab in ('AS4','AS5','AS6','DAC','CCC','ECT') then 0 
		else round(b.Venit_cond_normale,0)+round(b.Venit_cond_deosebite,0)+round(b.Venit_cond_speciale,0)
		-(b.Ind_c_medical_CAS+b.CMCAS)-(case when @NuCAS_H=1 then b.Suma_impozabila else 0 end)-(case when @Cassimps_K=1 then b.Cons_admin else 0 end)
		-isnull(s.Suma_corectie,0)-isnull(h.Suma_corectie,0)
		+(case when @CASS_colab=1 and p.Grupa_de_munca='O' and year(b.Data)<2011 or p.Grupa_de_munca='O' and p.Tip_colab='AS2' and year(b.Data)>=2011 then b.Venit_total else 0 end) end)), 
		@Numar_salariati_CCI, 0
	from brut b 
		left outer join personal p on b.marca=p.marca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, @CorSalComp, '', '', 1) s on @SalComp=1 and s.Data=b.Data and s.Marca=b.Marca and s.Loc_de_munca=b.Loc_de_munca
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, @CorAlocHrana, '', '', 1) h on @AlocHrana=1 and h.Data=b.Data and h.Marca=b.Marca and h.Loc_de_munca=b.Loc_de_munca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where b.data between @dataJos and @dataSus 
		and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)

	update @plafonare_contributii set Coeficient_CAS=(case when 
		Venit_plafonare_CAS>(case when @Numar_mediu_salariati_CAS=0 then 1 else @Numar_mediu_salariati_CAS end)*5*@SalarMediu 
		and (year(@dataSus)<2008 or year(@dataSus)>=2011) then round(@Numar_mediu_salariati_CAS*5*@SalarMediu/Venit_plafonare_CAS,8) else 1 end), 
		Coeficient_CCI=(case when Venit_plafonare_CCI>@Numar_salariati_CCI*12*@SalarMinim and @lFara_plafonare=0 
		then round(@Numar_salariati_CCI*12*@SalarMinim/Venit_plafonare_CCI,8) else 1 end)
	return
End
