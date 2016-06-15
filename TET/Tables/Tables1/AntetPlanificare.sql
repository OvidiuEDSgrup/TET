CREATE TABLE [dbo].[AntetPlanificare] (
    [idAntet]       INT          IDENTITY (1, 1) NOT NULL,
    [numar]         VARCHAR (20) NULL,
    [data]          DATETIME     NULL,
    [idResursa]     INT          NULL,
    [dataora_start] DATETIME     NULL,
    [dataora_stop]  DATETIME     NULL,
    [detalii]       XML          NULL,
    PRIMARY KEY CLUSTERED ([idAntet] ASC)
);

