CREATE TABLE [dbo].[TmpFiltruP] (
    [IDSesiune]     CHAR (20)  NOT NULL,
    [Cod]           CHAR (20)  NOT NULL,
    [Valoare_tupla] CHAR (200) NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Prin]
    ON [dbo].[TmpFiltruP]([IDSesiune] ASC, [Cod] ASC, [Valoare_tupla] ASC);

