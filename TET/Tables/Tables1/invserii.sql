CREATE TABLE [dbo].[invserii] (
    [Subunitate]        CHAR (9)     NOT NULL,
    [Data_inventarului] DATETIME     NOT NULL,
    [Gestiunea]         CHAR (9)     NOT NULL,
    [Cod_de_bara]       VARCHAR (30) NULL,
    [Cod_produs]        CHAR (20)    NOT NULL,
    [Serie]             CHAR (20)    NOT NULL,
    [Stoc_faptic]       FLOAT (53)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[invserii]([Subunitate] ASC, [Data_inventarului] ASC, [Gestiunea] ASC, [Cod_produs] ASC, [Serie] ASC);


GO
CREATE NONCLUSTERED INDEX [Gasit_data]
    ON [dbo].[invserii]([Subunitate] ASC, [Gestiunea] ASC);

