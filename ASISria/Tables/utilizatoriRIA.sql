CREATE TABLE [dbo].[utilizatoriRIA] (
    [BD]                VARCHAR (40) NOT NULL,
    [utilizator]        VARCHAR (40) NOT NULL,
    [parola]            VARCHAR (40) NULL,
    [utilizatorWindows] VARCHAR (40) NULL,
    [detalii]           XML          NULL,
    CONSTRAINT [PK_utilizatoriRIA] PRIMARY KEY CLUSTERED ([BD] ASC, [utilizator] ASC)
);

