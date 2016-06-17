CREATE TABLE [dbo].[parametriRIA] (
    [cod]       VARCHAR (15)  NOT NULL,
    [descriere] VARCHAR (100) NULL,
    [valoare]   VARCHAR (200) NULL,
    CONSTRAINT [PK_parametriRIA] PRIMARY KEY CLUSTERED ([cod] ASC)
);

