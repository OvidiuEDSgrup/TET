CREATE TABLE [dbo].[impozit] (
    [Tip_impozit]  CHAR (1)   NOT NULL,
    [Numar_curent] SMALLINT   NOT NULL,
    [Limita]       FLOAT (53) NOT NULL,
    [Suma_fixa]    FLOAT (53) NOT NULL,
    [Procent]      REAL       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Tip_Numar]
    ON [dbo].[impozit]([Tip_impozit] ASC, [Numar_curent] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_Limita]
    ON [dbo].[impozit]([Tip_impozit] ASC, [Limita] ASC);

