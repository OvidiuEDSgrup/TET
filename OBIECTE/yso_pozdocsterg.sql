if not exists (select name from sysobjects where name='yso_sysspd_antet')
CREATE TABLE yso_sysspd_antet (
	Host_id char (10) NOT NULL, 
	Host_name char (30) NOT NULL, 
	Aplicatia char (30) NOT NULL, 
	Data_operatiei datetime NOT NULL,
	Operator char (10) NOT NULL
	,eveniment NVARCHAR(100)
	,parametri INT
	,comanda NVARCHAR(4000) 
)
GO
--***
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'yso_ins_pozdoc') AND type='TR')
DROP trigger yso_ins_pozdoc
GO
--***
CREATE trigger yso_ins_pozdoc on pozdoc for insert NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspd
select host_id(),host_name (), @Aplicatia, getdate(), @Utilizator, 
data_operarii, ora_operarii,
Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare,
Pret_cu_amanuntul, TVA_deductibil, Cota_TVA, Utilizator, Cod_intrare, Cont_de_stoc, Cont_corespondent, 
TVA_neexigibil,	Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, 
Comanda, Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama, 
Accize_cumparare, Accize_datorate, Contract, Jurnal
from inserted

GO
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'yso_ins_sysspd') AND type='TR')
DROP trigger yso_ins_sysspd
GO
--***
CREATE trigger yso_ins_sysspd on sysspd for insert NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)
	,@eveniment NVARCHAR(100), @parametri INT, @comanda NVARCHAR(4000)

DECLARE @tSQLLog TABLE 
	(eveniment NVARCHAR(100)
	,parametri INT
	,comanda NVARCHAR(4000)
	,moment DATETIME DEFAULT CURRENT_TIMESTAMP)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

INSERT INTO @tSQLLog (eveniment, parametri, comanda)
EXEC('DBCC INPUTBUFFER(@@SPID) WITH NO_INFOMSGS;'); --AS LOGIN = 'sa'; 
select top 1 @eveniment=eveniment, @parametri=parametri, @comanda=comanda from @tsqllog

insert into yso_sysspd_antet ([Host_id], [Host_name],	Aplicatia, Data_operatiei, Operator, eveniment, parametri, comanda)
select i.Host_id, i.Host_name, i.Aplicatia, i.Data_stergerii, i.Stergator, @eveniment, @parametri, @comanda
from inserted i
group by i.Host_id, i.Host_name, i.Aplicatia, i.Data_stergerii, i.Stergator



