CREATE TABLE [dbo].[docsters] (
    [Subunitate]          CHAR (9)   NOT NULL,
    [Tip]                 CHAR (2)   NOT NULL,
    [Numar]               CHAR (8)   NOT NULL,
    [Data]                DATETIME   NOT NULL,
    [Tert]                CHAR (13)  NOT NULL,
    [Factura]             CHAR (20)  NOT NULL,
    [Gestiune]            CHAR (9)   NOT NULL,
    [Cod]                 CHAR (20)  NOT NULL,
    [Cod_intrare]         CHAR (13)  NOT NULL,
    [Gestiune_primitoare] CHAR (9)   NOT NULL,
    [Cont]                CHAR (13)  NOT NULL,
    [Cont_cor]            CHAR (13)  NOT NULL,
    [Cantitate]           FLOAT (53) NOT NULL,
    [Pret]                FLOAT (53) NOT NULL,
    [Pret_vanzare]        FLOAT (53) NOT NULL,
    [Jurnal]              CHAR (3)   NOT NULL,
    [Utilizator]          CHAR (10)  NOT NULL,
    [Data_operarii]       DATETIME   NOT NULL,
    [Ora_operarii]        CHAR (6)   NOT NULL,
    [Data_stergerii]      DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Sterse]
    ON [dbo].[docsters]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Data_stergerii] ASC, [Cod] ASC, [Cod_intrare] ASC);


GO
CREATE NONCLUSTERED INDEX [Data_stergerii]
    ON [dbo].[docsters]([Data_stergerii] ASC);

