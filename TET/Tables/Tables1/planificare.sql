CREATE TABLE [dbo].[planificare] (
    [id]        INT          IDENTITY (1, 1) NOT NULL,
    [idOp]      INT          NULL,
    [comanda]   VARCHAR (20) NULL,
    [resursa]   VARCHAR (20) NULL,
    [dataStart] DATETIME     NULL,
    [dataStop]  DATETIME     NULL,
    [oraStart]  VARCHAR (4)  NULL,
    [oraStop]   VARCHAR (4)  NULL,
    [cantitate] FLOAT (53)   NULL,
    [ore]       FLOAT (53)   NULL,
    [stare]     VARCHAR (2)  NULL,
    [detalii]   XML          NULL,
    [idAntet]   INT          NULL,
    CONSTRAINT [PK_planificare] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 20)
);


GO
CREATE NONCLUSTERED INDEX [princ]
    ON [dbo].[planificare]([idOp] ASC, [resursa] ASC) WITH (FILLFACTOR = 20);


GO
CREATE NONCLUSTERED INDEX [princdta]
    ON [dbo].[planificare]([idOp] ASC, [comanda] ASC, [resursa] ASC, [dataStart] ASC, [dataStop] ASC) WITH (FILLFACTOR = 20);

