--***
/**	procedura calcul Contrib. L118	*/
Create procedure psCalculContributiiL118 
	@dataJos datetime, @dataSus datetime, @MarcaJ char(6), @LocmJ char(9)
As
Begin
	declare @InstPubl int, @pCASind float, @pCASgr3 float, @pCASgr2 float, @pCASgr1 float, @pCCI float, @pCASSU float, @pSomajU float, @pFondGar float, @pFambp float, @CalculITM int, 
	@pITM float, @CASSColab int, @NuITMcolab int, @NuITMpens int, @Somajcolab int, @CCIcolabP int, @CCIcolabO int, @Data datetime, @Marca char(6), @Suma_Diminuare float, @Locm char(9), 
	@BazaCN float, @BazaCD float, @BazaCS float, @TBazaCASCN decimal(12,2), @TBazaCASCD decimal(12,2), @TBazaCASCS decimal(12,2),
	@TotalCAS decimal(12,2), @TotalBAZA decimal(12,2), @TotalCASS decimal(12,2), @TBazaSomaj decimal(12,2), 
	@TotalSomaj decimal(12,2), @TBazaCCI decimal(12,2), @TotalCCI decimal(12,2), @TBazaFambp decimal(12,2), 
	@TotalFambp decimal(12,2), @TBazaFG decimal(12,2), @TotalFG decimal(12,2), @TBazaITM decimal(12,2), @TotalITM decimal(12,2),
	@CASDim decimal(10,2), @CASSDim decimal(10,2), @SomajDim decimal(10,2), @CCIDim decimal(10,2), @FambpDim decimal(10,2), @FondGarDim decimal(10,2), @ITMDim decimal(10,2), 
	@BazaCASCN decimal(10), @BazaCASCD decimal(10), @BazaCASCS decimal(10), @DataNet datetime, @GrpMP char(1), @Somaj1P int, @TipdedSomajP int, @TipCorectieDiminuare char(2)

	set @InstPubl=dbo.iauParL('PS','INSTPUBL')
	set @pCASgr3=dbo.iauParLN(@dataSus,'PS','CASGRUPA3')-dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @pCASgr2=dbo.iauParLN(@dataSus,'PS','CASGRUPA2')-dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @pCASgr1=dbo.iauParLN(@dataSus,'PS','CASGRUPA1')-dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @pCCI=dbo.iauParLN(@dataSus,'PS','COTACCI')
	set @pCASSU=dbo.iauParLN(@dataSus,'PS','CASSUNIT')
	set @pSomajU=dbo.iauParLN(@dataSus,'PS','3.5%SOMAJ')
	set @pFondGar=dbo.iauParLN(@dataSus,'PS','FONDGAR')
	set @pFambp=dbo.iauParLN(@dataSus,'PS','0.5%ACCM')
	set @pITM=dbo.iauParLN(@dataSus,'PS','1%-CAMERA')
	set @CalculITM=dbo.iauParL('PS','1%-CAMERA')
	set @CASSColab=dbo.iauParL('PS','CALFASC')
	set @NuITMColab=dbo.iauParL('PS','NCALPCMC')
	set @NuITMPens=dbo.iauParL('PS','NCALPCMPE')
	set @SomajColab=dbo.iauParL('PS','CAL5FR1')
	set @CCIColabP=dbo.iauParL('PS','CCICOLAB')
	set @CCIColabO=dbo.iauParL('PS','CCICOLABO')
	set @TipCorectieDiminuare=dbo.iauParA('PS','DIML118')
	set @DataNet=DateAdd(day,1,@dataJos)

	select @TotalBAZA=0, @TBazaCASCN=0, @TBazaCASCD=0, @TBazaCASCS=0, @TBazaSomaj=0, @TBazaCCI=0, @TBazaFG=0, @TBazaFambp=0, @TBazaITM=0, @TotalCAS=0, @TotalCASS=0, 
		@TotalSomaj=0, @TotalCCI=0, @TotalFG=0, @TotalFambp=0, @TotalITM=0

	delete from net where Data=@DataNet and (@MarcaJ='' or Marca=@MarcaJ)
	declare ContributiiDiminuari cursor for
	select a.Data, a.Marca, n.Loc_de_munca, a.Suma_corectie, p.Grupa_de_munca, p.Somaj_1, p.Coef_invalid
	from corectii a
		left outer join personal p on p.Marca=a.Marca
		left outer join net n on n.Data=@dataSus and n.Marca=a.Marca
	where a.data=@dataJos and (@MarcaJ='' or a.Marca=@MarcaJ) and a.Tip_corectie_venit=@TipCorectieDiminuare 
		and (@LocmJ='' or a.Loc_de_munca=@LocmJ)

	open ContributiiDiminuari
	fetch next from ContributiiDiminuari into @Data, @Marca, @Locm, @Suma_diminuare, @GrpMP, @Somaj1P, @TipdedSomajP
	While @@fetch_status = 0 
	Begin
		select @CASDim=0, @CASSDim=0, @CASSDim=0, @SomajDim=0, @CCIDim=0, @FondGarDim=0, @FambpDim=0, @ITMDim=0, @BazaCASCN=0, @BazaCASCD=0, @BazaCASCS=0
		set @BazaCASCN=(case when @GrpMP in ('N','P','C') then -@Suma_diminuare else 0 end)
		set @BazaCASCD=(case when @GrpMP='D' then -@Suma_diminuare else 0 end)
		set @BazaCASCS=(case when @GrpMP='S' then -@Suma_diminuare else 0 end)
		select @CASDim=@BazaCASCN*@pCASgr3/100+@BazaCASCD*@pCASgr2/100+@BazaCASCS*@pCASgr1/100 where @GrpMP<>'O'
		select @CASSDim=-@Suma_diminuare*@pCASSU/100
		select @TBazaSomaj=@TBazaSomaj+(-@Suma_diminuare), @SomajDim=-@Suma_diminuare*@pSomajU/100 where not((@GrpMP in ('O','P') or @TipdedSomajP=5) and @Somaj1P=0)
		select @TBazaCCI=@TBazaCCI+(-@Suma_diminuare), @CCIDim=-@Suma_diminuare*@pCCI/100 where not(@GrpMP='O' and @CCIcolabO=0 or @GrpMP='P' and @CCIcolabP=0)
		select @TBazaFG=@TBazaFG+(-@Suma_diminuare), @FondGarDim=-@Suma_diminuare*@pFondGar/100 where not(@GrpMP in ('O','P') or @InstPubl=1)
		select @TBazaFambp=@TBazaFambp+(-@Suma_diminuare), @FambpDim=-@Suma_diminuare*@pFambp/100 where @GrpMP<>'O'
		select @TBazaITM=@TBazaITM+(-@Suma_diminuare), @ITMDim=-@Suma_diminuare*@pITM/100 where @CalculITM=1 and not(@NuITMcolab=1 and @GrpMP in ('O','P') or @NuITMpens=1 and @TipdedSomajP=5)
		select @TotalBAZA=@TotalBAZA+(-@Suma_diminuare), @TBazaCASCN=@TBazaCASCN+@BazaCASCN, 
			@TBazaCASCD=@TBazaCASCD+@BazaCASCD, @TBazaCASCS=@TBazaCASCS+@BazaCASCS, @TotalCAS=@TotalCAS+@CASDim, 
			@TotalCASS=@TotalCASS+@CASSDim, @TotalSomaj=@TotalSomaj+@SomajDim, @TotalCCI=@TotalCCI+@CCIDim, @TotalFG=@TotalFG+@FondGarDim, 
			@TotalFambp=@TotalFambp+@FambpDim, @TotalITM=@TotalITM+@ITMDim
	
		exec scriuNet_salarii @DataNet,@DataNet,@Marca,@Locm,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, @CASDim, @SomajDim, @FambpDim, @ITMDim, @CASSDim,0,'',0,0,0,0, @CCIDim,0, @FondGarDim,0,0,0,0,1

		fetch next from ContributiiDiminuari into @Data, @Marca, @Locm, @Suma_diminuare, @GrpMP, @Somaj1P, @TipdedSomajP
	End

	exec psCorectie_contributii @DataNet, @DataNet, @MarcaJ, @LocmJ, @TBazaCASCN, @TBazaCASCD, @TBazaCASCS, @TotalCAS, 0, 0, 0, 0, @TBazaSomaj, 0, @TotalSomaj, @TotalBAZA, @TotalCASS, 0, 0, 0, 0, 
		@TBazaFambp, @TotalFambp, @TBazaITM, @TotalITM, @TBazaCCI, @TotalCCI, 0, 0, 0, 0, @TBazaFG, @TotalFG, ''

	close ContributiiDiminuari
	Deallocate ContributiiDiminuari
End
