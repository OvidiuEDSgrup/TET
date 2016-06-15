CREATE TABLE [dbo].[sysspd] (
    [Host_id]               CHAR (10)    NOT NULL,
    [Host_name]             CHAR (30)    NOT NULL,
    [Aplicatia]             CHAR (30)    NOT NULL,
    [Data_stergerii]        DATETIME     NOT NULL,
    [Stergator]             CHAR (10)    NOT NULL,
    [Data_operarii]         DATETIME     NOT NULL,
    [Ora_operarii]          CHAR (6)     NOT NULL,
    [Subunitate]            CHAR (9)     NOT NULL,
    [Tip]                   CHAR (2)     NOT NULL,
    [Numar]                 CHAR (8)     NOT NULL,
    [Cod]                   CHAR (20)    NOT NULL,
    [Data]                  DATETIME     NOT NULL,
    [Gestiune]              CHAR (9)     NOT NULL,
    [Cantitate]             FLOAT (53)   NOT NULL,
    [Pret_valuta]           FLOAT (53)   NOT NULL,
    [Pret_de_stoc]          FLOAT (53)   NOT NULL,
    [Adaos]                 REAL         NOT NULL,
    [Pret_vanzare]          FLOAT (53)   NOT NULL,
    [Pret_cu_amanuntul]     FLOAT (53)   NOT NULL,
    [TVA_deductibil]        FLOAT (53)   NOT NULL,
    [Cota_TVA]              SMALLINT     NOT NULL,
    [Utilizator]            CHAR (10)    NOT NULL,
    [Cod_intrare]           CHAR (13)    NOT NULL,
    [Cont_de_stoc]          VARCHAR (20) NULL,
    [Cont_corespondent]     VARCHAR (20) NULL,
    [TVA_neexigibil]        SMALLINT     NOT NULL,
    [Pret_amanunt_predator] FLOAT (53)   NOT NULL,
    [Tip_miscare]           CHAR (1)     NOT NULL,
    [Locatie]               CHAR (30)    NOT NULL,
    [Data_expirarii]        DATETIME     NOT NULL,
    [Numar_pozitie]         INT          NOT NULL,
    [Loc_de_munca]          CHAR (9)     NOT NULL,
    [Comanda]               CHAR (40)    NOT NULL,
    [Barcod]                CHAR (30)    NOT NULL,
    [Cont_intermediar]      VARCHAR (20) NULL,
    [Cont_venituri]         VARCHAR (20) NULL,
    [Discount]              REAL         NOT NULL,
    [Tert]                  CHAR (13)    NOT NULL,
    [Factura]               CHAR (20)    NOT NULL,
    [Gestiune_primitoare]   VARCHAR (20) NULL,
    [Numar_DVI]             CHAR (25)    NOT NULL,
    [Stare]                 SMALLINT     NOT NULL,
    [Grupa]                 CHAR (13)    NOT NULL,
    [Cont_factura]          VARCHAR (20) NULL,
    [Valuta]                CHAR (3)     NOT NULL,
    [Curs]                  FLOAT (53)   NOT NULL,
    [Data_facturii]         DATETIME     NOT NULL,
    [Data_scadentei]        DATETIME     NOT NULL,
    [Procent_vama]          REAL         NOT NULL,
    [Suprataxe_vama]        FLOAT (53)   NOT NULL,
    [Accize_cumparare]      FLOAT (53)   NOT NULL,
    [Accize_datorate]       FLOAT (53)   NOT NULL,
    [Contract]              CHAR (20)    NOT NULL,
    [Jurnal]                CHAR (3)     NOT NULL
) ON [SYSS];


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



