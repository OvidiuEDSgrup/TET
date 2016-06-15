--***
Create
function [dbo].[fDeclaratia112CMFambp] 
	(@DataJ datetime, @DataS datetime, @oMarca int, @Marca char(6), @Lm char(9), @Strict int)
returns @FambpAngajator table 
	(Data datetime, NrCazuriIT int, NrCazuriTT int, NrCazuriRT int, NrCazuriCC int, 
	ZileCM int, ZileCMIT int, ZileCMTT int, ZileCMRT int, ZileCMCC int, 
	Indemnizatie decimal(10), IndemnizatieIT decimal(10), IndemnizatieTT decimal(10), IndemnizatieRT decimal(10), IndemnizatieCC decimal(10), 
	IndemnizatieFambp decimal(10), IndemnizITFambp decimal(10), IndemnizTTFambp decimal(10), IndemnizRTFambp decimal(10), IndemnizCCFambp decimal(10), 
	NrCazuriAjDeces int, SumaAjDeces decimal(10))
as
Begin
	declare @Subtipcor int, @NrCazuriAjDeces int, @SumaAjDeces decimal(10), @AjDecesUnitate int
	Set @Subtipcor=dbo.iauParL('PS','SUBTIPCOR')
	Set @AjDecesUnitate=dbo.iauParL('PS','AJDUNIT-R')

	declare @tmpfambp table 
		(Data datetime, Diagnostic char(3), Nr_cazuri int, ZileCM int, Indemnizatie decimal(10), Indemniz_fambp decimal(10))
	insert @tmpfambp
	select a.Data, (case when (a.tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-') then 'IT' 
		when tip_diagnostic='10' and a.suma=1 then 'RT' when tip_diagnostic='11' and a.suma=1 then 'TT' else 'CC' end), 
		count(distinct a.marca+convert(char(10),a.data_inceput,102)), sum(zile_lucratoare), sum(indemnizatie_unitate+indemnizatie_cas), 
		sum(indemnizatie_cas)
	from conmed a, istpers b
	where a.marca=b.marca and a.data between @DataJ and @DataS and a.data_inceput between @DataJ and @DataS 
		and (@oMarca=0 or a.marca=@Marca) and a.data=b.data and (@Lm='' or b.loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and ((tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-') or (tip_diagnostic='10' or tip_diagnostic='11') and a.suma=1)
	group by a.Data, (case when (a.tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-') then 'IT' 
	when tip_diagnostic='10' and a.suma=1 then 'RT' 
	when tip_diagnostic='11' and a.suma=1 then 'TT' else 'CC' end)

	select @NrCazuriAjDeces=count(distinct a.marca), @SumaAjDeces=sum(suma_corectie) 
	from corectii a, personal b
	where a.marca=b.marca and a.data between @DataJ and @DataS and (@oMarca=0 or a.marca=@Marca) 
	and (@Lm='' or b.loc_de_munca like rtrim(@Lm)+( case when @Strict=0 then '%' else '' end)) 
	and (@Subtipcor=0 and tip_corectie_venit='R-' or @Subtipcor=1 and Tip_corectie_venit in (select s.Subtip from Subtipcor s where s.tip_corectie_venit='R-'))
	and @AjDecesUnitate=0

	insert into @FambpAngajator
	select Data, sum((case when Diagnostic='IT' then Nr_cazuri else 0 end)), sum((case when Diagnostic='TT' then Nr_cazuri else 0 end)),
		sum((case when Diagnostic='RT' then Nr_cazuri else 0 end)), sum((case when Diagnostic='CC' then Nr_cazuri else 0 end)),
		sum((case when Diagnostic='RM' then Nr_cazuri else 0 end)), 
		sum((case when Diagnostic='IT' then ZileCM else 0 end)), sum((case when Diagnostic='TT' then ZileCM else 0 end)), 
		sum((case when Diagnostic='RT' then ZileCM else 0 end)), sum((case when Diagnostic='CC' then ZileCM else 0 end)), 
		sum(Indemnizatie), sum((case when Diagnostic='IT' then Indemnizatie else 0 end)), 
		sum((case when Diagnostic='TT' then Indemnizatie else 0 end)), sum((case when Diagnostic='RT' then Indemnizatie else 0 end)), 
		sum((case when Diagnostic='CC' then Indemnizatie else 0 end)), 
		sum(Indemniz_fambp),
		sum((case when Diagnostic='IT' then Indemniz_fambp else 0 end)), sum((case when Diagnostic='TT' then Indemniz_fambp else 0 end)),
		sum((case when Diagnostic='RT' then Indemniz_fambp else 0 end)), sum((case when Diagnostic='CC' then Indemniz_fambp else 0 end)),
		@NrCazuriAjDeces, @SumaAjDeces
	from @tmpfambp
	group by data

	if isnull((select count(1) from @FambpAngajator),0)=0 and @NrCazuriAjDeces<>0
		insert into @FambpAngajator
		values (@DataS, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @NrCazuriAjDeces, @SumaAjDeces)

	return
End

/*
select * from fDeclaratia112CMFambp ('02/01/2011', '02/28/2011', 0, '', '', 0)
*/
