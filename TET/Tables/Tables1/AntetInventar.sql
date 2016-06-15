CREATE TABLE [dbo].[AntetInventar] (
    [idInventar] INT          IDENTITY (1, 1) NOT NULL,
    [tip]        VARCHAR (2)  NULL,
    [gestiune]   VARCHAR (20) NULL,
    [data]       DATETIME     NULL,
    [grupa]      VARCHAR (20) NULL,
    [locatie]    VARCHAR (20) NULL,
    [stare]      INT          NULL,
    [detalii]    XML          NULL,
    PRIMARY KEY CLUSTERED ([idInventar] ASC),
    CONSTRAINT [UnicitateInventar_DataSiGestiune] UNIQUE NONCLUSTERED ([gestiune] ASC, [data] ASC)
);

