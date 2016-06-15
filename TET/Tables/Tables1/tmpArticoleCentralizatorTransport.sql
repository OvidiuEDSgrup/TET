CREATE TABLE [dbo].[tmpArticoleCentralizatorTransport] (
    [idContract]          INT             NULL,
    [comanda]             VARCHAR (20)    NULL,
    [stare]               INT             NULL,
    [data]                DATETIME        NULL,
    [tert]                VARCHAR (20)    NULL,
    [idPozContract]       INT             NULL,
    [cod]                 VARCHAR (20)    NULL,
    [cantitate_comanda]   DECIMAL (15, 2) NULL,
    [cantitate_transport] DECIMAL (15, 2) NULL,
    [cantitate]           FLOAT (53)      NULL,
    [greutate]            FLOAT (53)      NULL,
    [gestiune]            VARCHAR (20)    NULL,
    [idlinie]             INT             IDENTITY (1, 1) NOT NULL,
    [ordine]              FLOAT (53)      NULL,
    [datacalcul]          DATETIME        NULL,
    [grupare]             VARCHAR (100)   NULL
);

