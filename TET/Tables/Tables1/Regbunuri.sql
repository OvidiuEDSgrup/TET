CREATE TABLE [dbo].[Regbunuri] (
    [Data_primirii] DATETIME   NOT NULL,
    [Denumire_tert] CHAR (30)  NOT NULL,
    [Adresa]        CHAR (60)  NOT NULL,
    [Tert]          CHAR (13)  NOT NULL,
    [Cod_fiscal]    CHAR (20)  NOT NULL,
    [Denumire_bun]  CHAR (80)  NOT NULL,
    [Cod_bun]       CHAR (20)  NOT NULL,
    [Cantitate_bun] FLOAT (53) NOT NULL,
    [Valoare_bun]   FLOAT (53) NOT NULL,
    [Denumire_ret]  CHAR (80)  NOT NULL,
    [Cod_bun_ret]   CHAR (20)  NOT NULL,
    [Cantitate_ret] FLOAT (53) NOT NULL,
    [Valoare_ret]   FLOAT (53) NOT NULL,
    [Data_tr]       DATETIME   NOT NULL,
    [Denumire_serv] CHAR (30)  NOT NULL,
    [Nr_ordine]     FLOAT (53) NOT NULL,
    [Data_serviciu] DATETIME   NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[Regbunuri]([Data_primirii] ASC, [Tert] ASC, [Cod_bun] ASC, [Cod_bun_ret] ASC, [Nr_ordine] ASC);

