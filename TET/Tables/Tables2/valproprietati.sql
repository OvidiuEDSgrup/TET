CREATE TABLE [dbo].[valproprietati] (
    [Cod_proprietate]             CHAR (20)  NOT NULL,
    [Valoare]                     CHAR (200) NOT NULL,
    [Descriere]                   CHAR (80)  NOT NULL,
    [Valoare_proprietate_parinte] CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[valproprietati]([Cod_proprietate] ASC, [Valoare] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_si_proprietate]
    ON [dbo].[valproprietati]([Cod_proprietate] ASC);

