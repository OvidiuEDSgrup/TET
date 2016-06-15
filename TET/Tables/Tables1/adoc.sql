CREATE TABLE [dbo].[adoc] (
    [Subunitate]     CHAR (9)  NOT NULL,
    [Tip]            CHAR (2)  NOT NULL,
    [Numar_document] CHAR (8)  NOT NULL,
    [Data]           DATETIME  NOT NULL,
    [Tert]           CHAR (13) NOT NULL,
    [Numar_pozitii]  INT       NOT NULL,
    [Jurnal]         CHAR (3)  NOT NULL,
    [Stare]          SMALLINT  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Actualizare]
    ON [dbo].[adoc]([Subunitate] ASC, [Tip] ASC, [Numar_document] ASC, [Data] ASC);


GO
CREATE NONCLUSTERED INDEX [legpincon]
    ON [dbo].[adoc]([Subunitate] ASC, [Numar_document] ASC, [Data] ASC);


GO
CREATE NONCLUSTERED INDEX [Situatii]
    ON [dbo].[adoc]([Subunitate] ASC, [Data] ASC, [Tert] ASC);

