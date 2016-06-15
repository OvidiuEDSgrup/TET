CREATE TABLE [dbo].[antform] (
    [Numar_formular]    CHAR (9)    NOT NULL,
    [Denumire_formular] CHAR (50)   NOT NULL,
    [Linii_in_pozitii]  SMALLINT    NOT NULL,
    [Linii_pe_pagina]   SMALLINT    NOT NULL,
    [CLFrom]            CHAR (1000) NOT NULL,
    [CLWhere]           CHAR (1000) NOT NULL,
    [CLOrder]           CHAR (1000) NOT NULL,
    [Tip_formular]      CHAR (1)    NOT NULL,
    [eXML]              BIT         NOT NULL,
    [Transformare]      CHAR (200)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Antet_formular_principal]
    ON [dbo].[antform]([Numar_formular] ASC);


GO
CREATE NONCLUSTERED INDEX [Pentru_tip]
    ON [dbo].[antform]([Tip_formular] ASC);

