CREATE TABLE [dbo].[curscor] (
    [Data]               DATETIME   NOT NULL,
    [Marca]              CHAR (6)   NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Tip_corectie_venit] CHAR (2)   NOT NULL,
    [Suma_corectie]      FLOAT (53) NOT NULL,
    [Procent_corectie]   REAL       NOT NULL,
    [Expand_locm]        BIT        NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Marca]
    ON [dbo].[curscor]([Data] ASC, [Marca] ASC, [Loc_de_munca] ASC, [Tip_corectie_venit] ASC);

