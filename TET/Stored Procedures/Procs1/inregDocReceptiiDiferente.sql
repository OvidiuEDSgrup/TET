--***
create procedure inregDocReceptiiDiferente @sesiune varchar(50), @parXML xml 
as
Declare @Sub char(9), @cContPlus varchar(40), @cContMinus varchar(40), @nValMin float, @ctVenCh varchar(40), @CtAdaos varchar(40), @CtTVAnx varchar(40)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
exec luare_date_par 'GE', 'GENDIFRM', 1, @nValMin output, ''
exec luare_date_par 'GE', 'RMCTDIFP', 1, 1, @cContPlus output
exec luare_date_par 'GE', 'RMCTDIFN', 1, 1, @cContMinus output
exec luare_date_par 'GE', 'CADAOS', 0, 0, @CtAdaos output
exec luare_date_par 'GE', 'CNTVA', 0, 0, @CtTVAnx output

begin try	
	if object_id('tempdb..#pozdocDifRec') is not null drop table #pozdocDifRec

-- determin intr-o tabela temporara valorile de contat
	select p.Subunitate, p.tip, p.numar, p.data, max(p.utilizator) as utilizator, p.Loc_de_munca, p.comanda, max(p.jurnal) as jurnal
		,max(p.data_operarii) as data_operarii, max(p.ora_operarii) as ora_operarii
		,p.cont_de_stoc, sum(round(convert(decimal(17,5), p.cantitate*p.pret_de_stoc), 2)) - convert(decimal(17,5), max(ic.suma_inreg)) as valoare
	into #pozdocDifRec
	from pozdoc p 
--	citesc doar pozitiile selectate in inregDoc (pentru a nu dubla conditia RM cu prestari)
		inner join #pozdoc pd on p.subunitate=pd.subunitate and p.tip=pd.tip and p.numar=pd.numar and p.data=pd.data and p.idPozDoc=pd.idPozDoc
		inner join conturi c on p.subunitate = c.subunitate and p.cont_de_stoc = c.cont and c.sold_credit = 3
--	citesc valoarea inregistrarilor contabile generate prin inregDoc din tabela temporara
		outer apply (select sum(round(convert(decimal(17,5), suma), 2)) as suma_inreg 
			from #pozincon po where po.subunitate = p.subunitate and po.tip = p.tip
				and po.numar = p.numar and po.data = p.data and po.cont_debitor = p.Cont_de_stoc and po.Loc_de_munca=p.Loc_de_munca and po.Comanda=p.Comanda
				and (@CtAdaos='' or po.cont_creditor not like RTrim(@CtAdaos)+'%') 
				and (@CtTVAnx='' or po.cont_creditor not like RTrim(@CtTVAnx)+'%')) ic 
	where p.subunitate = @Sub and p.tip in ('RM','RS') 
	group by p.Subunitate, p.tip, p.numar, p.data, p.cont_de_stoc, p.comanda, p.Loc_de_munca

--	scriu in #pozincon
	insert into #pozincon (TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma,Explicatii, Data_operarii, Ora_operarii)
	select 'DIFREC', p.Subunitate, p.tip, p.numar, p.data, '', 0, 0, p.utilizator, p.Loc_de_munca, p.comanda, p.jurnal
		,(case when p.valoare<0 then p.cont_de_stoc else @cContPlus end), (case when p.valoare<0 then @cContMinus else p.Cont_de_stoc end)
		,p.Valoare, 'CORECTIE', p.data_operarii, p.ora_operarii
	from #pozdocDifRec p 
	where abs(valoare) >= @nValMin

end try

begin catch
	declare @mesaj varchar(8000)
	set @mesaj =ERROR_MESSAGE()+' (inregDocReceptiiDiferente)'
	raiserror(@mesaj, 11, 1)
end catch

if object_id('tempdb..#pozdocDifRec') is not null drop table #pozdocDifRec
