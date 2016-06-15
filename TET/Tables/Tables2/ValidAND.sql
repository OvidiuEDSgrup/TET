CREATE TABLE [dbo].[ValidAND] (
    [tip]            CHAR (2)   NOT NULL,
    [numar_document] CHAR (8)   NOT NULL,
    [data]           DATETIME   NOT NULL,
    [cont_deb]       CHAR (13)  NOT NULL,
    [cont_cred]      CHAR (13)  NOT NULL,
    [suma_deb]       FLOAT (53) NOT NULL,
    [suma_cred]      FLOAT (53) NOT NULL,
    [valuta]         CHAR (3)   NOT NULL,
    [curs]           FLOAT (53) NOT NULL,
    [suma_valuta]    FLOAT (53) NOT NULL,
    [conversie]      FLOAT (53) NOT NULL,
    [echivalent_USD] FLOAT (53) NOT NULL,
    [explicatii]     CHAR (50)  NOT NULL,
    [numar_pozitie]  INT        NOT NULL,
    [valid]          INT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [principal]
    ON [dbo].[ValidAND]([tip] ASC, [numar_document] ASC, [data] ASC, [numar_pozitie] ASC);

