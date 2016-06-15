CREATE TABLE [dbo].[lansmats] (
    [Subunitate]    CHAR (9)   NOT NULL,
    [Comanda]       CHAR (20)  NOT NULL,
    [Cod_tata]      CHAR (20)  NOT NULL,
    [Material]      CHAR (20)  NOT NULL,
    [Nr_fisa]       CHAR (8)   NOT NULL,
    [Serie]         CHAR (20)  NOT NULL,
    [Cant_nec]      FLOAT (53) NOT NULL,
    [Cant_efectiva] FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Lansms1]
    ON [dbo].[lansmats]([Subunitate] ASC, [Comanda] ASC, [Cod_tata] ASC, [Material] ASC, [Nr_fisa] ASC, [Serie] ASC);


GO
CREATE NONCLUSTERED INDEX [Lansms2]
    ON [dbo].[lansmats]([Subunitate] ASC, [Comanda] ASC, [Material] ASC, [Serie] ASC);

