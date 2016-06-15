CREATE TABLE [dbo].[valinfopers] (
    [Cod_inf]         CHAR (20) NOT NULL,
    [Valoare]         CHAR (80) NOT NULL,
    [Descriere]       CHAR (80) NOT NULL,
    [Val_inf_parinte] CHAR (80) NOT NULL,
    [Data]            DATETIME  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[valinfopers]([Cod_inf] ASC, [Valoare] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_si_informatie]
    ON [dbo].[valinfopers]([Cod_inf] ASC);

