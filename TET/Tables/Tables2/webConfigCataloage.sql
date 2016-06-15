CREATE TABLE [dbo].[webConfigCataloage] (
    [tipMacheta]        VARCHAR (2)   NULL,
    [descriere]         VARCHAR (30)  NULL,
    [proceduraDate]     VARCHAR (60)  NULL,
    [proceduraAdaugare] VARCHAR (60)  NULL,
    [proceduraStergere] VARCHAR (60)  NULL,
    [textAdaugare]      VARCHAR (200) NULL,
    [textModificare]    VARCHAR (200) NULL
) ON [WEB];


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[webConfigCataloage]([tipMacheta] ASC)
    ON [WEB];

