CREATE TABLE [dbo].[compcategorii] (
    [Cod_Categ] CHAR (20)      NOT NULL,
    [Cod_Ind]   CHAR (20)      NOT NULL,
    [Rand]      DECIMAL (5, 2) NOT NULL,
    [Parinte]   CHAR (20)      NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[compcategorii]([Cod_Categ] ASC, [Rand] ASC);

