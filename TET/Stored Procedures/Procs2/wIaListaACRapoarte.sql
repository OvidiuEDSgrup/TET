--***
create procedure wIaListaACRapoarte (@sesiune varchar(20), @parXML xml)
as
begin
	declare @eroare varchar(2000)
	begin try
		if object_id('tempdb..#standard') is not null drop table #standard
			--> configurarile standard; au prioritate cele ale beneficiarului de aceea mai jos se asigura o ordonare in care cfg std sunt ultimele
		create table #standard(caleraport varchar(500), expresie varchar(200), proceduraAC varchar(200), ordine int identity(1,1))
		insert into #standard(caleraport, expresie, proceduraAC)
		
		select '', '.*antet.*inventar.*', 'wacAntetInventar' union all
		select '', '.*denumir.*|.*cod.*clasificare.*', '' union all
		select '','.*grupa.*masina_.*','wACGrupeDeMasini' union all
		select '','.*grupa.*masin.*','wacGrmasini' union all
		select '','.*grupa.*comenzi.*','wacGrcom' union all
		select '','.*grupa.*tert.*','wacGterti' union all
		select '','.*grupa.*','wacGrupe' union all
		select '','.*grup.*','' union all
		select '','.*decont.*','wacDeconturi' union all
		select '','(.*contract.*)|(.*com.*livrare.*)','wacContracte' union all
		select '','Continent.*','wACContinente' union all
		select '','.*tara.*','wACTari' union all
		select '','.*cont.*','wacConturi' union all
		select '','.*judet.*','wACJudete' union all
		select '','.*tert.*','wACTerti' union all
		select '','.*valut.*','wacValuta' union all
		select '','.*loc.*munca.*','wacLocm' union all
		select '','.*gest.*','wacGestiuni' union all
		select '','.*marca.*','wacSalariati' union all
		select '','.*salariat.*','wacSalariati' union all
		select '','.*efect.*','wacEfect' union all
		select '','.*factur.*','wacFacturi' union all
		select '','.*cod.*intrare.*','wacCodIntrare' union all
		select '','.*categ.*deviz.*','wacCategoriiDL' union all
		select '','(.*comanda.*)|(.*comenzi.*)|(.*deviz.*)','wacComenzi' union all
		select '','.*cod.*','wacNomenclator' union all
		select '','.*categ.*indic.*','wacCategoriiTB' union all
		select '','(.*buget.*indicator.*)|(.*indicator.*buget.*)|(.*componenta economica.*)','wACIndBug' union all
		select '','.*indic.*ec-fin.*','wacIndicatori' union all
		select '','.*diagnostic.*','wACDiagnostic' union all
		select '','.*card.*','wACBanciPers' union all
		select '','(.*fix.*)|(.*de inventar.*)','wacMFixe' union all
		select '','(.*imobilizare.*)','wACImobilizari' union all
		select '','.*tip de miscare.*','wacTipMiscari' union all
		select '','.*element.*','wacElemente' union all
		select '','.*tip.*masin.*','wacTipuriMasini' union all
		select '','.*masina_*','wACMasiniNoi' union all
		select '','.*masin.*','wacMasini' union all
		select '','.*categ.*pret.*','wACCategPret' union all	
		select '','.*furnizor.*','wACTerti' union all
		select '','.*marcat.*','' union all
		select '','.*locati.*','wACLocatii' union all
		select '','.*punct.*livr.*','wACPuncteLivrare' union all
		select '','lot.*','wacLot' union all
		select '','.*document.*','' union all
		select '','.*nitate.*masura.*|UM','wACUM' union all
		select '','.*interventi.*','wACInterventiiMasini' union all
		select '','.*subtip.*cor.*','wACTipCorectii' union all
		select '','.*corecti.*','wACTipCorectiiSubtip'

		declare @ordineMaxSP int
		select @ordineMaxSP=isnull((select max(ordine) from webconfigacrapoarte),0)

		select isnull(caleraport,'') as caleraport, ordine, replace(expresie,'%','.*') expresie,
			rtrim(proceduraAC) as proceduraAC, id, 1 as setul
			from webConfigACRapoarte l union all
		select caleraport, @ordineMaxSP+ordine ordine, replace(expresie,'%','.*') expresie, proceduraAC, 1 id, 2 setul from #standard
		order by setul, ordine asc, id desc
		for xml raw
	end try
	begin catch
		set @eroare=rtrim(error_message())+'(wIaListaACRapoarte '+convert(varchar(20), error_line())+')'
	end catch

	if object_id('tempdb..#standard') is not null drop table #standard
	if len(@eroare)>0 raiserror(@eroare,16,1)
end
