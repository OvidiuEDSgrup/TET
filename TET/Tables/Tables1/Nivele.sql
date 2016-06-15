CREATE TABLE [dbo].[Nivele] (
    [Cifra] TINYINT      NOT NULL,
    [Nr]    TINYINT      NOT NULL,
    [Text]  VARCHAR (25) NULL,
    CONSTRAINT [cp_nivele] PRIMARY KEY CLUSTERED ([Cifra] ASC, [Nr] ASC)
);

