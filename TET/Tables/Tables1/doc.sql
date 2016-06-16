CREATE TABLE [dbo].[doc] (
    [Subunitate]          VARCHAR (9)  NOT NULL,
    [Tip]                 VARCHAR (2)  NOT NULL,
    [Numar]               VARCHAR (8)  NOT NULL,
    [Cod_gestiune]        VARCHAR (9)  NOT NULL,
    [Data]                DATETIME     NOT NULL,
    [Cod_tert]            CHAR (13)    NOT NULL,
    [Factura]             CHAR (20)    NOT NULL,
    [Contractul]          CHAR (20)    NOT NULL,
    [Loc_munca]           CHAR (9)     NOT NULL,
    [Comanda]             CHAR (40)    NOT NULL,
    [Gestiune_primitoare] VARCHAR (20) NULL,
    [Valuta]              CHAR (3)     NOT NULL,
    [Curs]                FLOAT (53)   NOT NULL,
    [Valoare]             FLOAT (53)   NOT NULL,
    [Tva_11]              FLOAT (53)   NOT NULL,
    [Tva_22]              FLOAT (53)   NOT NULL,
    [Valoare_valuta]      FLOAT (53)   NOT NULL,
    [Cota_TVA]            REAL         NOT NULL,
    [Discount_p]          REAL         NOT NULL,
    [Discount_suma]       FLOAT (53)   NOT NULL,
    [Pro_forma]           BINARY (1)   NOT NULL,
    [Tip_miscare]         CHAR (1)     NOT NULL,
    [Numar_DVI]           CHAR (30)    NOT NULL,
    [Cont_factura]        VARCHAR (20) NULL,
    [Data_facturii]       DATETIME     NOT NULL,
    [Data_scadentei]      DATETIME     NOT NULL,
    [Jurnal]              VARCHAR (20) NULL,
    [Numar_pozitii]       INT          NOT NULL,
    [Stare]               SMALLINT     NOT NULL,
    [detalii]             XML          NULL,
    [idplaja]             INT          NULL,
    CONSTRAINT [FK__doc__idplaja__2B8789E9] FOREIGN KEY ([idplaja]) REFERENCES [dbo].[docfiscale] ([Id])
);




GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[doc]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [unic]
    ON [dbo].[doc]([Subunitate] ASC, [Tip] ASC, [Data] ASC, [Numar] ASC, [Jurnal] ASC);


GO
CREATE NONCLUSTERED INDEX [Facturare]
    ON [dbo].[doc]([Subunitate] ASC, [Cod_tert] ASC, [Factura] ASC, [Tip] ASC, [Pro_forma] ASC);


GO
CREATE NONCLUSTERED INDEX [Numar]
    ON [dbo].[doc]([Numar] ASC);


GO
CREATE NONCLUSTERED INDEX [Punct_livrare]
    ON [dbo].[doc]([Subunitate] ASC, [Cod_tert] ASC, [Gestiune_primitoare] ASC, [Tip] ASC, [Numar] ASC);


GO



GO



GO



GO



GO



GO



GO



GO
CREATE trigger [dbo].[yso_docsterg] on dbo.doc for update, delete NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into yso_syssd
select top 1 host_id() [Host_id],host_name () [Host_name], @Aplicatia Aplicatia, getdate() Data_stergerii, @Utilizator Stergator  
,Subunitate
,Tip
,Numar
,Cod_gestiune
,Data
,Cod_tert
,Factura
,Contractul
,Loc_munca
,Comanda
,Gestiune_primitoare
,Valuta
,Curs
,Valoare
,Tva_11
,Tva_22
,Valoare_valuta
,Cota_TVA
,Discount_p
,Discount_suma
,Pro_forma
,Tip_miscare
,Numar_DVI
,Cont_factura
,Data_facturii
,Data_scadentei
,Jurnal
,Numar_pozitii
,Stare
,detalii
from deleted d

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
