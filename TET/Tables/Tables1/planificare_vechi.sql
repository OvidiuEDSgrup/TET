CREATE TABLE [dbo].[planificare_vechi] (
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
    [detalii]   XML          NULL
);

