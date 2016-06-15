CREATE TABLE [dbo].[tmpFiltru] (
    [Terminal]        INT       NOT NULL,
    [Cod_proprietate] CHAR (13) NOT NULL,
    [Valoare]         CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Princ]
    ON [dbo].[tmpFiltru]([Terminal] ASC, [Cod_proprietate] ASC, [Valoare] ASC);

