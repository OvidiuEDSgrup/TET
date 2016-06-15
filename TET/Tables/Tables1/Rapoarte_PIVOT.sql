CREATE TABLE [dbo].[Rapoarte_PIVOT] (
    [Aplicatie]              CHAR (10)  NOT NULL,
    [Utilizator]             CHAR (10)  NOT NULL,
    [Nume_raport]            CHAR (50)  NOT NULL,
    [Nume_procedura_stocata] CHAR (100) NOT NULL,
    [Text_select]            TEXT       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Princ]
    ON [dbo].[Rapoarte_PIVOT]([Nume_raport] ASC);

