CREATE TABLE [dbo].[componente] (
    [Data]     DATETIME   NOT NULL,
    [Marca]    CHAR (6)   NOT NULL,
    [Cod_comp] CHAR (13)  NOT NULL,
    [Val_comp] CHAR (40)  NOT NULL,
    [Procent]  FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[componente]([Data] ASC, [Marca] ASC, [Cod_comp] ASC, [Val_comp] ASC);


GO
CREATE NONCLUSTERED INDEX [Valoare_proprietate]
    ON [dbo].[componente]([Data] ASC, [Val_comp] ASC);

