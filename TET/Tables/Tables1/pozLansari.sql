CREATE TABLE [dbo].[pozLansari] (
    [id]          INT          IDENTITY (1, 1) NOT NULL,
    [tip]         VARCHAR (1)  NULL,
    [cod]         VARCHAR (20) NULL,
    [cantitate]   FLOAT (53)   NULL,
    [idp]         INT          NULL,
    [parinteTop]  INT          NULL,
    [detalii]     XML          NULL,
    [resursa]     VARCHAR (20) NULL,
    [ordine_o]    FLOAT (53)   NULL,
    [cantitate_i] FLOAT (53)   NULL,
    CONSTRAINT [PK_pozLansari] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [parinti]
    ON [dbo].[pozLansari]([tip] ASC, [idp] ASC);


GO
CREATE NONCLUSTERED INDEX [princ]
    ON [dbo].[pozLansari]([tip] ASC, [cod] ASC);


GO
CREATE NONCLUSTERED INDEX [pTop]
    ON [dbo].[pozLansari]([parinteTop] ASC);

