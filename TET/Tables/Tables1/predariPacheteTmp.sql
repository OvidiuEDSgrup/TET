CREATE TABLE [dbo].[predariPacheteTmp] (
    [Terminal]          CHAR (10)   NULL,
    [Subunitate]        CHAR (9)    NULL,
    [Contract]          CHAR (20)   NULL,
    [Tert]              CHAR (13)   NULL,
    [TipAviz]           CHAR (2)    NULL,
    [NumarAviz]         CHAR (8)    NULL,
    [DataAviz]          DATETIME    NULL,
    [Numar_pozitieAviz] INT         NULL,
    [CodPachet]         CHAR (20)   NULL,
    [Cod_intrarePachet] CHAR (20)   NULL,
    [Tip]               CHAR (2)    NULL,
    [Numar]             CHAR (8)    NULL,
    [Data]              DATETIME    NULL,
    [Numar_pozitie]     INT         NULL,
    [Cod_intrare]       CHAR (20)   NULL,
    [Cantitate]         FLOAT (53)  NULL,
    [ordine]            VARCHAR (1) NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Unic]
    ON [dbo].[predariPacheteTmp]([Terminal] ASC, [Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Aviz]
    ON [dbo].[predariPacheteTmp]([Terminal] ASC, [Subunitate] ASC, [TipAviz] ASC, [NumarAviz] ASC, [DataAviz] ASC, [CodPachet] ASC, [Cod_intrarePachet] ASC);


GO
CREATE NONCLUSTERED INDEX [Contract]
    ON [dbo].[predariPacheteTmp]([Terminal] ASC, [Subunitate] ASC, [Contract] ASC, [Tert] ASC, [CodPachet] ASC);

