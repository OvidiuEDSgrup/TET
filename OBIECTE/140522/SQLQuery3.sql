CREATE INDEX missing_index_2506 ON [TET].[dbo].[deconturi] ([Subunitate], [Tip], [Decont], [Marca])			
CREATE INDEX missing_index_2535 ON [TET].[dbo].[pozincon] ([Subunitate], [Cont_creditor], [Data]) INCLUDE ([Suma], [Loc_de_munca])			
CREATE INDEX missing_index_2537 ON [TET].[dbo].[pozincon] ([Subunitate], [Cont_debitor], [Data]) INCLUDE ([Suma], [Loc_de_munca])			
CREATE INDEX missing_index_2530 ON [TET].[dbo].[balanta] ([HostID]) INCLUDE ([Subunitate], [Cont], [Sold_inc_an_debit], [Sold_inc_an_credit], [Total_sume_prec_debit], [Total_sume_prec_credit])			
CREATE INDEX missing_index_2526 ON [TET].[dbo].[balanta] ([HostID]) INCLUDE ([Subunitate], [Cont], [Rul_curent_debit], [Rul_curent_credit], [Total_sume_debit], [Total_sume_credit])			
CREATE INDEX missing_index_2547 ON [TET].[dbo].[balanta] ([HostID]) INCLUDE ([Subunitate], [Cont], [Total_sume_prec_debit], [Total_sume_prec_credit], [Total_sume_debit], [Total_sume_credit])			
CREATE INDEX missing_index_2545 ON [TET].[dbo].[balanta] ([HostID]) INCLUDE ([Subunitate], [Cont], [Sold_inc_an_debit], [Sold_inc_an_credit], [Rul_prec_debit], [Rul_prec_credit], [Rul_curent_debit], [Rul_curent_credit])			
CREATE INDEX missing_index_2503 ON [TET].[dbo].[doc] ([Numar]) INCLUDE ([Subunitate], [Tip], [Cod_gestiune], [Data], [Cod_tert], [Factura], [Contractul], [Loc_munca], [Comanda], [Gestiune_primitoare], [Valuta], [Curs], [Valoare], [Tva_11], [Tva_22], [Valoare_valuta], [Cota_TVA], [Discount_p], [Discount_suma], [Pro_forma], [Tip_miscare], [Numar_DVI], [Cont_factura], [Data_facturii], [Data_scadentei], [Jurnal], [Numar_pozitii], [Stare])			
CREATE INDEX missing_index_2501 ON [TET].[dbo].[facturi] ([Subunitate], [Tip], [Tert])			
CREATE INDEX missing_index_2528 ON [TET].[dbo].[balanta] ([HostID]) INCLUDE ([Subunitate], [Cont], [Total_sume_prec_debit], [Total_sume_prec_credit])			
CREATE INDEX missing_index_2524 ON [TET].[dbo].[balanta] ([HostID]) INCLUDE ([Subunitate], [Cont], [Sold_inc_an_debit], [Sold_inc_an_credit], [Total_sume_debit], [Total_sume_credit])			
CREATE INDEX missing_index_2522 ON [TET].[dbo].[balanta] ([HostID]) INCLUDE ([Cont], [Denumire_cont], [Sold_inc_an_debit], [Sold_inc_an_credit], [Rul_prec_debit], [Rul_prec_credit], [Sold_prec_debit], [Sold_prec_credit], [Total_sume_prec_debit], [Total_sume_prec_credit], [Rul_curent_debit], [Rul_curent_credit], [Rul_cum_debit], [Rul_cum_credit], [Total_sume_debit], [Total_sume_credit], [Sold_cur_debit], [Sold_cur_credit])			
CREATE INDEX missing_index_2499 ON [TET].[dbo].[stocuri] ([Subunitate], [Cod], [Cod_gestiune])			
CREATE INDEX missing_index_2508 ON [TET].[dbo].[deconttva] ([Data], [Rand_decont]) INCLUDE ([Capitol])			
CREATE INDEX missing_index_2510 ON [TET].[dbo].[pozadoc] ([Subunitate], [Cont_deb], [Cont_cred]) INCLUDE ([Numar_document], [Data], [Tert], [Tip], [Factura_stinga], [Factura_dreapta], [Suma], [TVA11], [TVA22], [Numar_pozitie], [Tert_beneficiar], [Explicatii], [Valuta], [Loc_munca], [Data_fact], [Stare], [Jurnal])			
CREATE INDEX missing_index_2532 ON [TET].[dbo].[pozincon] ([Data], [Loc_de_munca]) INCLUDE ([Subunitate], [Tip_document], [Numar_document], [Cont_debitor], [Cont_creditor], [Suma], [Suma_valuta], [Explicatii], [Numar_pozitie], [Jurnal])			
CREATE INDEX missing_index_2513 ON [TET].[dbo].[infotert] ([Identificator]) INCLUDE ([Subunitate], [Tert], [Zile_inc])			
CREATE INDEX missing_index_2543 ON [TET].[dbo].[rulaje] ([Valuta], [Data]) INCLUDE ([Cont], [Rulaj_credit])			
CREATE INDEX missing_index_2541 ON [TET].[dbo].[rulaje] ([Valuta], [Data]) INCLUDE ([Cont], [Rulaj_debit])			
