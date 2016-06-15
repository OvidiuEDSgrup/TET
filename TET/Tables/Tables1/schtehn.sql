CREATE TABLE [dbo].[schtehn] (
    [Utilizator]      CHAR (10)  NOT NULL,
    [Cod_tehn]        CHAR (20)  NOT NULL,
    [Cant_in_parinte] FLOAT (53) NOT NULL,
    [Cant_in_produs]  FLOAT (53) NOT NULL,
    [Nivel]           FLOAT (53) NOT NULL,
    [Ordine]          FLOAT (53) NOT NULL,
    [Cod_parinte]     CHAR (20)  NOT NULL,
    [Nr_tehn]         FLOAT (53) NOT NULL,
    [Loc_munca]       CHAR (9)   NOT NULL,
    [Nr_fisa]         CHAR (8)   NOT NULL,
    [Alfa1]           CHAR (20)  NOT NULL,
    [Alfa2]           CHAR (20)  NOT NULL,
    [Val1]            FLOAT (53) NOT NULL,
    [Val2]            FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Ordine]
    ON [dbo].[schtehn]([Utilizator] ASC, [Ordine] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod]
    ON [dbo].[schtehn]([Cod_tehn] ASC, [Utilizator] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Nivel_si_ordine]
    ON [dbo].[schtehn]([Nivel] ASC, [Ordine] ASC, [Utilizator] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod_parinte]
    ON [dbo].[schtehn]([Cod_parinte] ASC, [Utilizator] ASC);

