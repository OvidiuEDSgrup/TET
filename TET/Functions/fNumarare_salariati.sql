--***
/**	functie numarare salariati	*/
Create function fNumarare_salariati 
	(@dataJos datetime, @dataSus datetime, @Ce_numar char(1), @pCod_functie char(6), @pLoc_de_munca char(9), @pTip_stat_plata char(10), @activitate varchar(20))
/*
	@Ce_numar: H- calcul numar salariati cu handicap pt. contributie neangajare persoane cu handicap
	@Ce_numar: C- calcul numar salariati pt. pplafonare CCI
*/
Returns float
As
Begin
	Declare @utilizator varchar(20), @multiFirma int, @lista_lm int, @Numar_salariati float, @nAn_inchis int, @nLuna_inchisa int, @Data_inchisa datetime, 
		@CASS_colab int, @NuCAS_H int, @Cassimps_K int, @SalComp int, @CorSalComp char(20)

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @CASS_colab=dbo.iauParL('PS','CALFASC')
	set @NuCAS_H=dbo.iauParL('PS','NUCAS-H')
	set @Cassimps_K=dbo.iauParL('PS','ASSIMPS-K')
	set @SalComp=dbo.iauParL('PS','SALCOMP')
	set @CorSalComp=dbo.iauParA('PS','SALCOMP')
	set @nAn_inchis=dbo.iauParN('PS','ANUL-INCH')
	set @nLuna_inchisa=dbo.iauParN('PS','LUNA-INCH')
	set @Data_inchisa=dbo.eom(convert(datetime,convert(char(2),@nLuna_inchisa)+'/01/'+convert(char(4),@nAn_inchis)))

	declare @asigcci table (marca char(6))
	insert into @asigcci
	select b.marca from brut b
		left outer join personal p on b.Marca=p.Marca
		left outer join dbo.fSumeCorectie (@DataJos, @DataSus, @CorSalComp, '', '', 1) s on @SalComp=1 and s.Data=b.Data and s.Marca=b.Marca and s.Loc_de_munca=b.Loc_de_munca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
	where @Ce_numar ='C' and b.data=@DataSus 
		and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
		and (@activitate is null or p.Activitate=@activitate)
		and round(b.Venit_cond_normale,0)+round(b.Venit_cond_deosebite,0)+round(b.Venit_cond_speciale,0)
		-(case when @NuCAS_H=1 then b.Suma_impozabila else 0 end)
		-(case when @Cassimps_K=1 and not(year(@DataSus)>=2011 and p.Grupa_de_munca in ('O','P') and p.Tip_colab='AS2') then b.Cons_admin else 0 end)
		-isnull(s.Suma_corectie,0)
		+(case when @CASS_colab=1 and p.Grupa_de_munca='O' and year(b.Data)<2011 or p.Grupa_de_munca='O' and p.Tip_colab='AS2' and year(b.Data)>=2011 then b.Venit_total else 0 end)<>0
	
	set @Numar_salariati = 0
	set @Numar_salariati=isnull((select (case when @DataJos>@Data_inchisa then 
		(select count(distinct p.cod_numeric_personal) 
		from personal p
			left outer join infopers ip on p.marca=ip.marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
		where (p.loc_ramas_vacant=0 or p.data_plec>@DataJos) 
			and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
			and (@Ce_numar <>'H' or p.grad_invalid in ('1','2','3') and p.grupa_de_munca not in ('O','P')) 
			and (@Ce_numar ='C' and not(p.Grupa_de_munca in ('O','P') and p.Tip_colab in ('AS4','AS5','AS6')
				or p.Grupa_de_munca in ('O') and p.Tip_colab in ('DAC','CCC','ECT')) and p.marca in (select Marca from @asigcci)
				or @Ce_numar <>'C' and p.grupa_de_munca not in ('O','P')) 
			and p.data_angajarii_in_unitate<=@DataSus 
			and (p.marca not in (select marca from conmed where data=@DataSus and tip_diagnostic='0-') 
				or p.marca in (select marca from brut where data=@DataSus and VENIT_TOTAL<>0)) 
			and (@pCod_functie='' or p.cod_functie=@pCod_functie) 
			and (@pLoc_de_munca='' or p.loc_de_munca like rtrim(@pLoc_de_munca)+'%') 
			and (@pTip_stat_plata='' or ip.religia=@pTip_stat_plata)
			and (@activitate is null or p.Activitate=@activitate))
	else
		(select count(distinct p.cod_numeric_personal) 
		from istpers i
			left outer join personal p on i.marca=p.marca
			left outer join infopers ip on i.marca=ip.marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
		where i.data=@DataSus 
			and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
			and (@Ce_numar <>'H' or i.grad_invalid in ('1','2','3')) and i.grupa_de_munca not in ('O','P') 
			and i.marca not in (select marca from conmed where data=@DataSus and tip_diagnostic='0-') 
			and i.marca in (select marca from brut where data=@DataSus) 
			and (@pCod_functie='' or i.cod_functie=@pCod_functie) 
			and (@pLoc_de_munca='' or i.loc_de_munca like rtrim(@pLoc_de_munca)+'%') 
			and (@pTip_stat_plata='' or ip.religia=@pTip_stat_plata)
			and (@activitate is null or p.Activitate=@activitate)
			/*and (p.loc_ramas_vacant=0 or i.data_plec>@DataJos)*/) end)),0)

	Return (@Numar_salariati)
End
