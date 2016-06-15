/* operatie pt. generare NC pt. cheltuieli salarii zilieri*/
Create procedure GenNCCheltZilieri
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @Continuare int output, @NrPozitie int output
As
Begin
	declare @userASiS char(10), @lista_lm int, @multiFirma int, @Sub char(9), @NCAnActiv int, @NCAnActivCtChelt int, 
	@DebitCheltZilieri varchar(20), @CreditCheltZilieri varchar(20), @AnActivDeb char(10), @AnActivCre char(10), 
	@Data datetime, @Lm char(9), @Marca char(6), @Comanda varchar(20), @TCheltLMZilieri decimal(10,2), @gfetch int,
	@NumarDoc char(8), @cDataDoc char(4), @Explicatii char(50)

	set @userASiS=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@userASiS)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @NCAnActiv=dbo.iauParL('PS','N-C-A-ACT')
	set @NCAnActivCtChelt=dbo.iauParA('PS','N-C-A-ACT')

	set @DebitCheltZilieri=dbo.iauParA('PS','N-C-ZILD')
	set @CreditCheltZilieri=dbo.iauParA('PS','N-C-ZILC')

	set @cDataDoc=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),2)
	set @NumarDoc='SAL'+@cDataDoc

	declare CheltLMZilieri cursor for
	select dbo.eom(a.Data), a.Loc_de_munca, a.Comanda, sum(Venit_total)
	from SalariiZilieri a
		left outer join Zilieri z on z.Marca=a.Marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.loc_de_munca
	where a.data between @dataJos and @dataSus 
		and (@pMarca='' or a.marca=@pMarca) and (dbo.eom(a.Data)>=z.Data_angajarii or 1=1)
		and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
	group by dbo.eom(a.Data), a.Loc_de_munca, a.Comanda
	order by a.loc_de_munca, a.Comanda

	open CheltLMZilieri
	fetch next from CheltLMZilieri into @Data, @Lm, @Comanda, @TCheltLMZilieri
	set @gfetch=@@fetch_status
	While @gfetch = 0 
	Begin
		set @Explicatii='Cheltuieli zilieri - '+rtrim(@lm)
		exec scriuNCsalarii @dataSus, @DebitCheltZilieri, @CreditCheltZilieri, @TCheltLMZilieri, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @Lm, @Comanda, '', 0, '', '', 0

		fetch next from CheltLMZilieri into @Data, @Lm, @Comanda, @TCheltLMZilieri
		set @gfetch=@@fetch_status
	End
	close CheltLMZilieri
	Deallocate CheltLMZilieri
End

/*
	exec GenNCCheltZilieri '07/01/2011', '07/31/2011', '', 1, 309014
*/
