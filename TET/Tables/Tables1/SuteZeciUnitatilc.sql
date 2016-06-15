CREATE TABLE [dbo].[SuteZeciUnitatilc] (
    [BitiSute]      SMALLINT     NOT NULL,
    [BitiZeci]      SMALLINT     NOT NULL,
    [BitiUnitatilc] SMALLINT     NOT NULL,
    [Text]          VARCHAR (25) NULL,
    [TextX]         VARCHAR (25) NULL,
    CONSTRAINT [cp_sutezeciUnitatilc] PRIMARY KEY CLUSTERED ([BitiSute] ASC, [BitiZeci] ASC, [BitiUnitatilc] ASC)
);

