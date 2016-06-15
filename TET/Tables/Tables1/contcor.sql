CREATE TABLE [dbo].[contcor] (
    [ContCG]       VARCHAR (20) NULL,
    [Cont_strain]  CHAR (20)    NOT NULL,
    [DenS]         CHAR (30)    NOT NULL,
    [Loc_de_munca] CHAR (9)     NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Contcor]
    ON [dbo].[contcor]([ContCG] ASC, [Loc_de_munca] ASC);


GO
CREATE NONCLUSTERED INDEX [Cont_strain]
    ON [dbo].[contcor]([Cont_strain] ASC);

