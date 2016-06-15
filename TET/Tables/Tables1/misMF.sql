CREATE TABLE [dbo].[misMF] (
    [Subunitate]              CHAR (9)     NOT NULL,
    [Data_lunii_de_miscare]   DATETIME     NOT NULL,
    [Numar_de_inventar]       CHAR (13)    NOT NULL,
    [Tip_miscare]             CHAR (3)     NOT NULL,
    [Numar_document]          CHAR (8)     NOT NULL,
    [Data_miscarii]           DATETIME     NOT NULL,
    [Tert]                    CHAR (13)    NOT NULL,
    [Factura]                 CHAR (20)    NOT NULL,
    [Pret]                    FLOAT (53)   NOT NULL,
    [TVA]                     FLOAT (53)   NOT NULL,
    [Cont_corespondent]       VARCHAR (20) NULL,
    [Loc_de_munca_primitor]   VARCHAR (20) NULL,
    [Gestiune_primitoare]     VARCHAR (20) NULL,
    [Diferenta_de_valoare]    FLOAT (53)   NOT NULL,
    [Data_sfarsit_conservare] DATETIME     NOT NULL,
    [Subunitate_primitoare]   CHAR (40)    NOT NULL,
    [Procent_inchiriere]      REAL         NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Actualizare]
    ON [dbo].[misMF]([Subunitate] ASC, [Data_lunii_de_miscare] ASC, [Tip_miscare] ASC, [Numar_de_inventar] ASC, [Numar_document] ASC);


GO
CREATE NONCLUSTERED INDEX [Pentru_calcul]
    ON [dbo].[misMF]([Subunitate] ASC, [Data_lunii_de_miscare] ASC, [Numar_de_inventar] ASC, [Tip_miscare] ASC);


GO
--***
create trigger misMFsterg on MisMF for update, delete /*with append*/ NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssmm
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator,
	Subunitate, Data_lunii_de_miscare, Numar_de_inventar, Tip_miscare, Numar_document, Data_miscarii, Tert, Factura,
	Pret, TVA, Cont_corespondent, Loc_de_munca_primitor, Gestiune_primitoare, Diferenta_de_valoare, 
	Data_sfarsit_conservare, Subunitate_primitoare, Procent_inchiriere
   from deleted
