CREATE TABLE [dbo].[incon] (
    [Subunitate]     CHAR (9)     NOT NULL,
    [Tip_document]   CHAR (2)     NOT NULL,
    [Numar_document] VARCHAR (20) NULL,
    [Data]           DATETIME     NOT NULL,
    [Jurnal]         CHAR (3)     NOT NULL,
    [Numar_pozitie]  INT          NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[incon]([Subunitate] ASC, [Tip_document] ASC, [Numar_document] ASC, [Data] ASC, [Jurnal] ASC);

