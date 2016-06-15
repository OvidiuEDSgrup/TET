CREATE TABLE [dbo].[GpsTracking] (
    [id]         INT            IDENTITY (1, 1) NOT NULL,
    [Tip]        VARCHAR (10)   NOT NULL,
    [Cod]        VARCHAR (20)   NOT NULL,
    [Data]       DATETIME       NULL,
    [x]          FLOAT (53)     NULL,
    [y]          FLOAT (53)     NULL,
    [kmph]       DECIMAL (4, 2) NULL,
    [detaliiXML] XML            NULL,
    CONSTRAINT [PK_GpsTracking] PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [TipCodData]
    ON [dbo].[GpsTracking]([Tip] ASC, [Cod] ASC, [Data] ASC);

