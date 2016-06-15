CREATE TABLE [dbo].[preldate] (
    [Aplicatie]        CHAR (2)    NOT NULL,
    [Cod]              CHAR (20)   NOT NULL,
    [Tip]              CHAR (1)    NOT NULL,
    [Descriere]        CHAR (50)   NOT NULL,
    [Stergere]         BIT         NOT NULL,
    [Formula_stergere] CHAR (2000) NOT NULL,
    [Generare]         BIT         NOT NULL,
    [Formula_generare] TEXT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[preldate]([Aplicatie] ASC, [Cod] ASC);

