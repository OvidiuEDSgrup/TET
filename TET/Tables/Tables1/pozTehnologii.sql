CREATE TABLE [dbo].[pozTehnologii] (
    [id]          INT          IDENTITY (1, 1) NOT NULL,
    [tip]         VARCHAR (1)  NOT NULL,
    [cod]         VARCHAR (20) NOT NULL,
    [cantitate]   FLOAT (53)   NULL,
    [pret]        FLOAT (53)   NULL,
    [resursa]     VARCHAR (20) NULL,
    [idp]         INT          NULL,
    [detalii]     XML          NULL,
    [cantitate_i] FLOAT (53)   NULL,
    [ordine_o]    FLOAT (53)   NULL,
    [parinteTop]  INT          NULL,
    CONSTRAINT [PK_pozTehnologii] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 20)
);


GO
CREATE NONCLUSTERED INDEX [parinti]
    ON [dbo].[pozTehnologii]([tip] ASC, [idp] ASC) WITH (FILLFACTOR = 20);


GO
CREATE NONCLUSTERED INDEX [princ]
    ON [dbo].[pozTehnologii]([tip] ASC, [cod] ASC) WITH (FILLFACTOR = 20);


GO
CREATE NONCLUSTERED INDEX [princ_cu_id]
    ON [dbo].[pozTehnologii]([id] ASC, [tip] ASC, [cod] ASC, [idp] ASC) WITH (FILLFACTOR = 20);


GO
CREATE NONCLUSTERED INDEX [pTop]
    ON [dbo].[pozTehnologii]([parinteTop] ASC) WITH (FILLFACTOR = 20);

