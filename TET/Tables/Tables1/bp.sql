CREATE TABLE [dbo].[bp] (
    [Casa_de_marcat]            SMALLINT     NOT NULL,
    [Factura_chitanta]          INT          NULL,
    [Numar_bon]                 INT          NOT NULL,
    [Numar_linie]               SMALLINT     NOT NULL,
    [Data]                      DATETIME     NOT NULL,
    [Ora]                       CHAR (6)     NOT NULL,
    [Tip]                       CHAR (2)     NOT NULL,
    [Vinzator]                  CHAR (10)    NOT NULL,
    [Client]                    CHAR (13)    NOT NULL,
    [Cod_citit_de_la_tastatura] CHAR (20)    NOT NULL,
    [CodPLU]                    CHAR (20)    NOT NULL,
    [Cod_produs]                CHAR (20)    NOT NULL,
    [Categorie]                 SMALLINT     NOT NULL,
    [UM]                        SMALLINT     NOT NULL,
    [Cantitate]                 FLOAT (53)   NOT NULL,
    [Cota_TVA]                  REAL         NOT NULL,
    [Tva]                       FLOAT (53)   NOT NULL,
    [Pret]                      FLOAT (53)   NOT NULL,
    [Total]                     FLOAT (53)   NOT NULL,
    [Retur]                     BIT          NOT NULL,
    [Inregistrare_valida]       BIT          NOT NULL,
    [Operat]                    BIT          NOT NULL,
    [Numar_document_incasare]   CHAR (20)    NOT NULL,
    [Data_documentului]         DATETIME     NOT NULL,
    [Loc_de_munca]              CHAR (9)     NOT NULL,
    [Discount]                  FLOAT (53)   NOT NULL,
    [IdAntetBon]                INT          NULL,
    [IdPozitie]                 INT          IDENTITY (1, 1) NOT NULL,
    [lm_real]                   VARCHAR (9)  NULL,
    [Comanda_asis]              VARCHAR (20) NULL,
    [Contract]                  VARCHAR (20) NULL,
    [Gestiune]                  AS           (rtrim([loc_de_munca])),
    [idPozContract]             INT          NULL,
    [detalii]                   XML          NULL,
    CONSTRAINT [FK_Bp_antetBonturi] FOREIGN KEY ([IdAntetBon]) REFERENCES [dbo].[antetBonuri] ([IdAntetBon])
);


GO
CREATE UNIQUE CLUSTERED INDEX [Numar_bon_Tip]
    ON [dbo].[bp]([Data] ASC, [Casa_de_marcat] ASC, [Vinzator] ASC, [Numar_bon] ASC, [Numar_linie] ASC);


GO
CREATE NONCLUSTERED INDEX [casa_de_marcat]
    ON [dbo].[bp]([Tip] ASC, [Data] ASC, [Casa_de_marcat] ASC, [Numar_bon] ASC, [Cantitate] ASC, [Cota_TVA] ASC, [Tva] ASC, [Pret] ASC, [Total] ASC, [Discount] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PentruFacturare]
    ON [dbo].[bp]([Casa_de_marcat] ASC, [Data] ASC, [Numar_bon] ASC)
    INCLUDE([Tip], [Cantitate], [Cota_TVA], [Tva], [Pret], [Total], [Discount]);


GO
CREATE NONCLUSTERED INDEX [IX_antetBon]
    ON [dbo].[bp]([IdAntetBon] ASC)
    INCLUDE([Tip], [Cod_produs], [Cantitate], [Tva], [Pret], [Total], [Discount], [Cota_TVA]);


GO

CREATE trigger [dbo].yso_bpsterg on [dbo].bp for update, delete NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into yso_syssbp
select host_id() [Host_id],host_name () [Host_name], @Aplicatia Aplicatia, getdate() Data_stergerii, @Utilizator Stergator  
, Casa_de_marcat,	Factura_chitanta,	Numar_bon,	Numar_linie,	Data,	Ora,	Tip,	Vinzator,	Client
,	Cod_citit_de_la_tastatura,	CodPLU,	Cod_produs,	Categorie,	UM,	Cantitate,	Cota_TVA,	Tva,	Pret,	Total,	Retur
,	Inregistrare_valida,	Operat,	Numar_document_incasare,	Data_documentului,	Loc_de_munca,	Discount,	IdAntetBon
,	IdPozitie,	lm_real,	Comanda_asis,	Contract
,	Gestiune
--into yso_syssbp
from deleted 

--declare @log xml=(
--	SELECT 
--		  r.session_id, 
--		  r.blocking_session_id, 
--		  s.program_name, 
--		  s.host_name, 
--		  t.objectid, 
--		  o.name,
--		  t.text

--	FROM
--		  sys.dm_exec_requests r
--		  INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
--		  CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
--		  left join sys.objects o on o.object_id=t.objectid

--	WHERE
--		  s.is_user_process = 1
--	for xml raw
--      )
--      return

