CREATE TABLE [dbo].[adocsters] (
    [Subunitate]      CHAR (9)   NOT NULL,
    [Numar_document]  CHAR (8)   NOT NULL,
    [Data]            DATETIME   NOT NULL,
    [Tert]            CHAR (13)  NOT NULL,
    [Tip]             CHAR (2)   NOT NULL,
    [Factura_stinga]  CHAR (20)  NOT NULL,
    [Factura_dreapta] CHAR (20)  NOT NULL,
    [Cont_deb]        CHAR (13)  NOT NULL,
    [Cont_cred]       CHAR (13)  NOT NULL,
    [Suma]            FLOAT (53) NOT NULL,
    [TVA11]           FLOAT (53) NOT NULL,
    [TVA22]           FLOAT (53) NOT NULL,
    [Utilizator]      CHAR (10)  NOT NULL,
    [Data_operarii]   DATETIME   NOT NULL,
    [Ora_operarii]    CHAR (6)   NOT NULL,
    [Numar_pozitie]   INT        NOT NULL,
    [Tert_beneficiar] CHAR (13)  NOT NULL,
    [Explicatii]      CHAR (50)  NOT NULL,
    [Loc_munca]       CHAR (9)   NOT NULL,
    [Comanda]         CHAR (20)  NOT NULL,
    [Data_fact]       DATETIME   NOT NULL,
    [Data_scad]       DATETIME   NOT NULL,
    [Stare]           SMALLINT   NOT NULL,
    [Data_stergerii]  DATETIME   NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [Data_stergerii]
    ON [dbo].[adocsters]([Data_stergerii] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Sterse]
    ON [dbo].[adocsters]([Subunitate] ASC, [Numar_document] ASC, [Data] ASC, [Tip] ASC, [Data_stergerii] ASC, [Numar_pozitie] ASC);

