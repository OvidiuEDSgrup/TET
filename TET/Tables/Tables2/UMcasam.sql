CREATE TABLE [dbo].[UMcasam] (
    [Tip_casam]     CHAR (20) NOT NULL,
    [UM]            CHAR (3)  NOT NULL,
    [Identificator] CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [UM_casa_unic]
    ON [dbo].[UMcasam]([Tip_casam] ASC, [UM] ASC);

