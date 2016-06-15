/* operatie pt. generare NC pt. impozit zilieri  */
Create procedure GenNCImpozitZilieri
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @Continuare int output, @NrPozitie int output, @LMImpozitZilieri decimal(10,2) output
As
Begin
	declare @userASiS char(10), @lista_lm int, @multiFirma int, @Sub char(9), @NCTaxePLM int, @AnPLImpozit int, @AnContImpozit varchar(10), 
	@DebitImpozitZilieri varchar(20), @CreditImpozitZilieri varchar(20), @NumarDoc char(8), @cDataDoc char(4), @Explicatii char(50), @ContDebitor varchar(20), @ContCreditor varchar(20), 
	@Data datetime, @Marca char(6), @Impozit decimal(10,2), @Lm char(9), @gfetch int

	set @userASiS=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@userASiS)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @NCTaxePLM=dbo.iauParL('PS','N-C-TX-LM')
	set @AnPLImpozit=dbo.iauParL('PS','AN-PL-IMP')
	set @DebitImpozitZilieri=dbo.iauParA('PS','N-I-ZILD')
	set @CreditImpozitZilieri=dbo.iauParA('PS','N-I-ZILC')
	set @cDataDoc=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),2)
	set @NumarDoc='SAL'+@cDataDoc

	declare ImpozitZilieri cursor for
	select dbo.eom(a.Data), (case when @AnPLImpozit=1 then isnull(pj.Valoare,'') else '' end) as AnaliticContImpozit, 
	a.Loc_de_munca as Loc_de_munca, sum(a.Impozit)
	from SalariiZilieri a
		left outer join Zilieri z on z.Marca=a.Marca
		left outer join Judete j on j.Cod_judet=z.Judet
		left outer join proprietati pj on pj.tip='JUDET' and pj.cod_proprietate='ANCTIMPOZIT' and pj.Cod=z.Judet and pj.Valoare<>''
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.loc_de_munca
	where a.data between @dataJos and @dataSus and (@pMarca='' or a.marca=@pMarca) 
		and (dbo.eom(a.Data)>=z.Data_angajarii or 1=1)
		and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
	Group by dbo.eom(a.Data), (case when @AnPLImpozit=1 then isnull(pj.Valoare,'') else '' end), a.Loc_de_munca 
	Order by dbo.eom(a.Data), a.Loc_de_munca

	open ImpozitZilieri
	fetch next from ImpozitZilieri into @Data, @AnContImpozit, @Lm, @Impozit
	Set @gfetch=@@fetch_status
	While @gfetch = 0 
	Begin
		select @LMImpozitZilieri=(case when @NCTaxePLM=0 then @LMImpozitZilieri else 0 end)+@Impozit
--	formez analitic cont creditor daca setare [X]Analitic punct de lucru la contul de impozit
		set @ContCreditor=rtrim(@CreditImpozitZilieri)+(case when @AnPLImpozit=1 then '.'+rtrim(@AnContImpozit) else '' end)
		if @NCTaxePLM=1
			exec scriuNCsalarii @Data, @DebitImpozitZilieri, @ContCreditor, @LMImpozitZilieri, @NumarDoc, 
				'Impozit - zilieri', @Continuare output, @NrPozitie output, @Lm, '', '', 0, '', '', 0

		fetch next from ImpozitZilieri into @Data, @AnContImpozit, @Lm, @Impozit
		set @gfetch=@@fetch_status
	End
	close ImpozitZilieri
	Deallocate ImpozitZilieri
End

/*
	exec GenNCImpozitZilieri '07/01/2011', '07/31/2011', '', 1, 0, 0
*/
