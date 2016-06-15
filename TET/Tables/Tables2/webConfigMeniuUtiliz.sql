CREATE TABLE [dbo].[webConfigMeniuUtiliz] (
    [IdUtilizator] VARCHAR (10) NOT NULL,
    [IdMeniu]      INT          NOT NULL,
    [Drepturi]     VARCHAR (30) NOT NULL,
    [Meniu]        VARCHAR (20) NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [PrincwebConfigMeniuUtiliz]
    ON [dbo].[webConfigMeniuUtiliz]([IdUtilizator] ASC, [Meniu] ASC)
    ON [WEB];

