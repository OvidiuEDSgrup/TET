CREATE TABLE [dbo].[Anexebug] (
    [Capitol_subcapitol] CHAR (13)  NOT NULL,
    [Subcapitol]         CHAR (13)  NOT NULL,
    [Titlu]              CHAR (13)  NOT NULL,
    [Articol]            CHAR (13)  NOT NULL,
    [Aliniat]            CHAR (13)  NOT NULL,
    [Plati]              FLOAT (53) NOT NULL,
    [Cheltuieli]         FLOAT (53) NOT NULL,
    [Venituri]           FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Ind]
    ON [dbo].[Anexebug]([Capitol_subcapitol] ASC, [Subcapitol] ASC, [Titlu] ASC, [Articol] ASC, [Aliniat] ASC);

