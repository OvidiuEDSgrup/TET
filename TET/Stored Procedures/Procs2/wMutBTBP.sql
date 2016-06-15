--***
create procedure  wMutBTBP  @NrCasa int, @Vanz char(10), @Data datetime, @NrBon int, @NrLin int, 
	@TipDoc char(2), @Incasare int, @Cant float, @CantCl8 float, @Corelatii int
as

if @Corelatii=0 and not (@TipDoc='AC' and @Incasare=0 and @CantCl8>=@Cant and @Cant>0)
begin
	insert bp
	(Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, 
		Cantitate, Cota_TVA, 
		Tva, Pret, 
		Total, Retur, 
		Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, 
		lm_real, Comanda_asis,[Contract], idAntetBon, idPozContract, detalii)
	select Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, 
		round(convert(decimal(15, 4), bt.Cantitate-(case when @CantCl8>0 then bt.Cantitate*@CantCl8/@Cant else 0 end)), 3) Cantitate, Cota_TVA Cota_TVA, 
		round(convert(decimal(15, 4), bt.TVA-(case when @CantCl8>0 then bt.TVA*@CantCl8/@Cant else 0 end)), 2) Tva, Pret, 
		round(convert(decimal(15, 4), bt.Total-(case when @CantCl8>0 then bt.Total*@CantCl8/@Cant else 0 end)), 2) Total, Retur, 
		Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, Loc_de_munca, Discount, 
		lm_real, Comanda_asis,[Contract], idAntetBon, idPozContract, detalii
	from bt where bt.casa_de_marcat=@NrCasa and bt.vinzator=@Vanz and bt.data=@Data and bt.numar_bon=@NrBon and bt.numar_linie=@NrLin
end
if @Corelatii=0 and @TipDoc='AC' and @Incasare=0 and @CantCl8>=0.001
begin
	insert bp
	(Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie, Data, Ora, Tip, Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, 
		Cantitate, Cota_TVA, Tva, Pret, Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, 
		Loc_de_munca, Discount, lm_real, Comanda_asis,[Contract], idAntetBon, idPozContract, detalii)
	select Casa_de_marcat, Factura_chitanta, Numar_bon, Numar_linie+500, Data, Ora, '20', Vinzator, Client, Cod_citit_de_la_tastatura, CodPLU, Cod_produs, Categorie, UM, 
		round(convert(decimal(15, 4), bt.Cantitate*@CantCl8/@Cant), 3) Cantitate, Cota_TVA, round(convert(decimal(15, 4), bt.TVA*@CantCl8/@Cant), 2) Tva, Pret, 
		round(convert(decimal(15, 4), bt.Total*@CantCl8/@Cant), 2) Total, Retur, Inregistrare_valida, Operat, Numar_document_incasare, Data_documentului, 
		Loc_de_munca, Discount, lm_real, Comanda_asis,[Contract], idAntetBon, idPozContract, detalii
	from bt where bt.casa_de_marcat=@NrCasa and bt.vinzator=@Vanz and bt.data=@Data and bt.numar_bon=@NrBon and bt.numar_linie=@NrLin
end

delete bt where bt.casa_de_marcat=@NrCasa and bt.vinzator=@Vanz and bt.data=@Data and bt.numar_bon=@NrBon and bt.numar_linie=@NrLin
