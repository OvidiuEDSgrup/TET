CREATE TABLE [dbo].[formular] (
    [formular]      CHAR (9)  NOT NULL,
    [Numar_pozitie] SMALLINT  NOT NULL,
    [tip]           SMALLINT  NOT NULL,
    [rand]          SMALLINT  NOT NULL,
    [pozitie]       SMALLINT  NOT NULL,
    [expresie]      TEXT      NOT NULL,
    [obiect]        CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [princ]
    ON [dbo].[formular]([formular] ASC, [rand] ASC, [pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Dupa_tip]
    ON [dbo].[formular]([formular] ASC, [tip] ASC, [rand] ASC, [pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [PentruXML]
    ON [dbo].[formular]([formular] ASC, [tip] ASC, [obiect] DESC);

