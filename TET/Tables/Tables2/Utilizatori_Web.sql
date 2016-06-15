CREATE TABLE [dbo].[Utilizatori_Web] (
    [Utilizator]    CHAR (20)  NOT NULL,
    [parola]        CHAR (20)  NOT NULL,
    [Grupa]         CHAR (13)  NOT NULL,
    [email]         CHAR (50)  NOT NULL,
    [tert]          CHAR (13)  NOT NULL,
    [identificator] CHAR (5)   NOT NULL,
    [Marca]         CHAR (6)   NOT NULL,
    [Nume_persoana] CHAR (50)  NOT NULL,
    [Nume_firma]    CHAR (30)  NOT NULL,
    [functia]       CHAR (30)  NOT NULL,
    [CUI]           CHAR (20)  NOT NULL,
    [Adresa]        CHAR (60)  NOT NULL,
    [Oras]          CHAR (35)  NOT NULL,
    [Cod_postal]    CHAR (30)  NOT NULL,
    [Judet]         CHAR (30)  NOT NULL,
    [Tara]          CHAR (35)  NOT NULL,
    [Telefon]       CHAR (20)  NOT NULL,
    [Telefon2]      CHAR (20)  NOT NULL,
    [Fax]           CHAR (20)  NOT NULL,
    [Observatii]    CHAR (50)  NOT NULL,
    [Informatii]    CHAR (100) NOT NULL,
    [CNP]           CHAR (13)  NOT NULL,
    [seria]         CHAR (2)   NOT NULL,
    [numar]         CHAR (6)   NOT NULL,
    [confirmat]     BIT        NOT NULL,
    [activat]       BIT        NOT NULL,
    [cod_activare]  CHAR (30)  NOT NULL,
    CONSTRAINT [dupa_utilizator] PRIMARY KEY NONCLUSTERED ([Utilizator] ASC)
);


GO
CREATE NONCLUSTERED INDEX [dupa_email]
    ON [dbo].[Utilizatori_Web]([email] ASC, [Utilizator] ASC, [Grupa] ASC);


GO
CREATE NONCLUSTERED INDEX [dupa_tert]
    ON [dbo].[Utilizatori_Web]([tert] ASC, [identificator] ASC);

