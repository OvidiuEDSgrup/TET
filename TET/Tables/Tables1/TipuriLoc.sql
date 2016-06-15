CREATE TABLE [dbo].[TipuriLoc] (
    [cod_tip]      CHAR (8)  NOT NULL,
    [denumire_tip] CHAR (30) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [cod_tip]
    ON [dbo].[TipuriLoc]([cod_tip] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [denumire]
    ON [dbo].[TipuriLoc]([denumire_tip] ASC);

