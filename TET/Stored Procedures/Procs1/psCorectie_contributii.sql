--***
/**	proc. corectie contributii	*/
Create procedure psCorectie_contributii 
	@dataJos datetime, @dataSus datetime, @marcaJos char(6), @locmJos varchar(9), @TBazaCASCN float, @TBazaCASCD float,@TBazaCASCS float, @TotalCAS decimal(14,4), 
	@TBazaCASCMCN float, @TBazaCASCMCD float, @TBazaCASCMCS float, @TotalCASCM decimal(14,4), @TBazaSomajPCON float, @TBazaSomajPNECON float, @TotalSomaj decimal(14,4), 
	@TBazaCASS float, @TotalCASS decimal(14,4), @TBazaCASSFambpS float, @TotalCASSFambpS decimal(14,4), @TBazaCASSFambpA float, @TotalCASSFambpA decimal(14,4), 
	@TBazaFambp float, @TotalFambp decimal(14,4), @TBazaITM float, @TotalITM decimal(14,4), @TBazaCCI float, @TotalCCI decimal(14,4), 
	@TBazaCCIfambp float, @TotalCCIfambp decimal(14,4), @TBazaFG float, @TotalFG decimal(14,4), @TBazaFGDim float, @TotalFGDim decimal(14,4), @lmCorectie varchar(9)=''
As
Begin try
	declare @utilizator varchar(20), @multiFirma int, @lista_lm int, @DataLunii datetime, 
		@pCASgr3 decimal(7,3), @pCASgr2 decimal(7,3), @pCASgr1 decimal(7,3), @pSomajU decimal(7,3), @pCASSU decimal(7,3), @pCASSind decimal(7,3), 
		@pFambp decimal(7,3), @pITM decimal(7,3), @pCCI decimal(7,3), @pFondGar decimal(7,3) 

	set @DataLunii=dbo.eom(@dataSus)
	set @pCASSind=dbo.iauParLN(@DataLunii,'PS','CASSIND')
	set @pCASgr3=dbo.iauParLN(@DataLunii,'PS','CASGRUPA3')-dbo.iauParLN(@DataLunii,'PS','CASINDIV')
	set @pCASgr2=dbo.iauParLN(@DataLunii,'PS','CASGRUPA2')-dbo.iauParLN(@DataLunii,'PS','CASINDIV')
	set @pCASgr1=dbo.iauParLN(@DataLunii,'PS','CASGRUPA1')-dbo.iauParLN(@DataLunii,'PS','CASINDIV')
	set @pCCI=dbo.iauParLN(@DataLunii,'PS','COTACCI')
	set @pCASSU=dbo.iauParLN(@DataLunii,'PS','CASSUNIT')
	set @pSomajU=dbo.iauParLN(@DataLunii,'PS','3.5%SOMAJ')
	set @pFondGar=dbo.iauParLN(@DataLunii,'PS','FONDGAR')
	set @pFambp=dbo.iauParLN(@DataLunii,'PS','0.5%ACCM')
	set @pITM=dbo.iauParLN(@DataLunii,'PS','1%-CAMERA')

	if (@marcaJos<>'' or @locmJos<>'') and @dataSus>='01/01/2012'
	Begin
		select @TBazaCASCN=sum(n.Baza_CAS_cond_norm), @TBazaCASCD=sum(n.Baza_CAS_cond_deoseb), @TBazaCASCS=sum(n.Baza_CAS_cond_spec), @TotalCAS=sum(n.CAS)
			,@TBazaCASCMCN=sum(n1.Baza_CAS_cond_norm), @TBazaCASCMCD=sum(n1.Baza_CAS_cond_deoseb), @TBazaCASCMCS=sum(n1.Baza_CAS_cond_spec), @TotalCASCM=sum(n1.CAS)
			,@TBazaSomajPCON=sum((case when n.Somaj_1<>0 and not(i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC','ECT')) then n.Asig_sanatate_din_CAS else 0 end))
			,@TBazaSomajPNECON=0, @TotalSomaj=sum(n.Somaj_5) 
			,@TBazaCASS=sum((case when not(i.Grupa_de_munca='O' and (i.Tip_colab in ('DAC','CCC','ECT') or p.As_sanatate=0)) then n.Venit_total-b.CMCas else 0 end)), @TotalCASS=sum(n.Asig_sanatate_pl_unitate)
			,@TBazaCASSFambpS=sum(indFambp), @TotalCASSFambpS=sum(n.Asig_sanatate_din_impozit), @TBazaCASSFambpA=sum(CMFaambpUnit), @TotalCASSFambpA=sum(n1.Asig_sanatate_din_impozit)
			,@TBazaFambp=sum((case when n.Fond_de_risc_1<>0 then 
				n.Baza_CAS_cond_norm+n.Baza_CAS_cond_deoseb+n.Baza_CAS_cond_spec else 0 end)+n1.Asig_sanatate_din_CAS)
			,@TotalFambp=sum(n.Fond_de_risc_1)
			,@TBazaCCI=sum(n1.Baza_CAS), @TotalCCI=sum(n.Ded_suplim)
			,@TBazaCCIfambp=sum(cm.indFambp), @TotalCCIfambp=sum(n1.Ded_suplim), @TBazaFG=sum(n1.CM_incasat), @TotalFG=sum(n1.Somaj_5)
		from net n
			left outer join net n1 on n1.Data=dbo.BOM(n.data) and n1.Marca=n.Marca
			left outer join istpers i on i.Data=n.data and i.Marca=n.Marca
			left outer join personal p on p.Marca=n.Marca
			left outer join (select data, marca, sum(Indemnizatie_unitate) as CMFaambpUnit, sum(Indemnizatie_CAS) as indFambp 
				from conmed where data=@datasus and tip_diagnostic in ('2-','3-','4-') group by data, marca) cm on cm.marca=n.marca
			left outer join (select data, marca, sum(Ind_c_medical_cas+Spor_cond_9) as CMCas from brut where data=@datasus group by data, marca) b on b.marca=n.marca and b.data=n.data
		where n.data=@dataSus and (@lmCorectie='' or n.Loc_de_munca like rtrim(@lmCorectie)+'%')
	End

	if @marcaJos='' or (@marcaJos<>'' or @locmJos<>'') and @dataSus>='01/01/2012'
	Begin
--	pana la decembrie 2010 calculul contributiei angajator la CAS se facea separat: pt. baza de calcul din timp lucrat si baza de calcul aferent concediilor medicale
		if @dataSus<'01/01/2011'
		Begin
			update net set CAS=CAS+round(convert(decimal(12,4),@TBazaCASCN*@pCASgr3/100+@TBazaCASCD*@pCASgr2/100+@TBazaCASCS*@pCASgr1/100),0)-@TotalCAS
			where Data=@dataSus and marca in (select top 1 marca from net where Data=@dataSus and CAS>=0.1 order by CAS desc)
			and abs(round(convert(decimal(12,4),@TBazaCASCN*@pCASgr3/100+@TBazaCASCD*@pCASgr2/100+@TBazaCASCS*@pCASgr1/100),0)-@TotalCAS)>=0.01

			if @TotalCASCM<>0
				update net set CAS=CAS+round(convert(decimal(12,4),@TBazaCASCMCN*@pCASgr3/100+@TBazaCASCMCD*@pCASgr2/100+@TBazaCASCMCS*@pCASgr1/100),0)-@TotalCASCM
				where Data=@dataJos and marca in (select top 1 marca from net where Data=@dataJos and CAS>=0.1)
				and abs(round(convert(decimal(12,4),@TBazaCASCMCN*@pCASgr3/100+@TBazaCASCMCD*@pCASgr2/100+ @TBazaCASCMCS*@pCASgr1/100),0)-@TotalCASCM)>=0.01
		End

--	dupa 01.01.2011 calculul contributiei angajator la CAS se face cumulat pt. baza de calcul din timp lucrat si baza de calcul aferent concediilor medicale
--	contributia de asigurari sociale
		if @dataSus>='01/01/2011'
			update net set CAS=CAS
				+round(convert(decimal(12,4),(@TBazaCASCN+@TBazaCASCMCN)*@pCASgr3/100+(@TBazaCASCD+@TBazaCASCMCD)*@pCASgr2/100+(@TBazaCASCS+@TBazaCASCMCS)*@pCASgr1/100),0)
				-(@TotalCAS+@TotalCASCM)
			where Data=@dataSus and marca in (select top 1 marca from net where Data=@dataSus and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%')
					and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%') and CAS>=0.1 order by CAS desc)
				and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')
				and abs(round(convert(decimal(12,4),(@TBazaCASCN+@TBazaCASCMCN)*@pCASgr3/100+(@TBazaCASCD+@TBazaCASCMCD)*@pCASgr2/100+(@TBazaCASCS+@TBazaCASCMCS)*@pCASgr1/100),0)
					-(@TotalCAS+@TotalCASCM))>=0.01

--	contributia de asigurari sociale pentru somaj
		update net set Somaj_5=Somaj_5+(case when @TBazaSomajPCON*@pSomajU/100+@TBazaSomajPNECON*@pSomajU/100>0 and @TBazaSomajPCON*@pSomajU/100+@TBazaSomajPNECON*@pSomajU/100<1 then 1 
			else round(convert(decimal(12,4),@TBazaSomajPCON*@pSomajU/100+@TBazaSomajPNECON*@pSomajU/100),0) end)-@TotalSomaj 
		where Data=@dataSus and marca in (select top 1 n1.marca from net n1 where n1.Data=@dataSus and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%')
					and (@lmCorectie='' or n1.Loc_de_munca like rtrim(@lmCorectie)+'%') 
				and not exists (select 1 from personal p where p.marca=n1.marca and p.coef_invalid in ('1','2','3','4')) and n1.Somaj_5>=0.01) 
			and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')
			and abs(round(convert(decimal(12,4),@TBazaSomajPCON*@pSomajU/100+@TBazaSomajPNECON*@pSomajU/100),0)-@TotalSomaj)>=0.01

--	contributia de asigurari sociale de sanatate
		update net set Asig_sanatate_pl_unitate=Asig_sanatate_pl_unitate+(case when @TBazaCASS*@pCASSU/100>0 and @TBazaCASS*@pCASSU/100<1 then 1 
			else round(convert(decimal(12,4),@TBazaCASS*@pCASSU/100),0) end)-@TotalCASS 
		where Data=@dataSus and marca in (select top 1 marca from net where Data=@dataSus and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%')
				and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%') and Asig_sanatate_pl_unitate>=0.1)
			and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')
			and abs(round(convert(decimal(12,4),@TBazaCASS*@pCASSU/100),0)-@TotalCASS)>=0.01

		if @TotalCASSFambpS<>0
			update net set Asig_sanatate_din_impozit=Asig_sanatate_din_impozit+round(convert(decimal(12,4),@TBazaCASSFambpS*@pCASSind/100),0)-@TotalCASSFambpS
			where Data=@dataSus and marca in (select top 1 marca from net where Data=@dataSus and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%') 
					and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%') and Asig_sanatate_din_impozit>=0.1)
				and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')
				and abs(round(convert(decimal(12,4),@TBazaCASSFambpS*@pCASSind/100),0)-@TotalCASSFambpS)>=0.01

		if @TotalCASSFambpA<>0
			update net set Asig_sanatate_din_impozit=Asig_sanatate_din_impozit+round(convert(decimal(12,4),@TBazaCASSFambpA*@pCASSind/100),0)-@TotalCASSFambpA
			where Data=@dataJos and marca in (select top 1 marca from net where Data=@dataJos and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%') 
					and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%') and Asig_sanatate_din_impozit>=0.1)
				and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')
				and abs(round(convert(decimal(12,4),@TBazaCASSFambpA*@pCASSind/100),0)-@TotalCASSFambpA)>=0.01
--	fond de accidente de munca si boli profesionale
		update net set Fond_de_risc_1=Fond_de_risc_1+(case when @TBazaFambp*@pFambp/100>0 and @TBazaFambp*@pFambp/100<1 then 1 
			else round(convert(decimal(12,4),@TBazaFambp*@pFambp/100),0) end)-@TotalFambp 
		where Data=@dataSus and marca in (select top 1 marca from net where Data=@dataSus and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%') 
				and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%') and Fond_de_risc_1>=0.01)
			and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')			
			and abs(round(convert(decimal(12,4),@TBazaFambp*@pFambp/100),0)-@TotalFambp)>=0.01
--	Comision Camera de munca
		update net set Camera_de_munca_1=Camera_de_munca_1+(case when @TBazaITM*@pITM/100>0 and @TBazaITM*@pITM/100<1 then 1 
			else round(convert(decimal(12,4),@TBazaITM*@pITM/100),0) end)-@TotalITM 
		where Data=@dataSus and marca in (select top 1 marca from net where Data=@dataSus and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%') 
				and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%') and Camera_de_munca_1>=0.01)
			and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')
			and abs(round(convert(decimal(12,4),@TBazaITM*@pITM/100),0)-@TotalITM)>=0.01
--	Contributia pentru concedii si indemnizatii
		update net set Ded_suplim=Ded_suplim+(case when round(@TBazaCCI,0)*@pCCI/100>0 and round(@TBazaCCI,0)*@pCCI/100<1 then 1 
			else round(convert(decimal(12,4),round(@TBazaCCI,0)*@pCCI/100),0) end)-@TotalCCI 
		where Data=@dataSus and marca in (select top 1 marca from net where Data=@dataSus and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%') 
				and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%') and Ded_suplim>=0.01)
			and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')
			and abs(round(convert(decimal(12,4),round(@TBazaCCI,0)*@pCCI/100),0)-@TotalCCI)>=0.01
--	Contributia pentru concedii si indemnizatii suportata din FAAMBP
		if @TotalCCIfambp<>0
		Begin
			update net set Ded_suplim=Ded_suplim+(case when @TBazaCCIfambp*@pCCI/100>0 and @TBazaCCIfambp*@pCCI/100<1 then 1 
				else round(convert(decimal(12,4),@TBazaCCIfambp*@pCCI/100),0) end)-@TotalCCIfambp
			where Data=@dataJos and marca in (select top 1 marca from net where Data=@dataJos and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%') 
					and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%') and Ded_suplim>=0.1)
				and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')
				and abs(round(convert(decimal(12,4),@TBazaCCIfambp*@pCCI/100),0)-@TotalCCIfambp)>=0.01
		End
--	contributia la fondul de garantare
		if @TotalFG<>0
			update net set Somaj_5=Somaj_5+(case when @TBazaFG*@pFondGar/100>0 and @TBazaFG*@pFondGar/100<1 then 1 
				else round(convert(decimal(12,4),@TBazaFG*@pFondGar/100),0) end)-@TotalFG 
			where Data=@dataJos and marca in (select top 1 marca from net where Data=@dataJos and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%') 
					and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%') and Somaj_5>=0.01)
				and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')
				and abs(round(convert(decimal(12,4),@TBazaFG*@pFondGar/100),0)-@TotalFG)>=0.01

		if @TotalFGDim<>0
			update net set Chelt_prof=Chelt_prof+(case when @TBazaFGDim*@pFondGar/100>0 and @TBazaFGDim*@pFondGar/100<1 then 1 
				else round(convert(decimal(12,4),@TBazaFGDim*@pFondGar/100),0) end)-@TotalFGDim 
			where Data=@dataJos and marca in (select top 1 marca from net where Data=@dataJos and (@locmJos='' or Loc_de_munca like rtrim(@locmJos)+'%') 
					and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%') and Chelt_prof>=0.01)
				and (@lmCorectie='' or Loc_de_munca like rtrim(@lmCorectie)+'%')
				and abs(round(convert(decimal(12,4),@TBazaFGDim*@pFondGar/100),0)-@TotalFGDim)>=0.01
	End
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura psCorectie_contributii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
