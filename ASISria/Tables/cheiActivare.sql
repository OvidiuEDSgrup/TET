CREATE TABLE [dbo].[cheiActivare] (
    [NumeServer]    VARCHAR (100)  NOT NULL,
    [BD]            VARCHAR (50)   NULL,
    [clientASW]     VARCHAR (40)   NOT NULL,
    [contractASW]   VARCHAR (40)   NOT NULL,
    [pozitieASW]    VARCHAR (40)   NOT NULL,
    [dataExp]       DATETIME       NULL,
    [nrUtilizatori] INT            NULL,
    [versiune]      VARCHAR (10)   NULL,
    [token]         VARCHAR (2000) NULL,
    CONSTRAINT [PK_cheiActivare] PRIMARY KEY CLUSTERED ([NumeServer] ASC)
);

