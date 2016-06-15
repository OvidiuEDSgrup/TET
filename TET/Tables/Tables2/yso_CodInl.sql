CREATE TABLE [dbo].[yso_CodInl] (
    [NrInl]     INT           IDENTITY (1, 1) NOT NULL,
    [Tip]       SMALLINT      NOT NULL,
    [Cod_vechi] NVARCHAR (50) NOT NULL,
    [Cod_nou]   NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_yso_CodInl] PRIMARY KEY CLUSTERED ([NrInl] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Unic_yso_CodInl]
    ON [dbo].[yso_CodInl]([Tip] ASC, [Cod_vechi] ASC, [Cod_nou] ASC);

