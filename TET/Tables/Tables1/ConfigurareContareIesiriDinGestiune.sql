CREATE TABLE [dbo].[ConfigurareContareIesiriDinGestiune] (
    [cont_de_stoc]    VARCHAR (20) NULL,
    [cont_cheltuieli] VARCHAR (20) NULL,
    [cont_venituri]   VARCHAR (20) NULL,
    [analiticg]       INT          NULL,
    [analiticcs]      INT          NULL,
    [nrord]           INT          NULL,
    [Tip]             VARCHAR (2)  NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [idx_ConfigurareContare]
    ON [dbo].[ConfigurareContareIesiriDinGestiune]([cont_de_stoc] ASC, [nrord] ASC);

