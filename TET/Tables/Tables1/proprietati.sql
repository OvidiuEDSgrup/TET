CREATE TABLE [dbo].[proprietati] (
    [Tip]             CHAR (20)  NOT NULL,
    [Cod]             CHAR (30)  NOT NULL,
    [Cod_proprietate] CHAR (20)  NOT NULL,
    [Valoare]         CHAR (200) NOT NULL,
    [Valoare_tupla]   CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[proprietati]([Tip] ASC, [Cod] ASC, [Cod_proprietate] ASC, [Valoare] ASC, [Valoare_tupla] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_si_cod]
    ON [dbo].[proprietati]([Tip] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_si_proprietate]
    ON [dbo].[proprietati]([Tip] ASC, [Cod_proprietate] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_si_tupla]
    ON [dbo].[proprietati]([Tip] ASC, [Cod] ASC, [Valoare_tupla] ASC);


GO
CREATE STATISTICS [_dta_stat_1620252877_2_3]
    ON [dbo].[proprietati]([Cod], [Cod_proprietate]);

