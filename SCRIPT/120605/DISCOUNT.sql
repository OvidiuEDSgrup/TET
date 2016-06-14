

Create trigger [dbo].[ModifContStoc] on [dbo].[pozdoc] instead of insert as

insert pozdoc
(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta,
Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil,
Cota_TVA, Utilizator, Data_operarii, Ora_operarii, Cod_intrare,
Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator,
Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda,
Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura,
Gestiune_primitoare, Numar_DVI, Stare, Grupa, Cont_factura, Valuta, Curs,
Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama,
Accize_cumparare, Accize_datorate, Contract, Jurnal)


select 
Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta,
Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, 
TVA_deductibil, Cota_TVA, Utilizator,
Data_operarii, Ora_operarii, Cod_intrare, 
Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator,
Tip_miscare, Locatie, Data_expirarii,
 Numar_pozitie, Loc_de_munca, Comanda, Barcod, Cont_intermediar,
(case when i.tip then '708' else Cont_venituri end),
 Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, Stare, Grupa,
Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama,
Suprataxe_vama, Accize_cumparare, Accize_datorate, Contract, Jurnal

from inserted i
go
