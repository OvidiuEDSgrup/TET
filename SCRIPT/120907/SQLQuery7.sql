INSERT INTO TET.dbo.pozdoc
(Subunitate,Tip,Numar,Cod,Data,Gestiune,Cantitate,Pret_valuta,Pret_de_stoc,Adaos,Pret_vanzare,Pret_cu_amanuntul,TVA_deductibil,Cota_TVA,Utilizator,Data_operarii,Ora_operarii,Cod_intrare,Cont_de_stoc,Cont_corespondent,TVA_neexigibil,Pret_amanunt_predator,Tip_miscare,Locatie,Data_expirarii,Numar_pozitie,Loc_de_munca,Comanda,Barcod,Cont_intermediar,Cont_venituri,Discount,Tert,Factura,Gestiune_primitoare,Numar_DVI,Stare,Grupa,Cont_factura,Valuta,Curs,Data_facturii,Data_scadentei,Procent_vama,Suprataxe_vama,Accize_cumparare,Accize_datorate,Contract,Jurnal,detalii)
     VALUES
           (<Subunitate, char(9),>
           ,<Tip, char(2),>
           ,<Numar, char(8),>
           ,<Cod, char(20),>
           ,<Data, datetime,>
           ,<Gestiune, char(9),>
           ,<Cantitate, float,>
           ,<Pret_valuta, float,>
           ,<Pret_de_stoc, float,>
           ,<Adaos, real,>
           ,<Pret_vanzare, float,>
           ,<Pret_cu_amanuntul, float,>
           ,<TVA_deductibil, float,>
           ,<Cota_TVA, real,>
           ,<Utilizator, char(10),>
           ,<Data_operarii, datetime,>
           ,<Ora_operarii, char(6),>
           ,<Cod_intrare, char(20),>
           ,<Cont_de_stoc, char(13),>
           ,<Cont_corespondent, char(13),>
           ,<TVA_neexigibil, real,>
           ,<Pret_amanunt_predator, float,>
           ,<Tip_miscare, char(1),>
           ,<Locatie, char(30),>
           ,<Data_expirarii, datetime,>
           ,<Numar_pozitie, int,>
           ,<Loc_de_munca, char(9),>
           ,<Comanda, char(40),>
           ,<Barcod, char(30),>
           ,<Cont_intermediar, char(13),>
           ,<Cont_venituri, char(13),>
           ,<Discount, real,>
           ,<Tert, char(13),>
           ,<Factura, char(20),>
           ,<Gestiune_primitoare, char(13),>
           ,<Numar_DVI, char(25),>
           ,<Stare, smallint,>
           ,<Grupa, char(13),>
           ,<Cont_factura, char(13),>
           ,<Valuta, char(3),>
           ,<Curs, float,>
           ,<Data_facturii, datetime,>
           ,<Data_scadentei, datetime,>
           ,<Procent_vama, real,>
           ,<Suprataxe_vama, float,>
           ,<Accize_cumparare, float,>
           ,<Accize_datorate, float,>
           ,<Contract, char(20),>
           ,<Jurnal, char(3),>
           ,<detalii, xml,>)
GO


